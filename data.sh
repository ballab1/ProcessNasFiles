#!/bin/bash

export DBMS_host=localhost
export DBMS_port=5432
export DBMS_dbname=nasfiles
export DBMS_username="${POSTGRES_USER:-postgres}"
export PGPASSWORD="${POSTGRES_PASSWORD:-admin123}"
export PSQL='/usr/local/bin/psql'
export IS_VERBOSE='true'

source ./data.bashlib


rawdata="${1:-${WORKSPACE}/files.3.json}"
jsonfile="${2:-${WORKSPACE}/data.json}"
op_index="${3:-${WORKSPACE}/nasfiles_index.json}"

set -eu

[ "$(which "$PSQL")" ] && data::run_etl "$rawdata" "$jsonfile"
[ "$(which "jq")" ]    && data::run_postprocess "$jsonfile" "$op_index"
exit 0
