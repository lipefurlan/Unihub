import hashlib
import secrets
from datetime import datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import hash_password
from app.models import Admin, Gym, PasswordResetToken, Student, University
from app.services.email_service import send_email

# Ordem de busca por e-mail (a mesma do login); "ies" é o portal da faculdade
ACCOUNT_MODELS = {"student": Student, "gym": Gym, "admin": Admin, "ies": University}


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def find_account(db: Session, email: str):
    """Procura o e-mail nas bases de contas (mesma ordem do login)."""
    for role, model in ACCOUNT_MODELS.items():
        account = db.scalar(select(model).where(model.email == email))
        if account is not None and account.password_hash is not None:
            return role, account
    return None, None


def request_password_reset(db: Session, email: str) -> None:
    """Gera o link de redefinição e envia por e-mail, se a conta existir.

    Não informa se o e-mail está cadastrado (evita descobrir contas alheias).
    """
    role, account = find_account(db, email)
    if account is None:
        return

    token = secrets.token_urlsafe(32)
    db.add(
        PasswordResetToken(
            role=role,
            account_id=account.id,
            token_hash=_hash_token(token),
            expires_at=datetime.now() + timedelta(minutes=settings.password_reset_expire_minutes),
        )
    )
    db.commit()

    # Estudante redefine no app; academia, admin e IES, no painel. Os apps Flutter
    # web usam rotas com "#" (estratégia padrão de URL), daí o "/#/".
    base_url = settings.student_app_url if role == "student" else settings.panel_app_url
    link = f"{base_url.rstrip('/')}/#/redefinir-senha?token={token}"
    minutes = settings.password_reset_expire_minutes
    send_email(
        to=account.email,
        subject="UniHub — redefinição de senha",
        html=(
            f"<p>Olá, {account.name}!</p>"
            "<p>Recebemos um pedido para redefinir a senha da sua conta UniHub.</p>"
            f'<p><a href="{link}">Clique aqui para criar uma nova senha</a>. '
            f"O link vale por {minutes} minutos e só pode ser usado uma vez.</p>"
            "<p>Se não foi você, é só ignorar este e-mail: sua senha continua a mesma.</p>"
        ),
    )


def reset_password(db: Session, token: str, new_password: str) -> None:
    reset = db.scalar(select(PasswordResetToken).where(PasswordResetToken.token_hash == _hash_token(token)))
    if reset is None or reset.used_at is not None or reset.expires_at < datetime.now():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Link inválido ou expirado. Peça um novo em \"Esqueci minha senha\".",
        )

    account = db.get(ACCOUNT_MODELS[reset.role], reset.account_id)
    if account is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Conta não encontrada.")

    account.password_hash = hash_password(new_password)
    reset.used_at = datetime.now()
    db.commit()
