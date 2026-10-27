from decimal import Decimal

from sqlalchemy import JSON, Boolean, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class University(Base):
    """IES conveniada: a faculdade que contrata o UniHub para os seus alunos.

    Só estudantes com e-mail de um dos domínios de uma IES ativa podem se
    cadastrar. Os valores do contrato entram na receita da plataforma.
    """

    __tablename__ = "universities"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    # Domínios de e-mail aceitos no cadastro, ex.: ["facamp.edu.br"]
    email_domains: Mapped[list] = mapped_column(JSON, default=list)
    # Contrato: taxa fixa por mês + taxa por aluno que assina
    monthly_fee: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    fee_per_student: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    # Subsídio opcional, igual para todos os alunos: baixa o preço que o aluno paga
    subsidy_per_student: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=Decimal("0"))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")
    # Acesso da IES ao painel (portal da faculdade); vazio = sem login
    email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str | None] = mapped_column(String(255))

    def accepts_email(self, email: str) -> bool:
        domain = email.rsplit("@", 1)[-1].lower()
        return any(domain == d or domain.endswith("." + d) for d in self.email_domains)
