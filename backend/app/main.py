from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.rate_limit import limiter, rate_limit_handler
from app.routers import admin, auth, checkins, gym_portal, gyms, plans, students, subscriptions

app = FastAPI(
    title="UniHub API",
    description=(
        "API do POC UniHub — plataforma agregadora de bem-estar para universitários. "
        "Modelo B2B2C com repasse por check-in às academias parceiras."
    ),
    version="0.1.0",
)

# Rate limiting por IP nas rotas de auth (ver app/core/rate_limit.py)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_handler)

# CORS: dev local + domínios publicados (configurável via CORS_ORIGIN_REGEX)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=settings.cors_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(plans.router)
app.include_router(students.router)
app.include_router(subscriptions.router)
app.include_router(checkins.router)
# gym_portal (/gyms/me) precisa vir antes de gyms (/gyms/{gym_id})
app.include_router(gym_portal.router)
app.include_router(gyms.router)
app.include_router(admin.router)

# Fotos das academias enviadas pelo admin (POC: disco local; produção: S3/R2)
_uploads_dir = Path(__file__).resolve().parents[1] / "uploads"
_uploads_dir.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=_uploads_dir), name="uploads")


@app.get("/", include_in_schema=False)
def root():
    return {"service": "UniHub API", "docs": "/docs"}
