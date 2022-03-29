#!/bin/bash

. "${PROJECT_DIR}"/ci-scripts/common.sh "${1}"

if skipTest "${0}"; then
  log "Skipping test ${0}"
  exit 0
fi

. "${PROJECT_DIR}"/ci-scripts/test/integration/pingaccess/runtime/send-request-to-runtime-port.sh

testVerifyPAEngines() {

  return_code=0
  for i in {1..10}
  do
    send_request_to_runtime_port 'pingaccess-0' "${NAMESPACE}"
    return_code=$?
    if [[ ${return_code} -ne 0 ]]; then
      log "The pingaccess-0 runtime is inaccessible.  This is attempt ${i} of 10.  Wait 60 seconds and then try again..."
      sleep 60
    else
      break
    fi
  done

  assertEquals "Failed to connect to the PingAccess Engine runtime port for pingaccess-0" 0 ${return_code}
}

# When arguments are passed to a script you must
# consume all of them before shunit is invoked
# or your script won't run.  For integration
# tests, you need this line.
shift $#

# load shunit
. ${SHUNIT_PATH}