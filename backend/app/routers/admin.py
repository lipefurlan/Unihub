from datetime import date, datetime
from decimal import Decimal
from pathlib import Path as FilePath

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Request, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.core.database import get_db
from app.core.security import get_current_admin, hash_password
from app.models import Admin, CheckIn, Gym, Payout, Student, Subscription
from app.schemas.admin import (
    AdminGymCreate,
    AdminGymRow,
    AdminGymUpdate,
    AdminOut,
    AdminPayoutRow,
    AdminStudentRow,
    PlatformOverview,
    TopGym,
)
from app.services import payout_service

router = APIRouter(prefix="/admin", tags=["Operação UniHub"], dependencies=[Depends(get_current_admin)])

MONTH_PATTERN = r"^\d{4}-\d{2}$"

UPLOADS_DIR = FilePath(__file__).resolve().parents[2] / "uploads"
ALLOWED_PHOTO_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


@router.get("/me", response_model=AdminOut)
def get_me(admin: Admin = Depends(get_current_admin)):
    return admin


@router.get("/overview", response_model=PlatformOverview)
def get_overview(db: Session = Depends(get_db)):
    current_month = date.today().strftime("%Y-%m")
    start, end = payout_service.month_bounds(current_month)

    active_subs = db.scalars(
        select(Subscription).where(Subscription.status == "active")
    ).all()
    subscription_revenue = float(sum((s.amount for s in active_subs), Decimal("0")))

    month_checkins, month_payout_total = db.execute(
        select(func.count(CheckIn.id), func.coalesce(func.sum(CheckIn.payout_amount_recorded), 0))
        .where(CheckIn.timestamp >= start, CheckIn.timestamp < end)
    ).one()

    active_gyms = db.scalar(select(func.count(Gym.id)).where(Gym.is_active.is_(True)))

    top_rows = db.execute(
        select(Gym.name, func.count(CheckIn.id).label("c"))
        .join(CheckIn, CheckIn.gym_id == Gym.id)
        .where(CheckIn.timestamp >= start, CheckIn.timestamp < end)
        .group_by(Gym.id, Gym.name)
        .order_by(func.count(CheckIn.id).desc())
        .limit(5)
    ).all()

    payout_total = float(month_payout_total)
    return PlatformOverview(
        active_students=len(active_subs),
        subscription_revenue=subscription_revenue,
        month_checkins=month_checkins,
        month_payout_total=payout_total,
        estimated_margin=subscription_revenue - payout_total,
        active_gyms=active_gyms or 0,
        top_gyms=[TopGym(gym_name=name, checkins=c) for name, c in top_rows],
    )


def _gym_row(db: Session, gym: Gym, current_month: str) -> AdminGymRow:
    total_checkins, total_amount = payout_service.compute_month_totals(db, gym.id, current_month)
    return AdminGymRow(
        id=gym.id,
        name=gym.name,
        email=gym.email,
        address=gym.address,
        latitude=gym.latitude,
        longitude=gym.longitude,
        modalities=gym.modalities,
        min_plan_tier=gym.min_plan_tier,
        checkin_payout_amount=float(gym.checkin_payout_amount),
        capacity=gym.capacity,
        opening_hours=gym.opening_hours,
        photo_url=gym.photo_url,
        is_active=gym.is_active,
        month_checkins=total_checkins,
        month_amount=float(total_amount),
    )


@router.get("/gyms", response_model=list[AdminGymRow])
def list_gyms(db: Session = Depends(get_db)):
    current_month = date.today().strftime("%Y-%m")
    gyms = db.scalars(select(Gym).order_by(Gym.name)).all()
    return [_gym_row(db, g, current_month) for g in gyms]


@router.post("/gyms", response_model=AdminGymRow, status_code=status.HTTP_201_CREATED)
def create_gym(payload: AdminGymCreate, db: Session = Depends(get_db)):
    """Credencia uma nova academia e libera o acesso dela ao painel."""
    exists = db.scalar(select(Gym).where(Gym.email == payload.email))
    if exists is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Já existe uma academia com este e-mail.")

    gym = Gym(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
        address=payload.address,
        latitude=payload.latitude,
        longitude=payload.longitude,
        modalities=[m.strip().lower() for m in payload.modalities if m.strip()],
        min_plan_tier=payload.min_plan_tier,
        checkin_payout_amount=Decimal(str(payload.checkin_payout_amount)),
        capacity=payload.capacity,
        opening_hours=payload.opening_hours,
        is_active=True,
    )
    db.add(gym)
    db.commit()
    db.refresh(gym)
    return _gym_row(db, gym, date.today().strftime("%Y-%m"))


