from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuração central da aplicação.

    DATABASE_URL aceita qualquer URL suportada pelo SQLAlchemy, então a troca
    de SQLite para PostgreSQL é só uma questão de ambiente (sem refatorar).
    """

    database_url: str = "sqlite:///./unihub.db"
    secret_key: str = "unihub-poc-dev-secret-key-trocar-em-producao"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24  # 24h: confortável para demo

    # Janela da regra anti-fraude: 1 check-in por aluno/academia a cada X horas
    checkin_antifraud_window_hours: int = 3

    # Origens liberadas no CORS: dev local + domínios publicados
    cors_origin_regex: str = (
        r"https?://(localhost|127\.0\.0\.1)(:\d+)?"
        r"|https://([a-z0-9-]+\.)?felipefurlan\.com\.br"
    )

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    def model_post_init(self, __context) -> None:
        # Railway/Heroku entregam "postgres://", mas o SQLAlchemy 2 exige "postgresql://"
        if self.database_url.startswith("postgres://"):
            self.database_url = self.database_url.replace("postgres://", "postgresql://", 1)


settings = Settings()
