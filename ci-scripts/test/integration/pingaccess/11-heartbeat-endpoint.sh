#!/bin/bash

. "${PROJECT_DIR}"/ci-scripts/common.sh "${1}"

if skipTest "${0}"; then
  log "Skipping test ${0}"
  exit 0
fi

testPingAccessHeartbeatEndpointExist() {
  PRODUCT_NAME=pingaccess
  SERVER=
  CONTAINER=

  SERVERS=$( kubectl get pod -o name -n "${NAMESPACE}" -l role=${PRODUCT_NAME}-engine | grep ${PRODUCT_NAME} | cut -d/ -f2)

  for SERVER in ${SERVERS}; do
    # Set the container name
    test "${SERVER}" == "${PRODUCT_NAME}-admin-0" && CONTAINER="${PRODUCT_NAME}-admin" || CONTAINER="${PRODUCT_NAME}"
    curl_heartbeat ${SERVER} ${CONTAINER} >> /dev/null
    assertEquals "Metrics endpoint can't be reached on ${SERVER}" 0 $?
  done
}

 testPingAccessHeartbeatPublished() {
   PRODUCT_NAME=pingaccess
   SERVER=
   CONTAINER=

   SERVERS=$( kubectl get pod -o name -n "${NAMESPACE}" -l role=${PRODUCT_NAME}-engine | grep ${PRODUCT_NAME} | cut -d/ -f2)

   for SERVER in ${SERVERS}; do
     # Set the container name
     test "${SERVER}" == "${PRODUCT_NAME}-admin-0" && CONTAINER="${PRODUCT_NAME}-admin" || CONTAINER="${PRODUCT_NAME}"
     metrics=$(curl_heartbeat ${SERVER} ${CONTAINER})
     assertContains "${metrics}" "metric_pingaccess_response_concurrency_statistics_90_percentile"
     assertContains "${metrics}" "metric_pingaccess_response_concurrency_statistics_mean"
     assertContains "${metrics}" "metric_pingaccess_response_statistics_count"
     assertContains "${metrics}" "metric_pingaccess_response_time_statistics_90_percentile"
     assertContains "${metrics}" "metric_pingaccess_response_time_statistics_mean"
   done
 }

curl_heartbeat() {
    SERVER=$1
    CONTAINER=$2
    
    kubectl exec -n ${NAMESPACE} ${SERVER} -c ${CONTAINER} -- sh -c "curl -s localhost:8079"
}

# When arguments are passed to a script you must
# consume all of them before shunit is invoked
# or your script won't run.  For integration
# tests, you need this line.
shift $#

# load shunit
. ${SHUNIT_PATH}
