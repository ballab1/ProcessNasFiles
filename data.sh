#!/bin/bash -x

function etl()
{
    [ "${IS_VERBOSE:-}" ] && VERBOSE=( '--no-align' '--tuples-only' '--quiet' '--echo-queries' '--echo-hidden' )

    $PSQL --host="$DBMS_host" \
          --port="$DBMS_port" \
          --dbname="$DBMS_dbname" \
          --username="$DBMS_username" \
          --variable=ON_ERROR_STOP=1 \
          ${VERBOSE[@]} $@

}

DBMS_host=10.3.1.16
DBMS_port=5432
DBMS_dbname=bobb
DBMS_username=bobb
PSQL='docker exec postgresql /usr/local/bin/psql'
IS_VERBOSE='true'

etl -f "${WORKSPACE}/setupDatabase.sql"
etl -f "${WORKSPACE}/processFileData.sql" "--variable=jsonfile=$1"
etl -f "${WORKSPACE}/buildTranslation.sql" "--output=${WORKSPACE}/data.txt"
etl "--command=copy (select row_to_json(nasdata) from nasinfo.nasdata) to stdout;" "--output=${WORKSPACE}/data.json"
