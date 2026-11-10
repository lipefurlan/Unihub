import pytest


@pytest.fixture(autouse=True)
def _skip_email_verification(monkeypatch):
    """Os testes antigos cadastram e já assinam; a confirmação por código tem
    testes próprios (test_email_verification.py), que religam a exigência."""
    # Import tardio: cada arquivo de teste define o ambiente (banco, chaves)
    # antes de o app carregar a configuração.
    from app.core.config import settings

    monkeypatch.setattr(settings, "email_verification_required", False)
