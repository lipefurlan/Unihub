from pydantic import BaseModel, ConfigDict, Field


class GymPublicOut(BaseModel):
    """Visão do estudante: sem o valor de repasse (dado comercial da academia)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    address: str
    latitude: float
    longitude: float
    modalities: list[str]
    min_plan_tier: int
    capacity: int
    opening_hours: str
    photo_url: str | None
    city: str
    rating_avg: float | None = None
    rating_count: int = 0


class GymOwnerOut(GymPublicOut):
    """Visão da própria academia no painel: inclui dados comerciais."""

    email: str
    checkin_payout_amount: float
    is_active: bool


class GymUpdate(BaseModel):
    """Campos que a própria academia pode editar.

    Valor de repasse e tier mínimo são cláusulas comerciais do contrato com a
    UniHub: a academia vê, mas só o admin altera (ver AdminGymUpdate).
    """

    name: str | None = None
    address: str | None = None
    modalities: list[str] | None = None
    capacity: int | None = Field(default=None, gt=0)
    opening_hours: str | None = None


class HourCount(BaseModel):
    hour: int
    checkins: int


class GymBusyHoursOut(BaseModel):
    """Movimento por hora nos últimos 30 dias (check-ins UniHub)."""

    hours: list[HourCount]
    quietest_start: int | None  # início da faixa de 2h mais vazia
    quietest_end: int | None


class TrendingGymOut(BaseModel):
    gym: GymPublicOut
    recent_checkins: int  # check-ins UniHub nos últimos 7 dias
