from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Student(Base):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    university: Mapped[str] = mapped_column(String(120))
    # IES conveniada do aluno (definida pelo domínio do e-mail no cadastro)
    university_id: Mapped[int | None] = mapped_column(ForeignKey("universities.id"), index=True)
    photo_url: Mapped[str | None] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(20), default="active")  # active | inactive
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    university_ref: Mapped["University | None"] = relationship()  # noqa: F821
    subscriptions: Mapped[list["Subscription"]] = relationship(back_populates="student")  # noqa: F821
    checkins: Mapped[list["CheckIn"]] = relationship(back_populates="student")  # noqa: F821

    @property
    def active_subscription(self):
        """Assinatura vigente do estudante (ativa ou pausada), se houver."""
        for sub in self.subscriptions:
            if sub.status in ("active", "paused"):
                return sub
        return None
