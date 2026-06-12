from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Payout(Base):
    """Repasse mensal consolidado de uma academia.

    valor_total = soma dos payout_amount_recorded dos check-ins do mês.
    """

    __tablename__ = "payouts"
    __table_args__ = (UniqueConstraint("gym_id", "reference_month", name="uq_payout_gym_month"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    gym_id: Mapped[int] = mapped_column(ForeignKey("gyms.id"), index=True)
    reference_month: Mapped[str] = mapped_column(String(7), index=True)  # "YYYY-MM"
    total_checkins: Mapped[int] = mapped_column(Integer, default=0)
    total_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0)
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending | paid
    paid_at: Mapped[datetime | None] = mapped_column(DateTime)

    gym: Mapped["Gym"] = relationship(back_populates="payouts")  # noqa: F821
