#!/bin/bash

set -e

# Source common environment variables
SCRIPT_HOME=$(cd $(dirname ${0}); pwd)
. ${SCRIPT_HOME}/../common.sh

# Configure aws and kubectl, unless skipped
configure_aws
configure_kube

# Do not ever delete the environment on the master branch. And only delete an environment,
# if the DELETE_ENV_AFTER_PIPELINE flag is true
if test "${CI_COMMIT_REF_SLUG}" = 'master' || test "${DELETE_ENV_AFTER_PIPELINE}" = 'false'; then
  log "Not deleting environment ${NAMESPACE}"
  log "Not deleting PingCentral database ${MYSQL_DATABASE} from host ${MYSQL_SERVICE_HOST}"
  exit 0
fi

all_namespaces=$(kubectl get ns -o name)
deleting_ns=()

for ns in $all_namespaces; do
  if [[ $ns == *"kube-"* || $ns == "namespace/default" || $ns == *"cluster-in-use-lock"* ]]; then
    log "Skipping namespace ${ns}"
    continue
  fi
  log "Deleting namespace asynchronously: ${ns}"
  kubectl delete "${ns}" --wait=false
  deleting_ns+=($ns)
done

wait_time=15

for ns in "${deleting_ns[@]}"; do
  while kubectl get ns -o name | grep $ns > /dev/null; do
    log "Waiting for namespace ${ns} to terminate"
    log "Sleeping for ${wait_time} seconds and trying again"
    sleep ${wait_time}
  done
done

pod_name="mysql-client-${CI_COMMIT_REF_SLUG}"
MYSQL_USER=$(get_ssm_val "${MYSQL_USER_SSM}")
MYSQL_PASSWORD=$(get_ssm_val "${MYSQL_PASSWORD_SSM}")

log "Deleting PingCentral database ${MYSQL_DATABASE} from host ${MYSQL_SERVICE_HOST}"
kubectl run -n default -i "${pod_name}" --restart=Never --rm --image=arey/mysql-client -- \
      -h "${MYSQL_SERVICE_HOST}" -P ${MYSQL_SERVICE_PORT} \
      -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
      -e "drop database ${MYSQL_DATABASE}"

# Sometimes, the cron job on the cluster - "cleanup-nondefault-namespaces" might clean up the lock before we can. 
# So check if it exists first.
if kubectl get ns cluster-in-use-lock > /dev/null 2>&1; then
  # Finally, delete the cluster-in-use-lock namespace. Do this last so that the cluster is clear for use by the next branch
  log "cluster-in-use-lock namespace synchronously deleting (will exit when done)"
  kubectl delete ns cluster-in-use-lock
fi