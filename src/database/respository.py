from typing import List, Dict, Any
from src.database.connection import UnitOfWork
from src.utils.secure_logger import get_logger

logger = get_logger("Repository")

class Repository:
    """
    Capa de acceso a datos que encapsula la ejecución de Procedimientos Almacenados.
    Protege contra inyecciones SQL mediante el uso de consultas parametrizadas.
    """

    def upsert_clients_batch(self, clients_batch: List[Dict[str, Any]]) -> None:
        """Sincroniza un lote de clientes hacia la base de datos."""
        sql = "{CALL sp_AetherSync_UpsertClient (?, ?, ?, ?, ?, ?, ?, ?, ?)}"

        with UnitOfWork() as cursor:
            for client in clients_batch:
                params = (
                    client.get("id"),
                    client.get("client_code"),
                    client.get("business_name"),
                    client.get("commercial_name"),
                    client.get("identification_type"),
                    client.get("tax_identification"),
                    client.get("client_type"),
                    client.get("acronym"),
                    client.get("is_active", True)
                )
                cursor.execute(sql, params)

    def upsert_points_batch(self, points_batch: List[Dict[str, Any]]) -> None:
        """Sincroniza un lote de puntos (Points) hacia la base de datos."""
        sql = "{CALL sp_AetherSync_UpsertPoint (?, ?, ?, ?, ?)}"

        with UnitOfWork() as cursor:
            for point in points_batch:
                params = (
                    point.get("id"),
                    point.get("code"),
                    point.get("name"),
                    point.get("address"),
                    point.get("branch")
                )
                cursor.execute(sql, params)

            logger.info(f"✅ Lote de {len(points_batch)} puntos procesado y guardado.")

    def upsert_atms_batch(self, atms_batch: List[Dict[str, Any]]) -> None:
        """Sincroniza un lote de cajeros (ATMs) hacia la base de datos."""
        sql = "{CALL sp_AetherSync_UpsertAtm (?, ?, ?, ?, ?, ?, ?)}"

        with UnitOfWork() as cursor:
            for atm in atms_batch:
                params = (
                    atm.get("id"),
                    atm.get("internal_code"),
                    atm.get("client_code"),
                    atm.get("name"),
                    atm.get("brand"),
                    atm.get("model"),
                    atm.get("client_name")
                )
                cursor.execute(sql, params)

            logger.info(f"✅ Lote de {len(atms_batch)} ATMs procesado y guardado.")