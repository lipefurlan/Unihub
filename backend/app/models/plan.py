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
