from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.security import get_current_student
from app.models import CheckIn, Student
from app.schemas.checkin import CheckInOut
from app.schemas.student import StudentOut, StudentProfileOut
from app.schemas.subscription import SubscriptionOut

router = APIRouter(prefix="/students/me", tags=["Estudante"])


@router.get("", response_model=StudentProfileOut)
def get_my_profile(student: Student = Depends(get_current_student)):
    profile = StudentOut.model_validate(student).model_dump()
    subscription = student.active_subscription
    profile["subscription"] = SubscriptionOut.model_validate(subscription) if subscription else None
    return profile


@router.get("/subscription", response_model=SubscriptionOut | None)
def get_my_subscription(student: Student = Depends(get_current_student)):
    return student.active_subscription


@router.get("/checkins", response_model=list[CheckInOut])
def get_my_checkins(student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    return db.scalars(
        select(CheckIn)
        .options(selectinload(CheckIn.gym))
        .where(CheckIn.student_id == student.id)
        .order_by(CheckIn.timestamp.desc())
    ).all()
