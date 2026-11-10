import secrets
from datetime import datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import CheckIn, Gym, Student

# Sem 0/O e 1/I/L para a recepção não confundir ao digitar
ENTRY_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
ENTRY_CODE_LENGTH = 6
# O código vale por algumas horas: o aluno mostra na chegada
ENTRY_CODE_VALID_HOURS = 3


def _new_entry_code() -> str:
    return "".join(secrets.choice(ENTRY_CODE_ALPHABET) for _ in range(ENTRY_CODE_LENGTH))


def create_checkin(db: Session, student: Student, gym_id: int) -> CheckIn:
    """Registra um check-in aplicando as regras de negócio do UniHub.

    Regras:
    1. O estudante precisa de assinatura ativa.
    2. O tier do plano deve ser >= ao tier mínimo da academia.
    3. Anti-fraude: no máximo 1 check-in por aluno/academia dentro da janela
       configurada (default 3h).
    4. O valor de repasse da academia é congelado (snapshot) no check-in.
    5. Teto de visitas pagas: só as primeiras N visitas do aluno no mês
       (somando todas as academias) geram repasse. Da N+1ª em diante o
       check-in é aceito, mas registrado como não remunerado.
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
    if subscription is not None and subscription.status == "paused":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seu plano está pausado. Retome o plano no perfil para fazer check-in.",
        )
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

    now = datetime.now()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    paid_this_month = db.scalar(
        select(func.count(CheckIn.id)).where(
            CheckIn.student_id == student.id,
            CheckIn.timestamp >= month_start,
            CheckIn.is_paid.is_(True),
        )
    )
    is_paid = paid_this_month < settings.max_paid_checkins_per_month

    checkin = CheckIn(
        student_id=student.id,
        gym_id=gym.id,
        timestamp=now,
        plan_tier_at_checkin=subscription.plan.tier,
        payout_amount_recorded=gym.checkin_payout_amount if is_paid else 0,
        is_paid=is_paid,
        entry_code=_new_entry_code(),
    )
    db.add(checkin)
    db.commit()
    db.refresh(checkin)
    return checkin


def validate_entry(db: Session, gym: Gym, code: str) -> dict:
    """Confirma a entrada do aluno na recepção pelo código da visita.

    O código só vale na academia do check-in e dentro de ENTRY_CODE_VALID_HOURS.
    Validar de novo não dá erro: a recepção vê que já estava confirmado.
    """
    normalized = code.strip().upper().replace(" ", "").replace("-", "")
    since = datetime.now() - timedelta(hours=ENTRY_CODE_VALID_HOURS)
    checkin = db.scalar(
        select(CheckIn)
        .where(
            CheckIn.entry_code == normalized,
            CheckIn.gym_id == gym.id,
            CheckIn.timestamp >= since,
        )
        .order_by(CheckIn.timestamp.desc())
        .limit(1)
    )
    if checkin is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Código inválido ou expirado. Peça para o aluno refazer o check-in no app.",
        )

    already_validated = checkin.validated_at is not None
    if not already_validated:
        checkin.validated_at = datetime.now()
        db.commit()
        db.refresh(checkin)
    return {
        "id": checkin.id,
        "student_name": checkin.student.name,
        "student_university": checkin.student.university,
        "timestamp": checkin.timestamp,
        "validated_at": checkin.validated_at,
        "already_validated": already_validated,
    }
