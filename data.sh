#!/bin/bash

#----------------------------------------------------------------------------------
function etl()
{
    [ "${IS_VERBOSE:-}" ] && VERBOSE=( '--no-align' '--tuples-only' '--quiet' '--echo-queries' '--echo-hidden' )

    $PSQL --host="$DBMS_host" \
          --port="$DBMS_port" \
          --dbname="$DBMS_dbname" \
          --username="$DBMS_username" \
          --variable=ON_ERROR_STOP=1 \
          ${VERBOSE[@]} "$@"

}

#----------------------------------------------------------------------------------
function etl_createDb()
{
    [ "${IS_VERBOSE:-}" ] && VERBOSE=( '--no-align' '--tuples-only' '--quiet' '--echo-queries' '--echo-hidden' )

    $PSQL --host="$DBMS_host" \
          --port="$DBMS_port" \
          --username="$DBMS_username" \
          --variable=ON_ERROR_STOP=1 \
          ${VERBOSE[@]} \
          --command="create database $DBMS_dbname;"

}

#----------------------------------------------------------------------------------
function etl_ip()
{
    local -r table="${1:?}"
    shift

    [ "${IS_VERBOSE:-}" ] && VERBOSE=( '--no-align' '--tuples-only' '--quiet' '--echo-queries' '--echo-hidden' )

    $@ | $PSQL --host="$DBMS_host" \
               --port="$DBMS_port" \
               --dbname="$DBMS_dbname" \
               --username="$DBMS_username" \
               --variable=ON_ERROR_STOP=1 \
               --command="truncate ${table}; copy ${table} from stdin;" \
               ${VERBOSE[@]}
}

#----------------------------------------------------------------------------------
function files_to_move()
{
    local -r jsonfile="${1:?}"
    local -r files_to_move="${2:?}"

    sed -r -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
           -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
           -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
           -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
           -e 's|(wiki/dok)\\(u[0-9a-fA-F]{4})|\1\2|g' \
           -e 's|(Q)\\(uebec)|\1\2|ig' \
           -e 's|(/iss)\\(ue)|\1\2|ig' \
           -e 's|(/incl)\\(ude)|\1\2|ig' \
           -e 's|(clo)\\(udbees)|\1\2|ig' \
           -e 's|(st)\\(uffed)|\1\2|ig' \
           -e 's|(st)\\(ubbed)|\1\2|ig' \
           -e 's|(Sa)\\(udade)|\1\2|ig' \
           -e 's|(A)\\(ubade)|\1\2|ig' \
           -e 's|(Val)\\(ueBean)|\1\2|ig' \
           -e 's|(Val)\\(ueCache)|\1\2|ig' \
           -e 's|(H)\\(ubBacked)|\1\2|ig' \
           -e 's|(St)\\(ubDaem)|\1\2|ig' \
           -e 's|(Cl)\\(ubbed)|\1\2|ig' \
           -e 's|(Pers)\\(uaded)|\1\2|ig' \
           -e 's|(Iss)\\(ueBean)|\1\2|ig' \
           -e 's|(Iss)\\(ueCache)|\1\2|ig' \
           -e 's|(r)\\(ubbed)|\1\2|ig' \
           -e 's|(Bl)\\(uebeard)|\1\2|ig' \
           -e 's|(/)\\(ubcd535\.iso)|\1\2|ig' \
           -e 's|(-dell-)\\(u2414h)|\1\2|ig' \
           -e 's|(dok)\\(u[0-9a-f]{4})|\1\2|ig' "${jsonfile}" \
        | jq -sr '.[]|select(.rownum != 1 and .type == "regular file" and (.file|startswith("/mnt/WdMyCloud/Seagate_Expansion_Drive/"))).file|ltrimstr("/mnt/WdMyCloud/")' > "${files_to_move}"
    dos2unix "$files_to_move"
}

#----------------------------------------------------------------------------------
function nasfiles_index()
{
    local -r jsonfile="${1:?}"
    local -r nasfiles_index="${2:?}"

    sed -r -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
           -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
           -e 's|([^\\])(u[0-9a-f]{4})|\1\\\2|g' \
           -e 's|([^\\])(u[0-9A-F]{4})|\1\\\2|g' \
           -e 's|(wiki/dok)\\(u[0-9a-fA-F]{4})|\1\2|g' \
           -e 's|(Q)\\(uebec)|\1\2|ig' \
           -e 's|(/iss)\\(ue)|\1\2|ig' \
           -e 's|(/incl)\\(ude)|\1\2|ig' \
           -e 's|(clo)\\(udbees)|\1\2|ig' \
           -e 's|(st)\\(uffed)|\1\2|ig' \
           -e 's|(st)\\(ubbed)|\1\2|ig' \
           -e 's|(Sa)\\(udade)|\1\2|ig' \
           -e 's|(A)\\(ubade)|\1\2|ig' \
           -e 's|(Val)\\(ueBean)|\1\2|ig' \
           -e 's|(Val)\\(ueCache)|\1\2|ig' \
           -e 's|(H)\\(ubBacked)|\1\2|ig' \
           -e 's|(St)\\(ubDaem)|\1\2|ig' \
           -e 's|(Cl)\\(ubbed)|\1\2|ig' \
           -e 's|(Pers)\\(uaded)|\1\2|ig' \
           -e 's|(Iss)\\(ueBean)|\1\2|ig' \
           -e 's|(Iss)\\(ueCache)|\1\2|ig' \
           -e 's|(r)\\(ubbed)|\1\2|ig' \
           -e 's|(Bl)\\(uebeard)|\1\2|ig' \
           -e 's|(/)\\(ubcd535\.iso)|\1\2|ig' \
           -e 's|(-dell-)\\(u2414h)|\1\2|ig' \
           -e 's|(dok)\\(u[0-9a-f]{4})|\1\2|ig' "${jsonfile}" \
        | jq -sc '[.[]|select(.rownum == 1 and .type == "regular file")|{sha256, file}]|unique|sort[]' > "${nasfiles_index}"
}

#----------------------------------------------------------------------------------

DBMS_host=localhost
DBMS_port=5432
DBMS_dbname=nasfiles
DBMS_username="${POSTGRES_USER:-postgres}"
export PGPASSWORD="${POSTGRES_PASSWORD:-admin123}"
PSQL='/usr/local/bin/psql'
IS_VERBOSE='true'
jsonfile="${WORKSPACE}/data.json"

set -eu

etl_createDb
etl -f "${WORKSPACE}/setupDatabase.sql"
etl_ip 'nasinfo.rawdata' "cat $1"
etl -f "${WORKSPACE}/processFileData.sql"
etl -f "${WORKSPACE}/buildTranslation.sql" "--output=${WORKSPACE}/data.txt"
etl '--command=copy (select row_to_json(nasdata) from nasinfo.nasdata) to stdout;' "--output=$jsonfile"

apk add dos2unix jq sed
files_to_move "$jsonfile" "${WORKSPACE}/files_to_move.txt"
nasfiles_index "${WORKSPACE}/files_to_move.txt" "${WORKSPACE}/nasfiles_index.json"

