#!/bin/bash
set -e

# Clean up any old data
rm -rf /var/lib/postgresql/data/*

# Wait for primary to be available
until pg_isready -h primary -U postgres; do
  echo "Waiting for primary..."
  sleep 2
done

# Perform base backup
PGPASSWORD=replicatorpass pg_basebackup -h primary -D /var/lib/postgresql/data -U replicator -Fp -Xs -P -R

# Enable hot standby
echo "hot_standby = on" >> /var/lib/postgresql/data/postgresql.conf
