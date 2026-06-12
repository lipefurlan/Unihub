from datetime import date

from pydantic import BaseModel, ConfigDict

from app.schemas.plan import PlanOut


class SubscriptionCreate(BaseModel):
    plan_id: int


class SubscriptionUpdate(BaseModel):
    """Troca de plano e/ou mudança de status (pausar, cancelar)."""

    plan_id: int | None = None
    status: str | None = None  # active | paused | canceled


class SubscriptionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    plan: PlanOut
    start_date: date
    renewal_date: date
    amount: float
    status: str
