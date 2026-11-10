from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Table, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


# Academias favoritas do aluno (muitos para muitos)
favorite_gyms = Table(
    "favorite_gyms",
    Base.metadata,
    Column("student_id", ForeignKey("students.id"), primary_key=True),
    Column("gym_id", ForeignKey("gyms.id"), primary_key=True),
)


class Student(Base):
    __tablename__ = "students"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    # E-mail pessoal: é o login e onde chegam os avisos (continua valendo
    # depois que o aluno se forma ou perde o acesso ao e-mail da faculdade)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    # E-mail institucional: prova o vínculo com a IES (domínio e, se a IES
    # enviou a lista de alunos, presença nessa lista). Também serve de login.
    institutional_email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True)
    # Confirmação por código enviado a cada e-mail (vazio = ainda não confirmou)
    email_verified_at: Mapped[datetime | None] = mapped_column(DateTime)
    # Celular com WhatsApp (só dígitos, com DDI). A confirmação por código no
    # WhatsApp entra quando houver a integração; por ora só guardamos.
    phone: Mapped[str | None] = mapped_column(String(20))
    phone_verified_at: Mapped[datetime | None] = mapped_column(DateTime)
    institutional_email_verified_at: Mapped[datetime | None] = mapped_column(DateTime)
    password_hash: Mapped[str] = mapped_column(String(255))
    university: Mapped[str] = mapped_column(String(120))
    # IES conveniada do aluno (definida pelo domínio do e-mail no cadastro)
    university_id: Mapped[int | None] = mapped_column(ForeignKey("universities.id"), index=True)
    photo_url: Mapped[str | None] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(20), default="active")  # active | inactive
    # Meta de treinos por semana (definida pelo aluno no app)
    weekly_goal: Mapped[int] = mapped_column(Integer, default=3, server_default="3")
    # Cidade de origem: onde o aluno passa fins de semana e férias
    home_city: Mapped[str | None] = mapped_column(String(80))
    # Curso de graduação: permite desafios entre cursos da mesma faculdade
    course: Mapped[str | None] = mapped_column(String(80), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    university_ref: Mapped["University | None"] = relationship()  # noqa: F821
    favorite_gyms: Mapped[list["Gym"]] = relationship(secondary=favorite_gyms)  # noqa: F821
    subscriptions: Mapped[list["Subscription"]] = relationship(back_populates="student")  # noqa: F821
    checkins: Mapped[list["CheckIn"]] = relationship(back_populates="student")  # noqa: F821

    @property
    def email_verified(self) -> bool:
        return self.email_verified_at is not None

    @property
    def institutional_email_verified(self) -> bool:
        return self.institutional_email_verified_at is not None

    @property
    def is_verified(self) -> bool:
        """Só assina plano quem confirmou os dois e-mails."""
        return self.email_verified and self.institutional_email_verified

    @property
    def active_subscription(self):
        """Assinatura vigente do estudante (ativa ou pausada), se houver."""
        for sub in self.subscriptions:
            if sub.status in ("active", "paused"):
                return sub
        return None
