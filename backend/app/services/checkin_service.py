from datetime import datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import CheckIn, Gym, Student


def create_checkin(db: Session, student: Student, gym_id: int) -> CheckIn:
    """Registra um check-in aplicando as regras de negócio do UniHub.

    Regras:
    1. O estudante precisa de assinatura ativa.
    2. O tier do plano deve ser >= ao tier mínimo da academia.
    3. Anti-fraude: no máximo 1 check-in por aluno/academia dentro da janela
       configurada (default 3h).
    4. O valor de repasse da academia é congelado (snapshot) no check-in.
    """
    gym = db.get(Gym, gym_id)
    if gym is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")
    if not gym.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Esta academia não está mais ativa na plataforma.",
        )

    subscription = student.active_subscription
    if subscription is None or subscription.status != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Você não possui uma assinatura ativa. Assine um plano para fazer check-in.",
        )

    if subscription.plan.tier < gym.min_plan_tier:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                f"Seu plano não dá acesso a esta academia. "
                f"É necessário o Plano {gym.min_plan_tier} ou superior."
            ),
        )

    window_hours = settings.checkin_antifraud_window_hours
    window_start = datetime.now() - timedelta(hours=window_hours)
    recent = db.scalar(
        select(CheckIn)
        .where(
            CheckIn.student_id == student.id,
            CheckIn.gym_id == gym.id,
            CheckIn.timestamp >= window_start,
        )
        .limit(1)
    )
    if recent is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Você já fez check-in nesta academia nas últimas {window_hours} horas.",
        )

    checkin = CheckIn(
        student_id=student.id,
        gym_id=gym.id,
        timestamp=datetime.now(),
        plan_tier_at_checkin=subscription.plan.tier,
        payout_amount_recorded=gym.checkin_payout_amount,
    )
    db.add(checkin)
    db.commit()
    db.refresh(checkin)
    return checkin
