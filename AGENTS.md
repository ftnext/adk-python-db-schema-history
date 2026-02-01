# Instructions for extracting ADK DB schemas

These steps are for a coding agent to capture table schema SQL for specific ADK versions.

## Assumptions
- Use `uvx --from google-adk==<version> adk ...` to run ADK.
- PostgreSQL runs via Docker image `postgres:18`.
- DB connection string: `postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres`.
- Output is stored under `v<version>/` directories (e.g., `v1.22.0/`), one `<table>.sql` file per table.

## Procedure
1. Start PostgreSQL 18:
   - Example: `docker run --name adk-pg -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres:18`
2. Start the ADK API server for the target version.
   - Note: ADK expects a PostgreSQL driver; use `psycopg` and `greenlet`.
   - Run from the `my_agent/` directory.
   - If port 8000 is already in use, stop the existing API server first.
   - Example:
     - `uvx --from google-adk==1.22.0 --with psycopg --with greenlet adk api_server --session_service_uri postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres`
3. Create a session by sending the required POST request to the API server.
   - Endpoint: `POST /apps/my_agent/users/test_user/sessions`
   - Example:
     - `curl -X POST http://127.0.0.1:8000/apps/my_agent/users/test_user/sessions -H 'Content-Type: application/json' -d '{}'`
   - If it fails immediately after startup, wait a few seconds and retry.
4. List the created tables in PostgreSQL.
5. For each table, export its CREATE TABLE SQL:
   - Use `docker exec -i adk-pg pg_dump --schema-only --table <schema>.<table> postgresql://postgres:mysecretpassword@localhost:5432/postgres`
6. Strip pg_dump boilerplate (e.g., `SET ...`, `--` headers, and `\restrict/\unrestrict`) so only CREATE/ALTER statements remain.
   - Example: `python scripts/strip_pg_dump.py v<version>`
7. Save each cleaned output as `v<version>/<table>.sql`.
8. Before switching ADK versions, stop the API server and reset the database to avoid cross-version contamination.
   - Example: `docker rm -f adk-pg`

## Notes
- Keep the list of tracked versions in README.md up to date.