@router.put("/gyms/{gym_id}", response_model=AdminGymRow)
def update_gym(gym_id: int, payload: AdminGymUpdate, db: Session = Depends(get_db)):
    gym = db.get(Gym, gym_id)
    if gym is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")

    data = payload.model_dump(exclude_unset=True)
    if "checkin_payout_amount" in data:
        data["checkin_payout_amount"] = Decimal(str(data["checkin_payout_amount"]))
    if "modalities" in data and data["modalities"] is not None:
        data["modalities"] = [m.strip().lower() for m in data["modalities"] if m.strip()]
    for field, value in data.items():
        setattr(gym, field, value)

    db.commit()
    db.refresh(gym)
    return _gym_row(db, gym, date.today().strftime("%Y-%m"))


@router.post("/gyms/{gym_id}/photo", response_model=AdminGymRow)
async def upload_gym_photo(
    gym_id: int,
    photo: UploadFile,
    request: Request,
    db: Session = Depends(get_db),
):
    """Recebe a foto da academia e a serve em /uploads (estático)."""
    gym = db.get(Gym, gym_id)
    if gym is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")

    extension = ALLOWED_PHOTO_TYPES.get(photo.content_type or "")
    if extension is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Formato inválido. Envie JPG, PNG ou WebP.",
        )

    content = await photo.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="A foto deve ter no máximo 5 MB.")

    UPLOADS_DIR.mkdir(exist_ok=True)
    filename = f"gym-{gym.id}{extension}"
    (UPLOADS_DIR / filename).write_bytes(content)

    # URL absoluta para os clientes Flutter carregarem direto
    gym.photo_url = f"{str(request.base_url).rstrip('/')}/uploads/{filename}"
    db.commit()
    db.refresh(gym)
    return _gym_row(db, gym, date.today().strftime("%Y-%m"))


@router.get("/payouts", response_model=list[AdminPayoutRow])
def list_payouts(
    month: str | None = Query(default=None, pattern=MONTH_PATTERN, description="YYYY-MM (default: mês corrente)"),
    db: Session = Depends(get_db),
):
    """Visão consolidada do caixa: quanto a plataforma deve a cada academia no mês."""
    reference_month = month or date.today().strftime("%Y-%m")
    gyms = db.scalars(select(Gym).order_by(Gym.name)).all()
    persisted = {
        (p.gym_id, p.reference_month): p
        for p in db.scalars(select(Payout).where(Payout.reference_month == reference_month)).all()
    }

    rows = []
    for gym in gyms:
        total_checkins, total_amount = payout_service.compute_month_totals(db, gym.id, reference_month)
        if total_checkins == 0:
            continue
        payout = persisted.get((gym.id, reference_month))
        rows.append(
            AdminPayoutRow(
                gym_id=gym.id,
                gym_name=gym.name,
                reference_month=reference_month,
                total_checkins=total_checkins,
                total_amount=float(total_amount),
                status=payout.status if payout else "pending",
                paid_at=payout.paid_at if payout else None,
            )
        )
    return rows


@router.post("/payouts/{gym_id}/{reference_month}/mark-paid", response_model=AdminPayoutRow)
def mark_payout_paid(
    gym_id: int,
    reference_month: str = Path(pattern=MONTH_PATTERN),
    db: Session = Depends(get_db),
):
    """Registra o pagamento do repasse do mês para a academia (upsert do Payout)."""
    gym = db.get(Gym, gym_id)
    if gym is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")

    total_checkins, total_amount = payout_service.compute_month_totals(db, gym_id, reference_month)
    if total_checkins == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nenhum check-in neste mês.")

    payout = db.scalar(
        select(Payout).where(Payout.gym_id == gym_id, Payout.reference_month == reference_month)
    )
    if payout is None:
        payout = Payout(gym_id=gym_id, reference_month=reference_month)
        db.add(payout)

    payout.total_checkins = total_checkins
    payout.total_amount = total_amount
    payout.status = "paid"
    payout.paid_at = datetime.now()
    db.commit()

    return AdminPayoutRow(
        gym_id=gym_id,
        gym_name=gym.name,
        reference_month=reference_month,
        total_checkins=total_checkins,
        total_amount=float(total_amount),
        status="paid",
        paid_at=payout.paid_at,
    )


@router.get("/students", response_model=list[AdminStudentRow])
def list_students(db: Session = Depends(get_db)):
    students = db.scalars(
        select(Student).options(joinedload(Student.subscriptions)).order_by(Student.name)
    ).unique().all()

    checkin_counts = dict(
        db.execute(select(CheckIn.student_id, func.count(CheckIn.id)).group_by(CheckIn.student_id)).all()
    )

    rows = []
    for s in students:
        sub = s.active_subscription
        rows.append(
            AdminStudentRow(
                id=s.id,
                name=s.name,
                email=s.email,
                university=s.university,
                plan_name=sub.plan.name if sub else None,
                subscription_status=sub.status if sub else None,
                total_checkins=checkin_counts.get(s.id, 0),
            )
        )
    return rows
