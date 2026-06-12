import csv
import io

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.core.database import get_db
from app.core.security import get_current_gym
from app.models import CheckIn, Gym, Payout
from app.schemas.checkin import GymCheckInOut
from app.schemas.gym import GymOwnerOut
from app.schemas.payout import GymDashboardOut, GymStudentRow, PayoutDetailOut, PayoutOut
from app.services import payout_service

# Importante: este router precisa ser registrado ANTES de /gyms/{gym_id}
# para que "/gyms/me" não seja interpretado como um id.
router = APIRouter(prefix="/gyms/me", tags=["Painel da Academia"])

MONTH_PATTERN = r"^\d{4}-\d{2}$"


@router.get("", response_model=GymOwnerOut)
def get_my_gym(gym: Gym = Depends(get_current_gym)):
    return gym


@router.get("/checkins", response_model=list[GymCheckInOut])
def get_my_checkins(
    limit: int = Query(default=50, le=500),
    gym: Gym = Depends(get_current_gym),
    db: Session = Depends(get_db),
):
    checkins = db.scalars(
        select(CheckIn)
        .options(joinedload(CheckIn.student))
        .where(CheckIn.gym_id == gym.id)
        .order_by(CheckIn.timestamp.desc())
        .limit(limit)
    ).all()
    return [
        GymCheckInOut(
            id=c.id,
            timestamp=c.timestamp,
            student_name=c.student.name,
            student_university=c.student.university,
            plan_tier_at_checkin=c.plan_tier_at_checkin,
            payout_amount_recorded=float(c.payout_amount_recorded),
        )
        for c in checkins
    ]


@router.get("/students", response_model=list[GymStudentRow])
def get_my_students(gym: Gym = Depends(get_current_gym), db: Session = Depends(get_db)):
    return payout_service.list_gym_students(db, gym.id)


@router.get("/dashboard", response_model=GymDashboardOut)
def get_my_dashboard(gym: Gym = Depends(get_current_gym), db: Session = Depends(get_db)):
    return payout_service.build_dashboard(db, gym)


@router.get("/payouts", response_model=list[PayoutOut])
def get_my_payouts(gym: Gym = Depends(get_current_gym), db: Session = Depends(get_db)):
    return payout_service.list_payouts(db, gym.id)


@router.get("/payouts/{reference_month}", response_model=PayoutDetailOut)
def get_my_payout_detail(
    reference_month: str = Path(pattern=MONTH_PATTERN, description="Mês no formato YYYY-MM"),
    gym: Gym = Depends(get_current_gym),
    db: Session = Depends(get_db),
):
    checkins = payout_service.month_checkins(db, gym.id, reference_month)
    if not checkins:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nenhum check-in neste mês.")

    total_checkins, total_amount = payout_service.compute_month_totals(db, gym.id, reference_month)
    payout = db.scalar(
        select(Payout).where(Payout.gym_id == gym.id, Payout.reference_month == reference_month)
    )
    return PayoutDetailOut(
        reference_month=reference_month,
        total_checkins=total_checkins,
        total_amount=float(total_amount),
        status=payout.status if payout else "pending",
        paid_at=payout.paid_at if payout else None,
        checkins=checkins,
    )


@router.get("/payouts/{reference_month}/export")
def export_my_payout_csv(
    reference_month: str = Path(pattern=MONTH_PATTERN),
    gym: Gym = Depends(get_current_gym),
    db: Session = Depends(get_db),
):
    """Extrato do mês em CSV (separador ';' e decimal com vírgula, padrão BR/Excel)."""
    checkins = payout_service.month_checkins(db, gym.id, reference_month)
    if not checkins:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nenhum check-in neste mês.")

    total_checkins, total_amount = payout_service.compute_month_totals(db, gym.id, reference_month)

    buffer = io.StringIO()
    writer = csv.writer(buffer, delimiter=";", lineterminator="\n")
    writer.writerow(["Data/Hora", "Aluno", "Universidade", "Tier do plano", "Valor do repasse (R$)"])
    for c in checkins:
        writer.writerow(
            [
                c["timestamp"].strftime("%d/%m/%Y %H:%M"),
                c["student_name"],
                c["student_university"],
                c["plan_tier_at_checkin"],
                f"{c['payout_amount_recorded']:.2f}".replace(".", ","),
            ]
        )
    writer.writerow([])
    writer.writerow(["Total de check-ins", total_checkins])
    writer.writerow(["Valor total a receber (R$)", f"{float(total_amount):.2f}".replace(".", ",")])

    # BOM para o Excel abrir com acentuação correta
    return Response(
        content="\ufeff" + buffer.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="extrato-unihub-{reference_month}.csv"'},
    )
