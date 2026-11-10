"""Engajamento do aluno: avaliações, sequência de semanas, conquistas e o
desafio do mês entre faculdades."""

from collections import Counter
from datetime import date, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import CheckIn, Gym, Student

# Antes desta hora conta para o selo "Madrugador"
EARLY_HOUR = 8


def attach_ratings(db: Session, gyms: list[Gym]) -> list[Gym]:
    """Preenche rating_avg/rating_count de várias academias com uma consulta só."""
    if not gyms:
        return gyms
    rows = db.execute(
        select(CheckIn.gym_id, func.avg(CheckIn.rating), func.count(CheckIn.rating))
        .where(CheckIn.gym_id.in_([g.id for g in gyms]), CheckIn.rating.is_not(None))
        .group_by(CheckIn.gym_id)
    ).all()
    by_gym = {gym_id: (avg, count) for gym_id, avg, count in rows}
    for gym in gyms:
        avg, count = by_gym.get(gym.id, (None, 0))
        gym.rating_avg = round(float(avg), 1) if avg is not None else None
        gym.rating_count = count
    return gyms


def rate_checkin(db: Session, student: Student, checkin_id: int, stars: int) -> CheckIn:
    checkin = db.get(CheckIn, checkin_id)
    if checkin is None or checkin.student_id != student.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Check-in não encontrado.")
    checkin.rating = stars
    db.commit()
    db.refresh(checkin)
    return checkin


def monday_of(day: date) -> date:
    return day - timedelta(days=day.weekday())


def week_streaks(per_week: Counter, goal: int, today: date) -> tuple[int, int]:
    """(sequência atual, maior sequência) de semanas com a meta batida.

    A semana atual só entra na sequência atual depois que a meta é batida.
    """
    this_monday = monday_of(today)
    current = 0
    week = this_monday if per_week[this_monday] >= goal else this_monday - timedelta(weeks=1)
    while per_week[week] >= goal:
        current += 1
        week -= timedelta(weeks=1)

    best = run = 0
    if per_week:
        week = min(per_week)
        while week <= this_monday:
            run = run + 1 if per_week[week] >= goal else 0
            best = max(best, run)
            week += timedelta(weeks=1)
    return current, max(best, current)


def checkins_per_week(checkins: list[CheckIn]) -> Counter:
    return Counter(monday_of(c.timestamp.date()) for c in checkins)


# (código, título, descrição, alvo, métrica)
BADGES = [
    ("first", "Primeiro treino", "Fez o primeiro check-in", 1, "checkins"),
    ("checkins_10", "10 check-ins", "Dez treinos pelo UniHub", 10, "checkins"),
    ("checkins_50", "50 check-ins", "Cinquenta treinos pelo UniHub", 50, "checkins"),
    ("explorer", "Explorador", "Treinou em 5 academias diferentes", 5, "gyms"),
    ("streak_4", "Sequência de 4 semanas", "Bateu a meta 4 semanas seguidas", 4, "best_streak"),
    ("streak_12", "Sequência de 12 semanas", "Bateu a meta 12 semanas seguidas", 12, "best_streak"),
    ("early", "Madrugador", f"5 treinos antes das {EARLY_HOUR}h", 5, "early"),
    ("reviewer", "Avaliador", "Avaliou 5 visitas", 5, "ratings"),
]


def achievements(db: Session, student: Student) -> dict:
    checkins = db.scalars(select(CheckIn).where(CheckIn.student_id == student.id)).all()
    current, best = week_streaks(checkins_per_week(checkins), student.weekly_goal, date.today())
    metrics = {
        "checkins": len(checkins),
        "gyms": len({c.gym_id for c in checkins}),
        "best_streak": best,
        "early": sum(1 for c in checkins if c.timestamp.hour < EARLY_HOUR),
        "ratings": sum(1 for c in checkins if c.rating is not None),
    }
    badges = [
        {
            "code": code,
            "title": title,
            "description": description,
            "target": target,
            "progress": min(metrics[metric], target),
            "achieved": metrics[metric] >= target,
        }
        for code, title, description, target, metric in BADGES
    ]
    return {
        "total_checkins": metrics["checkins"],
        "gyms_visited": metrics["gyms"],
        "current_streak": current,
        "best_streak": best,
        "badges": badges,
    }


def trending_gyms(db: Session, days: int = 7, limit: int = 5) -> list[tuple[Gym, int]]:
    """Academias com mais check-ins nos últimos dias ("bombando")."""
    since = datetime.now() - timedelta(days=days)
    rows = db.execute(
        select(Gym, func.count(CheckIn.id).label("c"))
        .join(CheckIn, CheckIn.gym_id == Gym.id)
        .where(Gym.is_active.is_(True), CheckIn.timestamp >= since)
        .group_by(Gym.id)
        .order_by(func.count(CheckIn.id).desc(), Gym.name)
        .limit(limit)
    ).all()
    return [(gym, count) for gym, count in rows]


MONTHS_PT = [
    "janeiro", "fevereiro", "março", "abril", "maio", "junho",
    "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
]
