source ./messenger_api/.env

REMOVE_CONNECTION="SELECT pg_terminate_backend (pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${POSTGRES_DB}';"

DB_KUBE_POD=$(kubectl get pods -o='name' | grep postgres-deployment)
DB_KUBE_POD=${DB_KUBE_POD:4}
DB_CONTAINER=messenger_api-db-1
docker exec -i ${DB_CONTAINER} psql -U $POSTGRES_USER -c "${REMOVE_CONNECTION}"
kubectl exec $DB_KUBE_POD -- pg_dump --username $POSTGRES_USER $POSTGRES_DB > /tmp/${POSTGRES_DB}_dump.sql
docker exec -i ${DB_CONTAINER} dropdb ${POSTGRES_DB}
docker exec -i ${DB_CONTAINER} createdb ${POSTGRES_DB}
cat /tmp/${POSTGRES_DB}_dump.sql | docker exec -i ${DB_CONTAINER} psql
rm -rf /tmp/${POSTGRES_DB}_dump.sql