import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from typing import Dict, Any, List, Generator
from src.core.config import settings
from src.utils.secure_logger import get_logger

logger = get_logger("ApiClient")

class ApiClient:
    """
    Cliente HTTP optimizado para consumir VCash Operations.
    Implementa Connection Pooling, reintentos automáticos y fragmentación de datos.
    """

    def __init__(self, api_root: str):
        self.api_root = api_root
        self.session = self._build_session()
        self._authenticate()

    def _build_session(self) -> requests.Session:
        """
        Configura una sesión HTTP resiliente.
        Sobrevive a caídas momentáneas de red o saturación del servidor de origen.
        """
        session = requests.Session()

        retry_strategy = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET", "POST", "OPTIONS"]
        )

        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("http://", adapter)
        session.mount("https://", adapter)

        session.headers.update({
            "Accept": "application/json",
            "Content-Type": "application/json"
        })

        return session

    def _authenticate(self) -> None:
        """Maneja el inicio de sesión y guarda el token en la sesión HTTP."""
        login_url = f"{self.api_root.rstrip('/')}/auth/login/"
        logger.info("Autenticando con la API de VCash Operations...")

        payload = {
            "login": settings.API_LOGIN,
            "password": settings.API_PASSWORD
        }

        try:
            response = self.session.post(login_url, data=payload, timeout=10)
            response.raise_for_status()

            data = response.json()
            token = data.get("token") or data.get("access")

            if token:
                self.session.headers.update({"Authorization": f"Bearer {token}"})
                logger.info("Autenticación exitosa. Token configurado.")
            else:
                logger.warning("El login fue 200 OK, pero no se encontró un token en la respuesta.")

        except requests.exceptions.RequestException as e:
            logger.error(f"Fallo crítico de autenticación: {str(e)}")
            raise

    def get_endpoints(self) -> Dict[str, str]:
        """
        Consulta la ruta raíz (API Root) para descubrir dinámicamente
        las URLs de los catálogos.
        """
        logger.info(f"Conectando al API Root: {self.api_root}")
        try:
            response = self.session.get(self.api_root, timeout=10)
            response.raise_for_status()
            return response.json()

        except requests.exceptions.RequestException as e:
            logger.error(f"Fallo crítico al obtener endpoints raíz: {str(e)}")
            raise

    def fetch_resource(self, url: str) -> List[Dict[str, Any]]:
        """
        Obtiene los datos completos de un recurso específico (Clientes, Puntos, ATMs).
        """
        logger.info(f"Extrayendo catálogo desde: {url}")
        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()

            data = response.json()
            logger.info(f"Extracción exitosa: {len(data)} registros encontrados.")
            return data

        except requests.exceptions.RequestException as e:
            logger.error(f"Error al consumir el recurso {url}: {str(e)}")
            return []

    def generate_batches(self, data: List[Any], batch_size: int) -> Generator[List[Any], None, None]:
        """
        Generador (yield) que divide listas masivas en fragmentos más pequeños (Chunks).
        Previene el consumo excesivo de RAM y evita colapsar la Base de Datos.
        """
        for i in range(0, len(data), batch_size):
            yield data[i:i + batch_size]