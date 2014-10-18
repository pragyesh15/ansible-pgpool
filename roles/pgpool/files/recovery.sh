#!/bin/bash -x

PGDATA=$1
REMOTE_HOST=$2
REMOTE_PGDATA=$3

PORT=5432
RECTEMPLATE="/usr/local/etc/pg_recovery_template.conf"
TMPREC=$(mktemp)

logger -t pgpool_recovery "Starting recovery of ${REMOTE_HOST}"

# Stop postgres, remove data, make new backup
ssh -T postgres@$REMOTE_HOST "
/etc/init.d/postgresql-9.3 stop
rm -rf $REMOTE_PGDATA
pg_basebackup -d \"host=$HOSTNAME user=repl password=replpass\" -D $REMOTE_PGDATA -x -c fast
"

logger -t pgpool_recovery "Configure recovery of ${REMOTE_HOST}"
# make new recovery file
sed "s/XXX_POSTGRES_MASTER_XXX/$HOSTNAME/" ${RECTEMPLATE} > ${TMPREC}
scp ${TMPREC} postgres@$REMOTE_HOST:${REMOTE_PGDATA}/recovery.conf

# Start postgres again
logger -t pgpool_recovery "Finishing recovery of ${REMOTE_HOST}"
ssh -T postgres@$REMOTE_HOST -- /usr/pgsql-9.3/bin/pg_ctl -D ${REMOTE_PGDATA} -l pgstartup.log start

logger -t pgpool_recovery "Finished recovery of ${REMOTE_HOST}"

