#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"
db="${2:-postgresql}"
if [ -z "$version" ]; then
  echo "Usage: $0 <version> [postgresql|mysql|all]" >&2
  exit 2
fi

current_pidfile=""
current_container=""

version_ge() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

cleanup() {
  if [ -n "$current_pidfile" ] && [ -f "$current_pidfile" ]; then
    kill "$(cat "$current_pidfile")" >/dev/null 2>&1 || true
  fi
  if [ -n "$current_container" ]; then
    docker rm -f "$current_container" >/dev/null 2>&1 || true
  fi
}

run_one() {
  local db_kind="$1"
  local log="/tmp/adk_api_${version}_${db_kind}.log"
  local pidfile="/tmp/adk_api_${version}_${db_kind}.pid"
  local container=""
  local dsn=""
  local image=""
  local port=""
  local driver_flags=()
  local export_cmd=()
  local output=""

  case "$db_kind" in
    postgresql|postgres)
      container="adk-pg"
      image="postgres:18"
      port="5432"
      dsn="postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres"
      driver_flags=(--with psycopg --with greenlet)
      output="schemas/v${version}/postgresql.sql"
      export_cmd=(psqldef -h localhost -p 5432 -U postgres -W mysecretpassword postgres --export)
      ;;
    mysql)
      container="adk-mysql"
      image="mysql:9"
      port="3306"
      mysql_db="adk"
      mysql_driver="pymysql"
      if version_ge "$version" "1.19.0"; then
        mysql_driver="aiomysql"
      fi
      dsn="mysql+${mysql_driver}://root:mysecretpassword@127.0.0.1:3306/${mysql_db}"
      if [ "$mysql_driver" = "aiomysql" ]; then
        driver_flags=(--with "$mysql_driver" --with greenlet)
      else
        driver_flags=(--with "$mysql_driver")
      fi
      output="schemas/v${version}/mysql.sql"
      export_cmd=(mysqldef -h 127.0.0.1 -P 3306 -u root "${mysql_db}" --export)
      ;;
    *)
      echo "Unknown database: ${db_kind}" >&2
      exit 2
      ;;
  esac

  current_pidfile="$pidfile"
  current_container="$container"
  trap cleanup EXIT

  if lsof -ti :8000 >/tmp/adk_port.pid 2>/dev/null; then
    echo "Port 8000 is already in use. Stop the existing API server first." >&2
    exit 1
  fi

  if [ "$db_kind" = "postgresql" ] || [ "$db_kind" = "postgres" ]; then
    docker run --name "$container" -e POSTGRES_PASSWORD=mysecretpassword -p "${port}:${port}" -d "$image" >/dev/null
  else
    docker run --name "$container" -e MYSQL_ROOT_PASSWORD=mysecretpassword -e MYSQL_ROOT_HOST=% -p "${port}:${port}" -d "$image" >/dev/null
    ready=0
    for _ in {1..20}; do
      if docker exec "$container" mysql -uroot -pmysecretpassword -e "SELECT 1" >/dev/null 2>&1; then
        ready=1
        break
      fi
      sleep 2
    done
    if [ "$ready" -ne 1 ]; then
      echo "MySQL did not become ready for v${version}." >&2
      exit 1
    fi
    docker exec "$container" mysql -uroot -pmysecretpassword -e "CREATE DATABASE IF NOT EXISTS ${mysql_db}" >/dev/null
  fi

  (cd my_agent && nohup uvx --from google-adk=="${version}" "${driver_flags[@]}" adk api_server --session_service_uri "$dsn" > "$log" 2>&1 & echo $! > "$pidfile")

  ok=0
  for _ in {1..20}; do
    if curl -sf -X POST http://127.0.0.1:8000/apps/my_agent/users/test_user/sessions -H 'Content-Type: application/json' -d '{}' >/dev/null; then
      ok=1
      break
    fi
    sleep 2
  done

  if [ "$ok" -ne 1 ]; then
    echo "API server did not start for v${version} (${db_kind}). See ${log}" >&2
    exit 1
  fi

  mkdir -p "schemas/v${version}"
  if [ "$db_kind" = "mysql" ]; then
    MYSQL_PWD=mysecretpassword "${export_cmd[@]}" > "$output"
  else
    "${export_cmd[@]}" > "$output"
  fi

  cleanup
  trap - EXIT
}

case "$db" in
  all)
    run_one postgresql
    run_one mysql
    ;;
  postgres)
    run_one postgresql
    ;;
  postgresql|mysql)
    run_one "$db"
    ;;
  *)
    echo "Usage: $0 <version> [postgresql|mysql|all]" >&2
    exit 2
    ;;
esac
