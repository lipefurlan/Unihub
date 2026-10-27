from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.schemas.subscription import SubscriptionOut


class StudentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    email: EmailStr
    university: str
    photo_url: str | None
    status: str
    weekly_goal: int = 3
    home_city: str | None = None


class StudentProfileOut(StudentOut):
    """Perfil completo: dados do aluno + assinatura vigente."""

    subscription: SubscriptionOut | None = None
    # Subsídio mensal da IES conveniada do aluno (desconta do preço do plano)
    university_subsidy: float = 0


class StudentUpdate(BaseModel):
    """O que o aluno ajusta no próprio perfil."""

    weekly_goal: int | None = Field(default=None, ge=1, le=7)
    home_city: str | None = Field(default=None, max_length=80)


class WeekStat(BaseModel):
    week_start: str  # segunda-feira, YYYY-MM-DD
    checkins: int
    goal_met: bool


class StudentStatsOut(BaseModel):
    """Meta semanal, sequência de semanas e resumo do mês."""

    weekly_goal: int
    week_checkins: int
    streak_weeks: int
    last_weeks: list[WeekStat]
    month_checkins: int
    month_gyms: int
    month_top_gym: str | None
