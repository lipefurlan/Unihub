from fastapi import HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from app.core.config import settings


def verify_google_credential(credential: str) -> dict:
    """Valida o ID token emitido pelo Google Identity Services.

    Confere assinatura, validade e se o token foi emitido para o nosso
    Client ID. Retorna os dados da conta Google (email, name, picture...).
    """
    if not settings.google_client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Login com Google não está configurado.",
        )
    try:
        info = id_token.verify_oauth2_token(credential, google_requests.Request(), settings.google_client_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Login com Google inválido.")

    if not info.get("email") or not info.get("email_verified"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sua conta Google não tem um e-mail verificado.",
        )
    return info
