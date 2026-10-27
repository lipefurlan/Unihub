"""Desafios de engajamento: faculdades contra faculdades ou cursos de uma
faculdade entre si.

O ranking é calculado na hora a partir dos check-ins do período, então não
há placar para manter em sincronia. Quem disputa são os alunos com
assinatura ativa; a pontuação é relativa ao tamanho de cada grupo para um
curso ou faculdade pequenos poderem ganhar dos grandes.
"""

import math
import secrets
from collections import defaultdict
from datetime import date, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.models import Challenge, CheckIn, Student, Subscription, University

SCOPES = {"universities", "courses"}
METRICS = {
    "checkins_per_student": "Check-ins por aluno",
    "active_share": "% da turma treinando toda semana",
}
# Séries da evolução semanal: só os primeiros colocados, para o gráfico ler bem
EVOLUTION_TOP = 5


def challenge_status(challenge: Challenge, today: date | None = None) -> str:
    today = today or date.today()
    if today < challenge.start_date:
        return "upcoming"
    if today > challenge.end_date:
        return "ended"
    return "active"


def create_challenge(
    db: Session,
    *,
    title: str,
    description: str | None,
    scope: str,
    metric: str,
    start_date: date,
    end_date: date,
    university_id: int | None,
    created_by: str,
) -> Challenge:
    if scope not in SCOPES:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Tipo de desafio inválido.")
    if metric not in METRICS:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Regra de pontuação inválida.")
    if end_date < start_date:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="A data final precisa ser depois da inicial."
        )
    if scope == "courses" and university_id is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Desafio entre cursos precisa de uma faculdade.",
        )
    challenge = Challenge(
        title=title.strip(),
        description=(description or "").strip() or None,
        scope=scope,
        metric=metric,
        start_date=start_date,
        end_date=end_date,
        university_id=university_id if scope == "courses" else None,
        public_token=secrets.token_urlsafe(12),
        created_by=created_by,
    )
    db.add(challenge)
    db.commit()
    db.refresh(challenge)
    return challenge


def _participants(db: Session, challenge: Challenge) -> dict[str, list[Student]]:
    """Alunos com assinatura ativa, agrupados por faculdade ou por curso."""
    query = (
        select(Student)
        .join(Subscription, Subscription.student_id == Student.id)
        .options(joinedload(Student.university_ref))
        .where(Subscription.status == "active")
    )
    if challenge.scope == "courses":
        query = query.where(Student.university_id == challenge.university_id, Student.course.is_not(None))
    else:
        query = query.where(Student.university_id.is_not(None))

    groups: dict[str, list[Student]] = defaultdict(list)
    for student in db.scalars(query).unique().all():
        key = student.course if challenge.scope == "courses" else student.university_ref.name
        groups[key].append(student)
    return groups


def _score(metric: str, checkins: int, active: int, participants: int) -> float:
    if participants == 0:
        return 0.0
    if metric == "active_share":
        return round(100 * active / participants, 1)
    return round(checkins / participants, 1)


def _bounds(challenge: Challenge) -> tuple[datetime, datetime]:
    start = datetime.combine(challenge.start_date, datetime.min.time())
    end = datetime.combine(challenge.end_date + timedelta(days=1), datetime.min.time())
    return start, end


