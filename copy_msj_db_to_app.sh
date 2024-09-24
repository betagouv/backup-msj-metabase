#!/bin/bash

dbclient-fetcher psql
pg_dump --clean --if-exists --format c --dbname $SCALINGO_POSTGRESQL_URL --no-owner --no-privileges --no-comments --exclude-schema 'information_schema' --exclude-schema '^pg_*' --exclude-table="ahoy_events" --exclude-table="ahoy_visits" --exclude-table="versions" --file dump.pgsql

# Drop all tables in the target database
psql $METABASE_POSTGRESQL_URL -c "
DO \$\$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE 'Starting to drop tables';
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        BEGIN
            RAISE NOTICE 'Dropping table: %', r.tablename;
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Error dropping table: %', r.tablename;
        END;
    END LOOP;
    RAISE NOTICE 'Finished dropping tables';
END
\$\$;"

pg_restore --no-owner --no-privileges --no-comments --dbname $METABASE_POSTGRESQL_URL dump.pgsql