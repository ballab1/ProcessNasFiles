#!/bin/bash

psql -U postgres --no-align --tuples-only --quiet --echo-queries --echo-hidden --variable=ON_ERROR_STOP=1 \
    -f ./setupDatabase.sql
psql -U postgres --no-align --tuples-only --quiet --echo-queries --echo-hidden --variable=ON_ERROR_STOP=1 \
    -f ./processFileData.sql "--variable=jsonfile=$1"
psql -U postgres --no-align --tuples-only --quiet --echo-queries --echo-hidden --variable=ON_ERROR_STOP=1 \
    -f ./buildTranslation.sql \
    --output=data.txt
psql -U postgres --no-align --tuples-only --quiet --echo-queries --echo-hidden --variable=ON_ERROR_STOP=1 \
    "--command=copy (select row_to_json(nasdata) from nasinfo.nasdata) to stdout;" \
    --output=data.json
