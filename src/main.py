import time
import sys
from src.core.config import settings
from src.core.sync_engine import SyncEngine
from src.utils.secure_logger import get_logger

logger = get_logger("AetherSyncDaemon")

def main():
    """
    Punto de entrada de AetherSync.
    Mantiene el ciclo de vida del agente activo como un servicio (Daemon).
    """
    logger.info("Iniciando AetherSync Daemon...")
    logger.info(f"Intervalo de sincronización: {settings.SYNC_INTERVAL_SECONDS} segundos.")
    logger.info(f"Tamaño de lote (Chunk size): {settings.BATCH_SIZE} registros.")
    engine = SyncEngine()

    while True:
        try:
            engine.run_cycle()
        except KeyboardInterrupt:
            logger.info("Señal de apagado recibida. Deteniendo AetherSync de forma segura...")
            sys.exit(0)
        except Exception as e:
            logger.critical(f"Error fatal no controlado (Uncaught Exception): {str(e)}", exc_info=True)
        finally:
            logger.info(f"Durmiendo {settings.SYNC_INTERVAL_SECONDS} segundos hasta el próximo ciclo...")
            time.sleep(settings.SYNC_INTERVAL_SECONDS)

if __name__ == "__main__":
    main()