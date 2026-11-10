from decimal import Decimal

from sqlalchemy import JSON, Boolean, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Plan(Base):
    __tablename__ = "plans"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(60))  # "Plano 1" … "Plano 7"
    monthly_price: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    tier: Mapped[int] = mapped_column(Integer, unique=True, index=True)
    color: Mapped[str] = mapped_column(String(9))  # hex usado na UI (estilo tier Wellhub)
    included_categories: Mapped[list] = mapped_column(JSON, default=list)
    benefits_description: Mapped[str] = mapped_column(Text, default="")
    # Plano 3+: inclui 1 plano de treino mensal de assessoria de corrida
    has_running_coach: Mapped[bool] = mapped_column(Boolean, default=False)
    # Plano desativado some da vitrine do app; quem já assina continua nele
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")

    # Academias do plano: todas (respeitando o tier mínimo de cada academia)
    # ou só as escolhidas pela operação em gym_ids
    all_gyms: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")
    gym_ids: Mapped[list] = mapped_column(JSON, default=list)

    # Restrições de uso (None = sem limite)
    max_checkins_per_month: Mapped[int | None] = mapped_column(Integer, nullable=True)
    max_checkins_per_day: Mapped[int | None] = mapped_column(Integer, nullable=True)
    allowed_from: Mapped[str | None] = mapped_column(String(5), nullable=True)  # "HH:MM"
    allowed_until: Mapped[str | None] = mapped_column(String(5), nullable=True)  # "HH:MM"
    restrictions_note: Mapped[str] = mapped_column(Text, default="", server_default="")

    def covers_gym(self, gym) -> bool:
        if self.all_gyms:
            return self.tier >= gym.min_plan_tier
        return gym.id in (self.gym_ids or [])
