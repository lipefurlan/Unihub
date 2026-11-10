from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import University

router = APIRouter(prefix="/universities", tags=["IES conveniadas"])


class UniversityPublicOut(BaseModel):
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
            name=u.name, email_domains=u.email_domains, subsidy_per_student=float(u.subsidy_per_student)
        )
        for u in rows
    ]
