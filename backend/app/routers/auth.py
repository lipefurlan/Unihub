from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.rate_limit import limiter
from app.core.security import create_access_token, hash_password, verify_password
from app.models import Admin, Gym, Student
from app.schemas.auth import LoginRequest, StudentRegister, TokenResponse

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/register/student", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
def register_student(request: Request, payload: StudentRegister, db: Session = Depends(get_db)):
    exists = db.scalar(select(Student).where(Student.email == payload.email))
    if exists is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Já existe uma conta com este e-mail.")

    student = Student(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
        university=payload.university,
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
