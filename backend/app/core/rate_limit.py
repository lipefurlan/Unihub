"""Rate limiting por IP (anti força-bruta) usando slowapi.

Aplicado nas rotas de autenticação: tentativas de senha ilimitadas são a
porta de entrada mais comum de ataque em APIs públicas.
"""

from fastapi import Request
from fastapi.responses import JSONResponse
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)


def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    return JSONResponse(
        status_code=429,
        content={"detail": "Muitas tentativas. Aguarde um minuto e tente novamente."},
    )
