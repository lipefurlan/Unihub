import secrets
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.courses import normalize_course
from app.core.database import get_db
from app.core.rate_limit import limiter
from app.core.security import create_access_token, hash_password, verify_password
from app.models import Student
from app.schemas.auth import (
    ForgotPasswordRequest,
    GoogleLoginRequest,
    LoginRequest,
    MessageResponse,
    ResetPasswordRequest,
    StudentRegister,
    TokenResponse,
)
from app.services.google_auth_service import verify_google_credential
from app.services.password_reset_service import find_account, request_password_reset, reset_password
from app.services.roster_service import require_in_roster
from app.services.university_service import require_university_for_email
from app.services.verification_service import normalize_phone, send_pending_codes

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/register/student", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
def register_student(request: Request, payload: StudentRegister, db: Session = Depends(get_db)):
    """Cadastro do aluno com o e-mail da faculdade (+ celular de WhatsApp).

    A IES vem do domínio do e-mail institucional (e, se ela enviou a lista de
    alunos, o e-mail precisa estar nela). Um código vai para o e-mail; o aluno
    entra no app na hora, mas só assina depois de confirmar. Se o cliente
    mandar também um e-mail pessoal, cada um recebe o seu código.
    """
    personal = payload.email.lower()
    institutional = (payload.institutional_email or payload.email).lower()

    for email in {personal, institutional}:
        _, existing = find_account(db, email)
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Já existe uma conta com o e-mail {email}. Faça login ou use \"Esqueci minha senha\".",
            )

    university = require_university_for_email(db, institutional)
    require_in_roster(db, university, institutional)
    student = Student(
        name=payload.name,
        email=personal,
        institutional_email=institutional,
        password_hash=hash_password(payload.password),
        university=university.name,
        university_id=university.id,
        course=normalize_course(payload.course),
        phone=normalize_phone(payload.phone),
    )
    db.add(student)
    db.commit()
    db.refresh(student)
    send_pending_codes(db, student)
    return TokenResponse(access_token=create_access_token(student.id, "student"), role="student")


@router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
def login(request: Request, payload: LoginRequest, db: Session = Depends(get_db)):
    """Login único para estudante, academia, admin e IES; o role vai no JWT."""
    role, account = find_account(db, payload.email)
    if account is not None and verify_password(payload.password, account.password_hash):
        return TokenResponse(access_token=create_access_token(account.id, role), role=role)

    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="E-mail ou senha incorretos.")


@router.post("/google", response_model=TokenResponse)
@limiter.limit("10/minute")
def login_google(request: Request, payload: GoogleLoginRequest, db: Session = Depends(get_db)):
    """Login com Google para qualquer perfil; cadastra estudante no primeiro acesso.

    Conta já existente (estudante, academia ou admin) com o mesmo e-mail entra
    direto. E-mail novo vira estudante, desde que seja de uma IES conveniada.
    """
    info = verify_google_credential(payload.credential)
    email = info["email"].lower()

    role, account = find_account(db, email)
    if account is not None:
        return TokenResponse(access_token=create_access_token(account.id, role), role=role)

    if not payload.allow_signup:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Não existe conta com este e-mail.")

    university = require_university_for_email(db, email)
    require_in_roster(db, university, email)
    now = datetime.now()
    student = Student(
        name=info.get("name") or email.split("@")[0],
        email=email,
        # O Google já garante que o e-mail é da pessoa: nasce confirmado.
        # Ela pode cadastrar um e-mail pessoal depois, no perfil.
        institutional_email=email,
        email_verified_at=now,
        institutional_email_verified_at=now,
        # Senha aleatória que ninguém conhece: a conta entra pelo Google e,
        # se quiser senha, usa "Esqueci minha senha"
        password_hash=hash_password(secrets.token_urlsafe(32)),
        university=university.name,
        university_id=university.id,
        photo_url=info.get("picture"),
    )
    db.add(student)
    db.commit()
    db.refresh(student)
    return TokenResponse(access_token=create_access_token(student.id, "student"), role="student")


@router.post("/forgot-password", response_model=MessageResponse)
@limiter.limit("5/minute")
def forgot_password(request: Request, payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    request_password_reset(db, payload.email.lower())
    # Mesma resposta exista ou não a conta (não revela quem está cadastrado)
    return MessageResponse(
        detail="Se houver uma conta com este e-mail, enviamos um link para redefinir a senha."
    )


@router.post("/reset-password", response_model=MessageResponse)
@limiter.limit("10/minute")
def reset_password_route(request: Request, payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    reset_password(db, payload.token, payload.new_password)
    return MessageResponse(detail="Senha alterada. Faça login com a nova senha.")
