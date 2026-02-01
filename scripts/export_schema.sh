#!/usr/bin/env bash
set -euo pipefail

version="${1:-}"
if [ -z "$version" ]; then
  echo "Usage: $0 <version>" >&2
  exit 2
fi

log="/tmp/adk_api_${version}.log"
pidfile="/tmp/adk_api_${version}.pid"

cleanup() {
  if [ -f "$pidfile" ]; then
    kill "$(cat "$pidfile")" >/dev/null 2>&1 || true
  fi
  docker rm -f adk-pg >/dev/null 2>&1 || true
}
trap cleanup EXIT

if lsof -ti :8000 >/tmp/adk_port.pid 2>/dev/null; then
  echo "Port 8000 is already in use. Stop the existing API server first." >&2
  exit 1
fi

docker run --name adk-pg -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres:18 >/dev/null

(cd my_agent && nohup uvx --from google-adk=="${version}" --with psycopg --with greenlet adk api_server --session_service_uri postgresql+psycopg://postgres:mysecretpassword@localhost:5432/postgres > "$log" 2>&1 & echo $! > "$pidfile")

ok=0
for _ in {1..20}; do
  if curl -sf -X POST http://127.0.0.1:8000/apps/my_agent/users/test_user/sessions -H 'Content-Type: application/json' -d '{}' >/dev/null; then
    ok=1
    break
  fi
  sleep 2
done

if [ "$ok" -ne 1 ]; then
  echo "API server did not start for v${version}. See ${log}" >&2
  exit 1
fi

mkdir -p "v${version}"
psqldef -h localhost -p 5432 -U postgres -W mysecretpassword postgres --export > "v${version}/schema.sql"
