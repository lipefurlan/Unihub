from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Numeric, String
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
    # Visita remunerada? Só as primeiras visitas do aluno no mês (teto
    # MAX_PAID_CHECKINS_PER_MONTH, somando todas as academias) geram repasse;
    # as seguintes entram com repasse zero e is_paid = False.
    is_paid: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")
    # Código de entrada da visita (QR mostrado pelo aluno, lido pela recepção).
    # Vale só para esta visita, como um ingresso; validated_at = entrada confirmada.
    entry_code: Mapped[str | None] = mapped_column(String(12), index=True)
    validated_at: Mapped[datetime | None] = mapped_column(DateTime)

    student: Mapped["Student"] = relationship(back_populates="checkins")  # noqa: F821
    gym: Mapped["Gym"] = relationship(back_populates="checkins")  # noqa: F821
