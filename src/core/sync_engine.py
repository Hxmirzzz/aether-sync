from src.core.config import settings
from src.api.client import ApiClient
from src.database.respository import Repository
from src.utils.secure_logger import get_logger

logger = get_logger("SyncEngine")

class SyncEngine:
    """
    Motor principal de sincronización (ETL).
    Orquesta la extracción desde la API, el particionado en lotes (chunks)
    y la carga hacia la base de datos.
    """

    def __init__(self):
        self.api = ApiClient(settings.API_ROOT)
        self.repo = Repository()
        self.batch_size = settings.BATCH_SIZE

    def run_cycle(self) -> None:
        """
        Ejecuta un ciclo completo de sincronización.
        Maneja errores a nivel de entidad para que si falla una (ej. ATMs),
        las demás (Clients, Points) sigan procesándose.
        """
        logger.info("=== Iniciando nuevo ciclo de sincronización ===")
        try:
            endpoints = self.api.get_endpoints()

            if "clients" in endpoints:
                self._process_entity("Clientes", endpoints["clients"], self.repo.upsert_clients_batch)

            if "points" in endpoints:
                self._process_entity("Puntos", endpoints["points"], self.repo.upsert_points_batch)

            if "atms" in endpoints:
                self._process_entity("ATMs", endpoints["atms"], self.repo.upsert_atms_batch)

            logger.info("=== Ciclo de sincronización finalizado exitosamente ===")

        except Exception as e:
            logger.error(f"Fallo crítico en el ciclo de sincronización: {str(e)}")

    def _process_entity(self, entity_name: str, url: str, repository_method: callable) -> None:
        """
        Método genérico para descargar datos, dividirlos en lotes y enviarlos a la DB.
        """
        logger.info(f"Procesando entidad: {entity_name}")
        try:
            data = self.api.fetch_resource(url)
            if not data:
                logger.warning(f"No se obtuvieron datos para {entity_name}. Saltando...")
                return

            batches = self.api.generate_batches(data, self.batch_size)

            batch_count = 0
            for batch in batches:
                batch_count += 1
                logger.info(f"Enviando lote {batch_count} de {entity_name} ({len(batch)} registros)...")
                repository_method(batch)

        except Exception as e:
            logger.error(f"Error procesando la entidad {entity_name}: {str(e)}")