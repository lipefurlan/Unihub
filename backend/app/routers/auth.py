import secrets

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.rate_limit import limiter
from app.core.security import create_access_token, hash_password, verify_password
from app.models import Admin, Gym, Student
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
from app.services.university_service import require_university_for_email

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/register/student", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
def register_student(request: Request, payload: StudentRegister, db: Session = Depends(get_db)):
    exists = db.scalar(select(Student).where(Student.email == payload.email))
    if exists is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Já existe uma conta com este e-mail.")

    university = require_university_for_email(db, payload.email)
    student = Student(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
        university=university.name,
        university_id=university.id,
    )
    db.add(student)
    db.commit()
    db.refresh(student)
    return TokenResponse(access_token=create_access_token(student.id, "student"), role="student")


@router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
def login(request: Request, payload: LoginRequest, db: Session = Depends(get_db)):
    """Login único: tenta estudante e depois academia; o role vai no JWT."""
    student = db.scalar(select(Student).where(Student.email == payload.email))
    if student is not None and verify_password(payload.password, student.password_hash):
        return TokenResponse(access_token=create_access_token(student.id, "student"), role="student")

    gym = db.scalar(select(Gym).where(Gym.email == payload.email))
    if gym is not None and verify_password(payload.password, gym.password_hash):
        return TokenResponse(access_token=create_access_token(gym.id, "gym"), role="gym")

    admin = db.scalar(select(Admin).where(Admin.email == payload.email))
    if admin is not None and verify_password(payload.password, admin.password_hash):
        return TokenResponse(access_token=create_access_token(admin.id, "admin"), role="admin")

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
    student = Student(
        name=info.get("name") or email.split("@")[0],
        email=email,
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
