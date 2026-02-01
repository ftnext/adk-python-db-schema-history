# Instructions for extracting ADK DB schemas

These steps are for a coding agent to capture table schema SQL for specific ADK versions.

## Assumptions
- Use `uvx --from google-adk==<version> adk ...` to run ADK.
- PostgreSQL runs via Docker image `postgres:18`.
- Fixed DB connection string: `postgresql://postgres:mysecretpassword@localhost:5432/postgres`.
- Output is stored under `v<version>/` directories (e.g., `v1.22.0/`), one `<table>.sql` file per table.

## Procedure
1. Start PostgreSQL 18:
   - Example: `docker run --name adk-pg -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres:18`
2. Start the ADK API server for the target version:
   - Example: `uvx --from google-adk==1.22.0 adk api_server --session_service_uri postgresql://postgres:mysecretpassword@localhost:5432/postgres`
3. Create a session by sending the required POST request to the API server.
   - (Confirm the exact endpoint and payload after `adk create` is available.)
4. List the created tables in PostgreSQL.
5. For each table, export its CREATE TABLE SQL:
   - Use `pg_dump --schema-only --table <schema>.<table> postgresql://postgres:mysecretpassword@localhost:5432/postgres`
6. Save each output as `v<version>/<table>.sql`.

## Notes
- The session-creation endpoint and payload must be confirmed after `adk create` is set up.
- Keep the list of tracked versions in README.md up to date.
