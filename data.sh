#!/bin/bash

function etl()
{
    [ "${IS_VERBOSE:-}" ] && VERBOSE=( '--no-align' '--tuples-only' '--quiet' '--echo-queries' '--echo-hidden' )

    "$PSQL" --host="$DBMS_host" \
            --port="$DBMS_port" \
            --dbname="$DBMS_dbname" \
            --username="$DBMS_username" \
            --variable=ON_ERROR_STOP=1 \
            "${VERBOSE[@]}" "$@"

}

DBMS_host=10.3.1.16
DBMS_port=5432
DBMS_dbname=bobb
DBMS_username=bobb
PSQL=/usr/local/bin/psql

etl -f ./setupDatabase.sql
etl -f ./processFileData.sql "--variable=jsonfile=$1"
etl -f ./buildTranslation.sql --output=data.txt
etl "--command=copy (select row_to_json(nasdata) from nasinfo.nasdata) to stdout;" --output=data.json
