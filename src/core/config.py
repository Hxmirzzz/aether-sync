from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """
    Validación estricta de variables de entorno.
    Si una variable sin valor por defecto falta en el .env, la app se detiene (Fail Fast).
    """
    API_ROOT: str
    API_LOGIN: str
    API_PASSWORD: str
    DB_CONNECTION_STRING: str
    SYNC_INTERVAL_SECONDS: int = 300
    BATCH_SIZE: int = 1000

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = Settings()