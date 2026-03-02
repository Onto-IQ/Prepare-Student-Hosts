#!/bin/sh
# Create n8n_1 .. n8n_25 for multi-instance n8n (N8N_COUNT=25).
# Runs once when Postgres data volume is first initialized.
set -e
for i in $(seq 1 25); do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname=postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'n8n_$i'" | grep -q 1 || \
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname=postgres -c "CREATE DATABASE n8n_$i;"
done
