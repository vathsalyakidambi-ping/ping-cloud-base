#!/bin/bash

CI_SCRIPTS_DIR="${SHARED_CI_SCRIPTS_DIR:-/ci-scripts}"
. "${CI_SCRIPTS_DIR}"/common.sh "${1}"
. "${CI_SCRIPTS_DIR}"/test/test_utils.sh

if skipTest "${0}"; then
  log "Skipping test ${0}"
  exit 0
fi

testUrls() {

  return_code=0
  for i in {1..10}
  do
    testUrlsWithoutBasicAuthExpect2xx "${PINGCENTRAL_CONSOLE}"
    return_code=$?
    if [[ ${return_code} -ne 0 ]]; then
      log "The PingCentral endpoint is inaccessible.  This is attempt ${i} of 10.  Wait 60 seconds and then try again..."
      sleep 60
    else
      break
    fi
  done

  assertEquals "Failed to connect to the PingCentral URLs: ${PINGCENTRAL_CONSOLE}" 0 ${return_code}
}

# When arguments are passed to a script you must
# consume all of them before shunit is invoked
# or your script won't run.  For integration
# tests, you need this line.
shift $#

# load shunit
. ${SHUNIT_PATH}