from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Challenge(Base):
    """Desafio de engajamento: faculdades contra faculdades, ou cursos de uma
    mesma faculdade entre si. O ranking é calculado na hora a partir dos
    check-ins (ver challenge_service)."""

    __tablename__ = "challenges"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(120))
    description: Mapped[str | None] = mapped_column(String(500))
    scope: Mapped[str] = mapped_column(String(20))  # universities | courses
    # Faculdade dona do desafio entre cursos (nulo = desafio entre faculdades)
    university_id: Mapped[int | None] = mapped_column(ForeignKey("universities.id"), index=True)
    # checkins_per_student: check-ins por assinante; active_share: % de assinantes que treinaram
    metric: Mapped[str] = mapped_column(String(30))
    start_date: Mapped[date] = mapped_column(Date)
    end_date: Mapped[date] = mapped_column(Date)
    # Link do placar público (TV, grupo da turma) sem expor o id sequencial
    public_token: Mapped[str] = mapped_column(String(24), unique=True, index=True)
    created_by: Mapped[str] = mapped_column(String(10))  # admin | ies
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    university: Mapped["University | None"] = relationship()  # noqa: F821
