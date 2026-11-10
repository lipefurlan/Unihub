from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class UniversityRosterEntry(Base):
    """Aluno da lista oficial enviada pela IES (CSV importado pela operação).

    Enquanto a IES não tiver lista importada, basta o domínio do e-mail e o
    código de confirmação. Com lista, só cadastra quem estiver nela.
    O RA fica guardado para o cruzamento futuro com o sistema da faculdade.
    """

    __tablename__ = "university_roster"
    __table_args__ = (UniqueConstraint("university_id", "email", name="uq_roster_university_email"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    university_id: Mapped[int] = mapped_column(ForeignKey("universities.id"), index=True)
    email: Mapped[str] = mapped_column(String(255), index=True)
    name: Mapped[str | None] = mapped_column(String(120))
    ra: Mapped[str | None] = mapped_column(String(40))
    imported_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
