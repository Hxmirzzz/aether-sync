# 🔄 AetherSync - ETL Daemon for VCash Operations

![Python](https://img.shields.io/badge/Python-3.11-blue?style=flat-square&logo=python)
![SQL Server](https://img.shields.io/badge/SQL_Server-2022-red?style=flat-square&logo=microsoft-sql-server)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat-square&logo=docker)
![Architecture](https://img.shields.io/badge/Architecture-ETL_Worker-success?style=flat-square)

**AetherSync** es un agente (daemon) de extracción, transformación y carga (ETL) desarrollado en Python. Actúa como el puente de sincronización continua entre el catálogo maestro de **VCash Operations** (API REST) y la base de datos local de **VCashApp** (.NET Core MVC).

Diseñado para ejecutarse como un servicio en segundo plano ininterrumpido, AetherSync garantiza que la información operativa crítica (Clientes, Puntos, ATMs) esté siempre actualizada de manera transaccional, segura y con alta tolerancia a fallos de red.

## 🏗️ Arquitectura y Decisiones de Diseño (ADRs)

Para garantizar un rendimiento de grado empresarial sin comprometer la estabilidad del sistema principal, se implementaron los siguientes patrones:

1. **Separación de Responsabilidades (API vs BD):** El motor no acopla la lectura HTTP con la escritura en SQL. Usa un pipeline donde los datos fluyen a través de un orquestador central (`SyncEngine`).
2. **Chunking & Memory Safety:** Se utilizan generadores (`yield`) para paginar respuestas masivas de la API en lotes de 1,000 registros, protegiendo la memoria RAM del contenedor.
3. **Unit of Work & Idempotencia:** Las conexiones a SQL Server utilizan gestores de contexto (`__enter__`/`__exit__`) para garantizar transacciones ACID. La deduplicación se delega al motor de base de datos mediante procedimientos almacenados con la instrucción `MERGE WITH (HOLDLOCK)`.
4. **Resiliencia de Red (Exponential Backoff):** El cliente HTTP implementa estrategias de reintento automático (`urllib3 Retry`) para sobrevivir a caídas momentáneas o saturación del servidor origen (HTTP 429, 502, 504).
5. **Fail-Fast Configuration:** Se utiliza `pydantic-settings` para validar estrictamente la presencia y el tipo de las variables de entorno en el milisegundo cero, impidiendo arranques en falso.

## 🛡️ Prácticas de Seguridad Aplicadas

* **Zero-Privilege Container:** El `Dockerfile` está configurado para ejecutar el proceso bajo un usuario restringido (`aetheruser`), mitigando riesgos de escalada de privilegios.
* **Data Masking en Logs:** Implementación de un formateador personalizado (`SecureFormatter`) que intercepta expresiones regulares para enmascarar información sensible (como números de identificación fiscal) antes de emitir la salida a la consola.
* **Prevención de Inyección SQL:** Todas las escrituras hacia la base de datos utilizan parámetros parametrizados de la librería `pyodbc`, neutralizando ataques de inyección.

## 🚀 Despliegue Rápido (Docker)

El proyecto incluye configuración lista para orquestación mediante `docker-compose`.

1. Clona el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/AetherSync.git
   cd AetherSync
   ```
2. Configura las variables de entorno a partir de la plantilla segura:
   ```bash
   cp .env.example .env
   # Edita el archivo .env con las credenciales de SQL Server y la API
   ```
3. Levanta el servicio en segundo plano:
   ```bash
   docker-compose up -d --build
   ```
4. Monitorea el agente de sincronización:
   ```bash
   docker-compose logs -f
   ```

## 🧪 Pruebas Unitarias

El proyecto incluye una suite de pruebas que utiliza `unittest.mock` para validar la lógica de negocio y la autenticación JWT sin depender de conexiones activas a internet o bases de datos reales.

```bash
# Ejecutar suite de pruebas
pytest -v
```