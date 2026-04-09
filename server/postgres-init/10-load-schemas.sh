#!/bin/bash
# Postgres entrypoint runs .sh files alphabetically AFTER .sql files,
# so by here 00-create-databases.sql has already created all 6 dbs.
# Now load each per-service schema into its own database.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d socialdev_auth      -f /docker-entrypoint-initdb.d/01-auth.sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d socialdev_problem   -f /docker-entrypoint-initdb.d/02-problem.sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d socialdev_activity  -f /docker-entrypoint-initdb.d/03-activity.sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d socialdev_chat      -f /docker-entrypoint-initdb.d/04-chat.sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d socialdev_image     -f /docker-entrypoint-initdb.d/05-image.sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d socialdev_analytics -f /docker-entrypoint-initdb.d/06-analytics.sql

echo "✓ all socialdev schemas loaded"
