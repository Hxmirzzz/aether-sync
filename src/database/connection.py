import pyodbc
from src.core.config import settings
from src.utils.secure_logger import get_logger

logger = get_logger("DatabaseConnection")

class UnitOfWork:
    """
    Gestor de contexto (Context Manager) para manejar conexiones y transacciones
    hacia SQL Server de forma segura y automatizada.
    """
    def __init__(self):
        self.conn = None
        self.cursor = None

    def __enter__(self):
        try:
            self.conn = pyodbc.connect(settings.DB_CONNECTION)
            self.cursor = self.conn.cursor()
            self.conn.autocommit = False

            return self.cursor
        except pyodbc.Error as e:
            logger.error(f"Fallo catastrófico al conectar a SQL Server: {e}")
            raise

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.conn:
            if exc_type is None:
                self.conn.commit()
            else:
                logger.error(f"Excepción detectada ({exc_type.__name__}). Ejecutando ROLLBACK.")
                self.conn.rollback()

            self.cursor.close()
            self.conn.close()