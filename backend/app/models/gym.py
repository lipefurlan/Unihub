from decimal import Decimal

from sqlalchemy import JSON, Boolean, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Gym(Base):
    __tablename__ = "gyms"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)  # login do painel
    password_hash: Mapped[str] = mapped_column(String(255))
    address: Mapped[str] = mapped_column(String(255))
    latitude: Mapped[float]
    longitude: Mapped[float]
    modalities: Mapped[list] = mapped_column(JSON, default=list)  # ex.: ["musculação", "crossfit"]
    # Tier mínimo de plano que dá acesso a esta academia
    min_plan_tier: Mapped[int] = mapped_column(Integer, default=1)
    # Valor repassado à academia a cada check-in (snapshot copiado para o CheckIn)
    checkin_payout_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    capacity: Mapped[int] = mapped_column(Integer, default=100)
    opening_hours: Mapped[str] = mapped_column(String(120), default="06:00–22:00")
    photo_url: Mapped[str | None] = mapped_column(String(500))
    # Academia desativada some do app e não aceita check-ins (controle do admin)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")

    checkins: Mapped[list["CheckIn"]] = relationship(back_populates="gym")  # noqa: F821
    payouts: Mapped[list["Payout"]] = relationship(back_populates="gym")  # noqa: F821
