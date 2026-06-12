from pydantic import BaseModel, ConfigDict


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
