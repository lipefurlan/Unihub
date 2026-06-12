from datetime import datetime

from pydantic import BaseModel

from app.schemas.checkin import GymCheckInOut


class PayoutOut(BaseModel):
    reference_month: str  # "YYYY-MM"
    total_checkins: int
    total_amount: float
    status: str  # pending | paid
    paid_at: datetime | None = None


class PayoutDetailOut(PayoutOut):
    """Detalhamento: os check-ins que compõem o repasse do mês."""

    checkins: list[GymCheckInOut]


class DailyCount(BaseModel):
    date: str  # "YYYY-MM-DD"
    count: int


class HourRangeCount(BaseModel):
    label: str  # ex.: "06h–09h"
    count: int


class GymDashboardOut(BaseModel):
    month_checkins: int
    unique_students: int
    estimated_revenue: float
    prev_month_checkins: int
    prev_month_revenue: float
    checkins_by_day: list[DailyCount]
    checkins_by_hour_range: list[HourRangeCount]


class GymStudentRow(BaseModel):
    """Linha da tabela de gestão de alunos do painel."""

    student_id: int
    name: str
    university: str
    plan_name: str | None
    total_checkins: int
    last_checkin: datetime
