import logging

import requests

from app.core.config import settings

logger = logging.getLogger("unihub.email")

RESEND_URL = "https://api.resend.com/emails"


def send_email(to: str, subject: str, html: str) -> None:
    """Envia um e-mail transacional pelo Resend.

    Sem RESEND_API_KEY (ambiente local), não envia nada: só registra no log,
    para dar para testar o fluxo copiando o link do terminal.
    """
    if not settings.resend_api_key:
        logger.warning("RESEND_API_KEY ausente — e-mail não enviado.\nPara: %s\nAssunto: %s\n%s", to, subject, html)
        return

    try:
        response = requests.post(
            RESEND_URL,
            headers={"Authorization": f"Bearer {settings.resend_api_key}"},
            json={"from": settings.email_from, "to": [to], "subject": subject, "html": html},
            timeout=10,
        )
        response.raise_for_status()
    except requests.RequestException:
        # Não derruba a requisição: a resposta ao usuário é sempre a mesma
        # (não revela se o e-mail existe). O erro fica no log para investigar.
        logger.exception("Falha ao enviar e-mail para %s", to)
