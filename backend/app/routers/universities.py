from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.courses import COURSES
from app.core.database import get_db
from app.models import University

router = APIRouter(prefix="/universities", tags=["IES conveniadas"])


class UniversityPublicOut(BaseModel):
    id: int
    name: str
    email_domains: list[str]
    subsidy_per_student: float


@router.get("", response_model=list[UniversityPublicOut])
def list_universities(db: Session = Depends(get_db)):
    """IES conveniadas: só alunos com e-mail destes domínios podem se cadastrar."""
    rows = db.scalars(
        select(University).where(University.is_active.is_(True)).order_by(University.name)
    ).all()
    return [
        UniversityPublicOut(
            id=u.id,
            name=u.name, email_domains=u.email_domains, subsidy_per_student=float(u.subsidy_per_student)
        )
        for u in rows
    ]


@router.get("/courses", response_model=list[str])
def list_courses():
    """Cursos aceitos no cadastro (agrupam os desafios entre cursos)."""
    return COURSES
