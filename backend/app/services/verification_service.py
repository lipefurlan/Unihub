"""Confirmação dos e-mails do aluno por código de 6 dígitos (enviado pelo Resend)."""

import hashlib
import hmac
import re
import secrets
from datetime import datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import EmailVerificationCode, Student
from app.services.email_service import send_email

KINDS = ("personal", "institutional")


def normalize_phone(raw: str | None) -> str | None:
    """Guarda só dígitos, com DDI 55 quando vier no formato nacional."""
    if not raw:
        return None
    digits = re.sub(r"\D", "", raw)
    if len(digits) in (10, 11):  # DDD + número
        digits = "55" + digits
    if not 12 <= len(digits) <= 15:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Celular inválido. Use DDD + número, ex.: (19) 99999-0000.",
        )
    return digits


def _hash_code(student_id: int, kind: str, code: str) -> str:
    # O código tem só 6 dígitos: o "sal" com aluno e tipo evita tabela pronta,
    # e o limite de tentativas impede força bruta.
    raw = f"{student_id}:{kind}:{code}:{settings.secret_key}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def target_email(student: Student, kind: str) -> str:
    return student.email if kind == "personal" else (student.institutional_email or student.email)


def is_verified(student: Student, kind: str) -> bool:
    return student.email_verified if kind == "personal" else student.institutional_email_verified


def same_address(student: Student) -> bool:
    return (student.institutional_email or student.email) == student.email


def _mark_verified(student: Student, kind: str, when: datetime) -> None:
    if kind == "personal" or same_address(student):
        student.email_verified_at = student.email_verified_at or when
    if kind == "institutional" or same_address(student):
        student.institutional_email_verified_at = student.institutional_email_verified_at or when


def _canonical_kind(student: Student, kind: str) -> str:
    if kind not in KINDS:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Tipo de e-mail inválido.")
    # Um e-mail só (o da faculdade): um código só, qualquer que seja o tipo pedido
    return "institutional" if same_address(student) else kind


def send_code(db: Session, student: Student, kind: str, *, enforce_cooldown: bool = True) -> None:
    """Gera um código novo (invalida os anteriores) e manda para o e-mail."""
    kind = _canonical_kind(student, kind)
    if is_verified(student, kind):
        return

    now = datetime.now()
    if enforce_cooldown:
        last = db.scalar(
            select(EmailVerificationCode)
            .where(EmailVerificationCode.student_id == student.id, EmailVerificationCode.kind == kind)
            .order_by(EmailVerificationCode.id.desc())
        )
        wait = settings.verification_code_resend_seconds
        if last is not None and last.created_at and last.created_at > now - timedelta(seconds=wait):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Acabamos de enviar um código. Aguarde {wait} segundos para pedir outro.",
            )

    db.execute(
        update(EmailVerificationCode)
        .where(
            EmailVerificationCode.student_id == student.id,
            EmailVerificationCode.kind == kind,
            EmailVerificationCode.used_at.is_(None),
        )
        .values(used_at=now)
    )
    code = f"{secrets.randbelow(1_000_000):06d}"
    email = target_email(student, kind)
    db.add(
        EmailVerificationCode(
            student_id=student.id,
            kind=kind,
            email=email,
            code_hash=_hash_code(student.id, kind, code),
            expires_at=now + timedelta(minutes=settings.verification_code_expire_minutes),
            created_at=now,
        )
    )
    db.commit()

    label = "seu e-mail" if same_address(student) else (
        "seu e-mail pessoal" if kind == "personal" else "seu e-mail da faculdade"
    )
    minutes = settings.verification_code_expire_minutes
    send_email(
        to=email,
        subject=f"UniHub — seu código é {code}",
        html=(
            f"<p>Olá, {student.name}!</p>"
            f"<p>Use o código abaixo para confirmar {label} no UniHub:</p>"
            f'<p style="font-size:28px;font-weight:700;letter-spacing:6px">{code}</p>'
            f"<p>Ele vale por {minutes} minutos. Se não foi você que criou a conta, é só ignorar este e-mail.</p>"
        ),
    )


def send_pending_codes(db: Session, student: Student) -> None:
    """Depois do cadastro: um código para cada e-mail ainda não confirmado."""
    send_code(db, student, "institutional", enforce_cooldown=False)
    if not same_address(student):
        send_code(db, student, "personal", enforce_cooldown=False)


def confirm_code(db: Session, student: Student, kind: str, code: str) -> None:
    kind = _canonical_kind(student, kind)
    if is_verified(student, kind):
        return

    now = datetime.now()
    pending = db.scalar(
        select(EmailVerificationCode)
        .where(
            EmailVerificationCode.student_id == student.id,
            EmailVerificationCode.kind == kind,
            EmailVerificationCode.used_at.is_(None),
        )
        .order_by(EmailVerificationCode.id.desc())
    )
    if pending is None or pending.expires_at < now or pending.email != target_email(student, kind):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Código expirado. Peça um novo código.",
        )
    if pending.attempts >= settings.verification_code_max_attempts:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Muitas tentativas erradas. Peça um novo código.",
        )

    if not hmac.compare_digest(pending.code_hash, _hash_code(student.id, kind, code.strip())):
        pending.attempts += 1
        db.commit()
        left = settings.verification_code_max_attempts - pending.attempts
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Código incorreto. Restam {left} tentativa(s)." if left > 0
            else "Código incorreto. Peça um novo código.",
        )

    pending.used_at = now
    _mark_verified(student, kind, now)
    db.commit()


def require_verified(student: Student) -> None:
    if settings.email_verification_required and not student.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Confirme seu e-mail pessoal e o da faculdade com os códigos que enviamos antes de assinar.",
        )
