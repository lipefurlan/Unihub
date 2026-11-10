from pydantic import BaseModel, ConfigDict, Field


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


class AdminPlanUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=60)
    monthly_price: float | None = Field(default=None, gt=0, le=10000)
    benefits_description: str | None = None
    included_categories: list[str] | None = None
    has_running_coach: bool | None = None
    is_active: bool | None = None
