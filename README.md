This repository visualizes the historical evolution of the Python ADK database table schemas, with an emphasis on changes not explicitly called out in release notes.

It is intended to help teams track when and how tables changed across releases. 
The current focus includes the following versions, and this list will be updated as new findings emerge.

- [1.14.0](https://github.com/google/adk-python/releases/tag/v1.14.0)
    - >NOTE: This requires DB migration, run `ALTER TABLE events ADD COLUMN custom_metadata JSON;` to migrate existing database tables.
- [1.17.0](https://github.com/google/adk-python/releases/tag/v1.17.0)
- [1.19.0](https://github.com/google/adk-python/releases/tag/v1.19.0)
    - >Add transcription fields to session events
- [1.22.0](https://github.com/google/adk-python/releases/tag/v1.22.0)
    - >Introduce new JSON-based database schema for DatabaseSessionService, which will be used for newly-created databases. A migration command and script are provided.

Each snapshot captures the table definitions for a specific version so differences can be compared over time.
Schemas are stored under `schemas/v<version>/` as `postgresql.sql` and `mysql.sql`.
By keeping an explicit timeline of schema shifts, the repository reduces surprises during upgrades and investigations.

## Example

With `psqldef`

```bash
docker run --name adk-pg -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres:18 
```

```bash
uvx --from google-adk==1.14.0 --with psycopg --with greenlet adk api_server --session_service_uri postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres
```

Create session to initialize the database:

```bash
curl -X POST http://127.0.0.1:8000/apps/my_agent/users/test_user/sessions -H 'Content-Type: application/json' -d '{}'
```

```bash
psqldef -h localhost -p 5432 -U postgres -W mysecretpassword --dry-run postgres < schemas/v1.17.0/postgresql.sql
```

With `mysqldef`

```bash
docker run --name adk-mysql -e MYSQL_ROOT_PASSWORD=mysecretpassword -p 3306:3306 -d mysql:9
```

```bash
uvx --from google-adk==1.14.0 --with pymysql adk api_server --session_service_uri mysql+pymysql://root:mysecretpassword@127.0.0.1:3306/adk
```

Create session to initialize the database:

```bash
curl -X POST http://127.0.0.1:8000/apps/my_agent/users/test_user/sessions -H 'Content-Type: application/json' -d '{}'
```

```bash
MYSQL_PWD=mysecretpassword mysqldef -h 127.0.0.1 -P 3306 -u root adk --dry-run < schemas/v1.17.0/mysql.sql
```

v1.14.0 -> v1.17.0

```sql
-- dry run --
ALTER TABLE "public"."events" ADD COLUMN "usage_metadata" jsonb;
ALTER TABLE "public"."events" ADD COLUMN "citation_metadata" jsonb;
```
