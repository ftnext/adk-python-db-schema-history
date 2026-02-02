# Instructions for extracting ADK DB schemas

These steps are for a coding agent to capture table schema SQL for specific ADK versions.

## Assumptions
- Use `uvx --from google-adk==<version> adk ...` to run ADK.
- PostgreSQL runs via Docker image `postgres:18`.
- MySQL runs via Docker image `mysql:9`.
- DB connection strings:
  - PostgreSQL: `postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres`.
  - MySQL (<= 1.17.0): `mysql+pymysql://root:mysecretpassword@127.0.0.1:3306/adk`.
  - MySQL (>= 1.19.0): `mysql+aiomysql://root:mysecretpassword@127.0.0.1:3306/adk`.
- Output is stored under `schemas/v<version>/` as:
  - `postgresql.sql` exported by `psqldef`
  - `mysql.sql` exported by `mysqldef`
## MySQL gotchas
- Use a dedicated database (e.g. `adk`). Do not use `mysql` system DB; it can reject access (e.g. `mysql.events`).
- Allow root connections from non-localhost by setting `MYSQL_ROOT_HOST=%` on container startup; otherwise `root@127.0.0.1` may be denied.
- For v1.19.0+ use `aiomysql` and `greenlet` (async driver requirement).
- When waiting for MySQL, prefer a real query (`mysql -e "SELECT 1"`) instead of `mysqladmin ping` to ensure authentication is ready.

## Procedure
1. Start the database container.
   - PostgreSQL 18:
     - `docker run --name adk-pg -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres:18`
   - MySQL 9:
     - `docker run --name adk-mysql -e MYSQL_ROOT_PASSWORD=mysecretpassword -e MYSQL_ROOT_HOST=% -p 3306:3306 -d mysql:9`
2. (MySQL only) Create the target database.
   - Example:
     - `docker exec adk-mysql mysql -uroot -pmysecretpassword -e "CREATE DATABASE IF NOT EXISTS adk"`
3. Start the ADK API server for the target version.
   - Run from the `my_agent/` directory.
   - If port 8000 is already in use, stop the existing API server first.
   - PostgreSQL example:
     - `uvx --from google-adk==1.22.0 --with psycopg --with greenlet adk api_server --session_service_uri postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres`
   - MySQL example:
     - `uvx --from google-adk==1.17.0 --with pymysql adk api_server --session_service_uri mysql+pymysql://root:mysecretpassword@127.0.0.1:3306/adk`
     - `uvx --from google-adk==1.22.0 --with aiomysql --with greenlet adk api_server --session_service_uri mysql+aiomysql://root:mysecretpassword@127.0.0.1:3306/adk`
4. Create a session by sending the required POST request to the API server.
   - Endpoint: `POST /apps/my_agent/users/test_user/sessions`
   - Example:
     - `curl -X POST http://127.0.0.1:8000/apps/my_agent/users/test_user/sessions -H 'Content-Type: application/json' -d '{}'`
   - If it fails immediately after startup, wait a few seconds and retry.
5. Export the full schema with `sqldef` and save it under the version directory:
   - PostgreSQL example:
     - `psqldef -h localhost -p 5432 -U postgres -W mysecretpassword postgres --export > schemas/v<version>/postgresql.sql`
   - MySQL example:
     - `MYSQL_PWD=mysecretpassword mysqldef -h 127.0.0.1 -P 3306 -u root adk --export > schemas/v<version>/mysql.sql`
6. Before switching ADK versions, stop the API server and reset the database to avoid cross-version contamination.
   - Examples:
     - `docker rm -f adk-pg`
     - `docker rm -f adk-mysql`
   - If port 8000 is still in use:
     - `lsof -ti :8000` then `kill <pid>`

## Scripted workflow (recommended)
- Use `scripts/export_schema.sh <version> [postgresql|mysql|all]` to run the steps above.
- Examples:
  - `scripts/export_schema.sh 1.22.0 postgresql`
  - `scripts/export_schema.sh 1.22.0 mysql`
  - `scripts/export_schema.sh 1.22.0 all`
- Logs are saved to `/tmp/adk_api_<version>_<db>.log` when troubleshooting startup issues.

## Notes
- Keep the list of tracked versions in README.md up to date.
