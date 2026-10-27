from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.schemas.gym import GymPublicOut


class CheckInCreate(BaseModel):
    gym_id: int


class CheckInOut(BaseModel):
    """Visão do estudante (histórico)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    gym: GymPublicOut
    timestamp: datetime
    plan_tier_at_checkin: int


class CheckInCreatedOut(CheckInOut):
    """Resposta do check-in: o aluno vê se a visita entrou no teto pago."""

    is_paid: bool


class GymCheckInOut(BaseModel):
    """Visão da academia: quem fez check-in e o valor de repasse gerado."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    timestamp: datetime
    student_name: str
    student_university: str
    plan_tier_at_checkin: int
    payout_amount_recorded: float
    is_paid: bool  # False = acima do teto mensal do aluno, sem repasse
