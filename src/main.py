import argparse
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

    parser = argparse.ArgumentParser(description="AetherSync ETL Daemon para VCash Operations")
    parser.add_argument("-all", action="store_true", help="Ejecuta todas las entidades en ciclo continuo (Modo Demonio)")
    parser.add_argument("-client", action="store_true", help="Sincroniza SOLO Clientes (Ejecución única)")
    parser.add_argument("-point", action="store_true", help="Sincroniza SOLO Puntos (Ejecución única)")
    parser.add_argument("-atm", action="store_true", help="Sincroniza SOLO ATMs (Ejecución única)")

    args = parser.parse_args()

    if not any([args.all, args.client, args.point, args.atm]):
        args.all = True

    logger.info("Iniciando AetherSync Daemon...")
    engine = SyncEngine()

    if args.client or args.point or args.atm:
        logger.info("Modo de Prueba Individual")

        if args.client:
            engine.sync_clients()
        if args.point:
            engine.sync_points()
        if args.atm:
            engine.sync_atms()

        logger.info("=== Prueba individual finalizada. Saliendo... ===")
        sys.exit(0)

    if args.all:
        logger.info(f"=== MODO DEMONIO ACTIVADO (Intervalo: {settings.SYNC_INTERVAL_SECONDS}s) ===")
        try:
            while True:
                logger.info("Iniciando AetherSync Daemon...")

                engine.sync_clients()
                engine.sync_points()
                engine.sync_atms()

                logger.info("Ciclo global finalizado exitosamente.")
                logger.info(f"Durmiendo {settings.SYNC_INTERVAL_SECONDS} segundos...")
                time.sleep(settings.SYNC_INTERVAL_SECONDS)

        except KeyboardInterrupt:
            logger.info("Servicio detenido manualmente por el usuario (Ctrl+C).")
            sys.exit(0)

if __name__ == "__main__":
    main()