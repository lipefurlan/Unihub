from collections import Counter
from datetime import date, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.security import get_current_student
from app.models import CheckIn, Gym, Student
from app.schemas.checkin import CheckInOut
from app.schemas.gym import GymPublicOut
from app.schemas.student import (
    AchievementsOut,
    ChallengeOut,
    StudentOut,
    StudentProfileOut,
    StudentStatsOut,
    StudentUpdate,
)
from app.schemas.subscription import SubscriptionOut
from app.services import engagement_service

router = APIRouter(prefix="/students/me", tags=["Estudante"])

# Semanas mostradas no histórico da meta
STATS_WEEKS = 8


def _profile(student: Student) -> dict:
    profile = StudentOut.model_validate(student).model_dump()
    subscription = student.active_subscription
    profile["subscription"] = SubscriptionOut.model_validate(subscription) if subscription else None
    university = student.university_ref
    profile["university_subsidy"] = float(university.subsidy_per_student) if university else 0
    return profile


@router.get("", response_model=StudentProfileOut)
def get_my_profile(student: Student = Depends(get_current_student)):
    return _profile(student)


@router.put("", response_model=StudentProfileOut)
def update_my_profile(
    payload: StudentUpdate,
    student: Student = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    data = payload.model_dump(exclude_unset=True)
    if "weekly_goal" in data and data["weekly_goal"] is not None:
        student.weekly_goal = data["weekly_goal"]
    if "home_city" in data:
        student.home_city = (data["home_city"] or "").strip() or None
    db.commit()
    db.refresh(student)
    return _profile(student)


@router.get("/subscription", response_model=SubscriptionOut | None)
def get_my_subscription(student: Student = Depends(get_current_student)):
    return student.active_subscription


@router.get("/checkins", response_model=list[CheckInOut])
def get_my_checkins(student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    checkins = db.scalars(
        select(CheckIn)
        .options(selectinload(CheckIn.gym))
        .where(CheckIn.student_id == student.id)
        .order_by(CheckIn.timestamp.desc())
    ).all()
    engagement_service.attach_ratings(db, list({c.gym_id: c.gym for c in checkins}.values()))
    return checkins


@router.get("/stats", response_model=StudentStatsOut)
def get_my_stats(student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    """Meta semanal (semanas de segunda a domingo), sequência e resumo do mês."""
    today = date.today()
    this_monday = today - timedelta(days=today.weekday())
    # Busca 1 ano para a sequência poder passar das semanas exibidas
    since = datetime.combine(this_monday - timedelta(weeks=52), datetime.min.time())
    checkins = db.scalars(
        select(CheckIn)
        .options(selectinload(CheckIn.gym))
        .where(CheckIn.student_id == student.id, CheckIn.timestamp >= since)
    ).all()

    per_week = engagement_service.checkins_per_week(checkins)
    goal = student.weekly_goal
    streak, _ = engagement_service.week_streaks(per_week, goal, today)

    last_weeks = []
    for i in range(STATS_WEEKS - 1, -1, -1):
        monday = this_monday - timedelta(weeks=i)
        last_weeks.append(
            {"week_start": monday.isoformat(), "checkins": per_week[monday], "goal_met": per_week[monday] >= goal}
        )

    month = [c for c in checkins if c.timestamp.year == today.year and c.timestamp.month == today.month]
    gyms = Counter(c.gym.name for c in month)
    return {
        "weekly_goal": goal,
        "week_checkins": per_week[this_monday],
        "streak_weeks": streak,
        "last_weeks": last_weeks,
        "month_checkins": len(month),
        "month_gyms": len(gyms),
        "month_top_gym": gyms.most_common(1)[0][0] if gyms else None,
    }


@router.get("/favorites", response_model=list[GymPublicOut])
def get_my_favorites(student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    return engagement_service.attach_ratings(db, sorted(student.favorite_gyms, key=lambda g: g.name))


@router.get("/achievements", response_model=AchievementsOut)
def get_my_achievements(student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    """Totais, sequência atual e a melhor, e os selos (conquistados ou em progresso)."""
    return engagement_service.achievements(db, student)


@router.get("/challenge", response_model=ChallengeOut)
def get_challenge(student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    """Desafio do mês entre faculdades, com a posição da faculdade do aluno."""
    return engagement_service.university_challenge(db, student)


@router.put("/favorites/{gym_id}", status_code=status.HTTP_204_NO_CONTENT)
def add_favorite(gym_id: int, student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    gym = db.get(Gym, gym_id)
    if gym is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academia não encontrada.")
    if gym not in student.favorite_gyms:
        student.favorite_gyms.append(gym)
        db.commit()


@router.delete("/favorites/{gym_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_favorite(gym_id: int, student: Student = Depends(get_current_student), db: Session = Depends(get_db)):
    student.favorite_gyms = [g for g in student.favorite_gyms if g.id != gym_id]
    db.commit()
