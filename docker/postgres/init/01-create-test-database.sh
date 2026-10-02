#!/bin/bash
set -e

# Cria o banco dedicado da suite de testes na primeira inicializacao do volume.
if [ -n "${TEST_DB_NAME}" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        CREATE DATABASE "${TEST_DB_NAME}";
EOSQL
fi
