# Instructions for extracting ADK DB schemas

These steps are for a coding agent to capture table schema SQL for specific ADK versions.

## Assumptions
- Use `uvx --from google-adk==<version> adk ...` to run ADK.
- PostgreSQL runs via Docker image `postgres:18`.
- DB connection string: `postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres`.
- Output is stored under `v<version>/` directories (e.g., `v1.22.0/`) as `schema.sql` exported by `psqldef`.

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
4. Export the full schema with `psqldef` and save it under the version directory:
   - Example: `psqldef -h localhost -p 5432 -U postgres -W mysecretpassword postgres --export > v<version>/schema.sql`
5. Before switching ADK versions, stop the API server and reset the database to avoid cross-version contamination.
   - Example: `docker rm -f adk-pg`

## Scripted workflow (recommended)
- Use `scripts/export_schema.sh <version>` to run the steps above in one command.
- Example: `scripts/export_schema.sh 1.22.0`
- Logs are saved to `/tmp/adk_api_<version>.log` when troubleshooting startup issues.

## Notes
- Keep the list of tracked versions in README.md up to date.
