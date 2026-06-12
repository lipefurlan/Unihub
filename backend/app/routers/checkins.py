from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_student
from app.models import Student
from app.schemas.checkin import CheckInCreate, CheckInOut
from app.services import checkin_service

router = APIRouter(prefix="/checkins", tags=["Check-ins"])


@router.post("", response_model=CheckInOut, status_code=status.HTTP_201_CREATED)
def create_checkin(
    payload: CheckInCreate,
    student: Student = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    """Faz check-in aplicando as regras de tier e anti-fraude (ver checkin_service)."""
    return checkin_service.create_checkin(db, student, payload.gym_id)
