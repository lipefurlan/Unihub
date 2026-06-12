from collections import Counter
from datetime import date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.models import CheckIn, Gym, Payout, Student, Subscription

# Faixas de horário usadas no gráfico de ocupação do painel
HOUR_RANGES = [(0, 6), (6, 9), (9, 12), (12, 15), (15, 18), (18, 21), (21, 24)]


def month_bounds(reference_month: str) -> tuple[datetime, datetime]:
    """Converte "YYYY-MM" no intervalo [primeiro dia, primeiro dia do mês seguinte)."""
    year, month = int(reference_month[:4]), int(reference_month[5:7])
    start = datetime(year, month, 1)
    end = datetime(year + 1, 1, 1) if month == 12 else datetime(year, month + 1, 1)
    return start, end


def compute_month_totals(db: Session, gym_id: int, reference_month: str) -> tuple[int, Decimal]:
    """Repasse do mês = soma dos snapshots de valor dos check-ins do mês."""
    start, end = month_bounds(reference_month)
    total_checkins, total_amount = db.execute(
        select(func.count(CheckIn.id), func.coalesce(func.sum(CheckIn.payout_amount_recorded), 0))
        .where(CheckIn.gym_id == gym_id, CheckIn.timestamp >= start, CheckIn.timestamp < end)
    ).one()
    return total_checkins, Decimal(str(total_amount))


def list_payouts(db: Session, gym_id: int) -> list[dict]:
    """Histórico de repasses: um item por mês com check-ins, do mais recente ao mais antigo.

    Meses passados usam o status persistido em Payout (pendente/pago);
    o mês corrente é sempre calculado ao vivo como pendente (em apuração).

    A agregação por mês é feita em Python (e não com funções de data do banco)
    para manter a query portável entre SQLite e PostgreSQL.
    """
    timestamps = db.scalars(select(CheckIn.timestamp).where(CheckIn.gym_id == gym_id)).all()
    months = sorted({ts.strftime("%Y-%m") for ts in timestamps}, reverse=True)

    persisted = {
        p.reference_month: p
        for p in db.scalars(select(Payout).where(Payout.gym_id == gym_id)).all()
    }

    result = []
    for month in months:
        total_checkins, total_amount = compute_month_totals(db, gym_id, month)
        payout = persisted.get(month)
        result.append(
            {
                "reference_month": month,
                "total_checkins": total_checkins,
                "total_amount": float(total_amount),
                "status": payout.status if payout else "pending",
                "paid_at": payout.paid_at if payout else None,
            }
        )
    return result


def month_checkins(db: Session, gym_id: int, reference_month: str) -> list[dict]:
    """Check-ins que compõem o repasse do mês, com dados do aluno."""
    start, end = month_bounds(reference_month)
    checkins = db.scalars(
        select(CheckIn)
        .options(joinedload(CheckIn.student))
        .where(CheckIn.gym_id == gym_id, CheckIn.timestamp >= start, CheckIn.timestamp < end)
        .order_by(CheckIn.timestamp.desc())
    ).all()
    return [
        {
            "id": c.id,
            "timestamp": c.timestamp,
            "student_name": c.student.name,
            "student_university": c.student.university,
            "plan_tier_at_checkin": c.plan_tier_at_checkin,
            "payout_amount_recorded": float(c.payout_amount_recorded),
        }
        for c in checkins
    ]


def build_dashboard(db: Session, gym: Gym) -> dict:
    """Métricas agregadas do painel da academia."""
    today = date.today()
    current_month = today.strftime("%Y-%m")
    prev_month = (today.replace(day=1) - timedelta(days=1)).strftime("%Y-%m")

    month_checkins_count, month_revenue = compute_month_totals(db, gym.id, current_month)
    prev_checkins_count, prev_revenue = compute_month_totals(db, gym.id, prev_month)

    month_start, month_end = month_bounds(current_month)
    unique_students = db.scalar(
        select(func.count(func.distinct(CheckIn.student_id))).where(
            CheckIn.gym_id == gym.id,
            CheckIn.timestamp >= month_start,
            CheckIn.timestamp < month_end,
        )
    )

    # Séries dos gráficos calculadas sobre os últimos 30 dias.
    # Agregação em Python para manter portabilidade SQLite/PostgreSQL.
    window_start = datetime.combine(today - timedelta(days=29), datetime.min.time())
    timestamps = db.scalars(
        select(CheckIn.timestamp).where(CheckIn.gym_id == gym.id, CheckIn.timestamp >= window_start)
    ).all()

    # Check-ins por dia (incluindo dias sem check-in, para o gráfico não "pular" datas)
    by_day = Counter(ts.strftime("%Y-%m-%d") for ts in timestamps)
    checkins_by_day = [
        {"date": day, "count": by_day.get(day, 0)}
        for day in ((today - timedelta(days=29 - i)).strftime("%Y-%m-%d") for i in range(30))
    ]

    # Check-ins por faixa de horário — mostra onde a capacidade ociosa
    # da academia está sendo preenchida
    by_hour = Counter(ts.hour for ts in timestamps)
    checkins_by_hour_range = [
        {
            "label": f"{start_h:02d}h–{end_h:02d}h",
            "count": sum(by_hour.get(h, 0) for h in range(start_h, end_h)),
        }
        for start_h, end_h in HOUR_RANGES
    ]

    return {
        "month_checkins": month_checkins_count,
        "unique_students": unique_students or 0,
        "estimated_revenue": float(month_revenue),
        "prev_month_checkins": prev_checkins_count,
        "prev_month_revenue": float(prev_revenue),
        "checkins_by_day": checkins_by_day,
        "checkins_by_hour_range": checkins_by_hour_range,
    }


def list_gym_students(db: Session, gym_id: int) -> list[dict]:
    """Tabela de gestão de alunos: agregados por aluno que frequentou a academia."""
    rows = db.execute(
        select(
            Student.id,
            Student.name,
            Student.university,
            func.count(CheckIn.id).label("total_checkins"),
            func.max(CheckIn.timestamp).label("last_checkin"),
        )
        .join(CheckIn, CheckIn.student_id == Student.id)
        .where(CheckIn.gym_id == gym_id)
        .group_by(Student.id, Student.name, Student.university)
        .order_by(func.max(CheckIn.timestamp).desc())
    ).all()

    # Nome do plano vigente de cada aluno (uma query, sem N+1)
    student_ids = [r.id for r in rows]
    plans_by_student: dict[int, str] = {}
    if student_ids:
        subs = db.scalars(
            select(Subscription)
            .options(joinedload(Subscription.plan))
            .where(Subscription.student_id.in_(student_ids), Subscription.status.in_(["active", "paused"]))
        ).all()
        plans_by_student = {s.student_id: s.plan.name for s in subs}

    return [
        {
            "student_id": r.id,
            "name": r.name,
            "university": r.university,
            "plan_name": plans_by_student.get(r.id),
            "total_checkins": r.total_checkins,
            "last_checkin": r.last_checkin,
        }
        for r in rows
    ]
