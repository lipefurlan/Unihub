from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class CheckIn(Base):
    __tablename__ = "checkins"

    id: Mapped[int] = mapped_column(primary_key=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True)
    gym_id: Mapped[int] = mapped_column(ForeignKey("gyms.id"), index=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, index=True)
    # Snapshot do tier do plano do aluno no momento do check-in
    plan_tier_at_checkin: Mapped[int] = mapped_column(Integer)
    # Snapshot do valor de repasse da academia no momento do check-in.
    # O repasse mensal é a soma destes valores — mudanças futuras no valor
    # da academia não afetam check-ins já registrados.
    payout_amount_recorded: Mapped[Decimal] = mapped_column(Numeric(10, 2))

    student: Mapped["Student"] = relationship(back_populates="checkins")  # noqa: F821
    gym: Mapped["Gym"] = relationship(back_populates="checkins")  # noqa: F821
