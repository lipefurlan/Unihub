from pydantic import BaseModel, ConfigDict, Field, field_validator


class PlanOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    monthly_price: float
    tier: int
    color: str
    included_categories: list[str]
    benefits_description: str
    has_running_coach: bool
    is_active: bool = True
    all_gyms: bool = True
    gym_ids: list[int] = []
    max_checkins_per_month: int | None = None
    max_checkins_per_day: int | None = None
    allowed_from: str | None = None
    allowed_until: str | None = None
    restrictions_note: str = ""

    @field_validator("gym_ids", mode="before")
    @classmethod
    def _none_as_empty(cls, v):
        return v or []


class AdminPlanRow(PlanOut):
    """Plano visto pela operação, com quantos alunos assinam hoje."""

    active_subscribers: int = 0


class AdminPlanCreate(BaseModel):
    name: str = Field(min_length=2, max_length=60)
    monthly_price: float = Field(gt=0, le=10000)
    benefits_description: str = ""
    included_categories: list[str] = []
    has_running_coach: bool = False
    is_active: bool = True
    all_gyms: bool = True
    gym_ids: list[int] = []
    max_checkins_per_month: int | None = Field(default=None, ge=1, le=100)
    max_checkins_per_day: int | None = Field(default=None, ge=1, le=10)
    allowed_from: str | None = Field(default=None, pattern=r"^([01]\d|2[0-3]):[0-5]\d$")
    allowed_until: str | None = Field(default=None, pattern=r"^([01]\d|2[0-3]):[0-5]\d$")
    restrictions_note: str = ""


class AdminPlanUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=60)
    monthly_price: float | None = Field(default=None, gt=0, le=10000)
    benefits_description: str | None = None
    included_categories: list[str] | None = None
    has_running_coach: bool | None = None
    is_active: bool | None = None
    all_gyms: bool | None = None
    gym_ids: list[int] | None = None
    # Nos campos de limite e horário, null limpa a restrição
    max_checkins_per_month: int | None = Field(default=None, ge=1, le=100)
    max_checkins_per_day: int | None = Field(default=None, ge=1, le=10)
    allowed_from: str | None = Field(default=None, pattern=r"^([01]\d|2[0-3]):[0-5]\d$")
    allowed_until: str | None = Field(default=None, pattern=r"^([01]\d|2[0-3]):[0-5]\d$")
    restrictions_note: str | None = None
