#!/usr/bin/env bash
# Load the schema into a throwaway PostgreSQL and run the flows script.
#   ./run-schema.sh [schema_dir]
# Expects in schema_dir: bootstrap.sql (or 00-bootstrap.sql), numbered DDL files (01-*.sql …),
# and flows.sql (or tests/flows.sql; override with FLOWS=path). Uses a local image; it never pulls one.
# Env: PG_IMAGE, OWNER_ROLE, BOOTSTRAP_VARS (the psql -v pairs the bootstrap needs), FLOWS.
set -euo pipefail

DIR="${1:-.}"
IMAGE="${PG_IMAGE:-postgres:18-alpine}"
OWNER="${OWNER_ROLE:-app_owner}"
BOOTSTRAP_VARS=(${BOOTSTRAP_VARS:--v db=postgres -v owner_pw=x -v app_pw=x})

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image $IMAGE is not on this machine. Pull it yourself (docker pull $IMAGE) and run again." >&2
  exit 2
fi

cid=$(docker run -d --rm -e POSTGRES_PASSWORD=x "$IMAGE")
trap 'docker stop "$cid" >/dev/null' EXIT
until docker exec "$cid" pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done
sleep 1

psql_in() { docker exec -i "$cid" psql -U postgres -v ON_ERROR_STOP=1 -q "$@"; }

bootstrap="$DIR/00-bootstrap.sql"
[ -f "$bootstrap" ] || bootstrap="$DIR/bootstrap.sql"
echo "bootstrap: $bootstrap"
psql_in "${BOOTSTRAP_VARS[@]}" < "$bootstrap"

for f in "$DIR"/[0-9][0-9]-*.sql; do
  case "$(basename "$f")" in 00-*) continue ;; esac
  echo "load: $f"
  (echo "SET ROLE $OWNER;"; cat "$f") | psql_in
done

flows="${FLOWS:-}"
if [ -z "$flows" ]; then
  for candidate in "$DIR/flows.sql" "$DIR/tests/flows.sql"; do
    [ -f "$candidate" ] && flows="$candidate" && break
  done
fi
if [ -n "$flows" ]; then
  echo "flows: $flows"
  psql_in < "$flows"
fi