def ranking(db: Session, challenge: Challenge) -> dict:
    """Ranking atual e a evolução semana a semana dos primeiros colocados."""
    groups = _participants(db, challenge)
    student_group = {s.id: key for key, students in groups.items() for s in students}
    start, end = _bounds(challenge)
    checkins = (
        db.execute(
            select(CheckIn.student_id, CheckIn.timestamp).where(
                CheckIn.student_id.in_(list(student_group)),
                CheckIn.timestamp >= start,
                CheckIn.timestamp < end,
            )
        ).all()
        if student_group
        else []
    )

    def rows_until(limit: datetime) -> list[dict]:
        per_student: dict[int, int] = defaultdict(int)
        for student_id, ts in checkins:
            if ts < limit:
                per_student[student_id] += 1
        # "Treinando toda semana" = ao menos um check-in por semana já corrida
        weekly_target = max(1, math.ceil((limit - start).days / 7))
        rows = []
        for key, students in groups.items():
            count = sum(per_student[s.id] for s in students)
            regular = sum(1 for s in students if per_student[s.id] >= weekly_target)
            rows.append(
                {
                    "name": key,
                    "participants": len(students),
                    "checkins": count,
                    "active_students": regular,
                    "score": _score(challenge.metric, count, regular, len(students)),
                }
            )
        rows.sort(key=lambda r: (-r["score"], -r["checkins"], r["name"]))
        for position, row in enumerate(rows, start=1):
            row["position"] = position
        return rows

    # Desafio em andamento conta só as semanas já corridas
    horizon = min(end, datetime.combine(date.today() + timedelta(days=1), datetime.min.time()))
    current = rows_until(max(horizon, start + timedelta(days=1)))

    # Evolução: placar acumulado no fim de cada semana do desafio (até hoje)
    week_ends = []
    cursor = start + timedelta(days=7)
    while cursor < horizon:
        week_ends.append(cursor)
        cursor += timedelta(days=7)
    if horizon > start:  # desafio que ainda não começou não tem evolução
        week_ends.append(horizon)
    leaders = [r["name"] for r in current[:EVOLUTION_TOP]]
    snapshots = [{r["name"]: r["score"] for r in rows_until(limit)} for limit in week_ends]
    evolution = {
        "labels": [(limit - timedelta(days=1)).date().isoformat() for limit in week_ends],
        "series": [{"name": name, "points": [snap.get(name, 0.0) for snap in snapshots]} for name in leaders],
    }
    return {"ranking": current, "evolution": evolution}


def summary(db: Session, challenge: Challenge, with_ranking: bool = False) -> dict:
    data = ranking(db, challenge)
    state = challenge_status(challenge)
    leader = data["ranking"][0] if data["ranking"] and data["ranking"][0]["checkins"] > 0 else None
    out = {
        "id": challenge.id,
        "title": challenge.title,
        "description": challenge.description,
        "scope": challenge.scope,
        "metric": challenge.metric,
        "metric_label": METRICS[challenge.metric],
        "university_id": challenge.university_id,
        "university_name": challenge.university.name if challenge.university else None,
        "start_date": challenge.start_date,
        "end_date": challenge.end_date,
        "status": state,
        "public_token": challenge.public_token,
        "created_by": challenge.created_by,
        "groups": len(data["ranking"]),
        "participants": sum(r["participants"] for r in data["ranking"]),
        "total_checkins": sum(r["checkins"] for r in data["ranking"]),
        "leader": leader["name"] if leader else None,
        "champion": leader["name"] if leader and state == "ended" else None,
    }
    if with_ranking:
        out.update(data)
    return out


def list_challenges(db: Session, university: University | None = None) -> list[Challenge]:
    """Todos (operação) ou os que envolvem a faculdade: entre faculdades + os seus de cursos."""
    query = select(Challenge).options(joinedload(Challenge.university))
    if university is not None:
        query = query.where((Challenge.scope == "universities") | (Challenge.university_id == university.id))
    challenges = db.scalars(query).all()
    order = {"active": 0, "upcoming": 1, "ended": 2}
    return sorted(challenges, key=lambda c: (order[challenge_status(c)], -c.end_date.toordinal()))


def get_challenge(db: Session, challenge_id: int, university: University | None = None) -> Challenge:
    challenge = db.get(Challenge, challenge_id)
    visible = challenge is not None and (
        university is None or challenge.scope == "universities" or challenge.university_id == university.id
    )
    if not visible:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Desafio não encontrado.")
    return challenge


def student_challenges(db: Session, student: Student) -> list[dict]:
    """Desafios ativos de que o aluno participa, com o grupo dele e quanto já somou."""
    if student.university_id is None:
        return []
    out = []
    for challenge in list_challenges(db):
        if challenge_status(challenge) != "active":
            continue
        if challenge.scope == "courses" and (
            challenge.university_id != student.university_id or not student.course
        ):
            continue
        start, end = _bounds(challenge)
        my_count = db.scalar(
            select(func.count(CheckIn.id)).where(
                CheckIn.student_id == student.id, CheckIn.timestamp >= start, CheckIn.timestamp < end
            )
        )
        data = summary(db, challenge, with_ranking=True)
        data["my_group"] = student.course if challenge.scope == "courses" else student.university
        data["my_checkins"] = my_count
        out.append(data)
    return out


def delete_challenge(db: Session, challenge: Challenge) -> None:
    db.delete(challenge)
    db.commit()
