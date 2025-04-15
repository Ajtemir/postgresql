#!/bin/bash
set -e

echo "🔧 Updating pg_hba.conf for remote access and replication..."

# Ensure data directory exists before writing to pg_hba.conf
PGDATA=${PGDATA:-/var/lib/postgresql/data}
echo "Using PGDATA at $PGDATA"

# Wait for Postgres to init files before touching pg_hba.conf
#until [ -f "$PGDATA/pg_hba.conf" ]; do
#  echo "⏳ Waiting for pg_hba.conf to appear..."
#  sleep 1
#done

# Append replication rules
echo "host    all             all             0.0.0.0/0               md5" >> "$PGDATA/pg_hba.conf"
echo "host    replication     replicator      0.0.0.0/0               trust" >> "$PGDATA/pg_hba.conf"

# Create replication role
echo "⏳ Waiting for PostgreSQL to be ready to accept connections..."
until pg_isready -U "$POSTGRES_USER" -h "localhost"; do
  sleep 1
done

echo "🛠️  Creating replication role 'replicator'..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'replicator') THEN
      CREATE ROLE replicator WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'replicatorpass';
    END IF;
  END
  \$\$;
EOSQL

echo "✅ primary.sh finished!"
