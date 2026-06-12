from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class AdminOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    email: EmailStr


class AdminGymCreate(BaseModel):
    """Credenciamento de uma nova academia parceira (feito pela operação)."""

    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6)
    address: str = Field(min_length=5)
    latitude: float
    longitude: float
    modalities: list[str] = Field(min_length=1)
    min_plan_tier: int = Field(ge=1, le=7)
    checkin_payout_amount: float = Field(gt=0)
    capacity: int = Field(gt=0, default=100)
    opening_hours: str = "06:00–22:00"


class AdminGymUpdate(BaseModel):
    """Edição completa pelo admin — inclui as cláusulas comerciais."""

    name: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    modalities: list[str] | None = None
    min_plan_tier: int | None = Field(default=None, ge=1, le=7)
    checkin_payout_amount: float | None = Field(default=None, gt=0)
    capacity: int | None = Field(default=None, gt=0)
    opening_hours: str | None = None
    is_active: bool | None = None


class AdminGymRow(BaseModel):
    """Linha da tabela de academias parceiras (clientes da plataforma)."""

    id: int
    name: str
    email: str
    address: str
    latitude: float
    longitude: float
    modalities: list[str]
    min_plan_tier: int
    checkin_payout_amount: float
    capacity: int
    opening_hours: str
    photo_url: str | None
    is_active: bool
    month_checkins: int
    month_amount: float


class AdminPayoutRow(BaseModel):
    """Repasse consolidado de uma academia em um mês (visão do caixa)."""

    gym_id: int
    gym_name: str
    reference_month: str
    total_checkins: int
    total_amount: float
    status: str  # pending | paid
    paid_at: datetime | None = None


class AdminStudentRow(BaseModel):
    id: int
    name: str
    email: str
    university: str
    plan_name: str | None
    subscription_status: str | None
    total_checkins: int


class TopGym(BaseModel):
    gym_name: str
    checkins: int


class PlatformOverview(BaseModel):
    """Métricas da operação no mês corrente."""

    active_students: int
    subscription_revenue: float  # receita mensal de assinaturas ativas
    month_checkins: int
    month_payout_total: float  # total devido às academias no mês
    estimated_margin: float  # receita - repasses
    active_gyms: int
    top_gyms: list[TopGym]
