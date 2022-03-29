#!/bin/bash

. "${PROJECT_DIR}"/ci-scripts/common.sh "${1}"

if skipTest "${0}"; then
  log "Skipping test ${0}"
  exit 0
fi

testUrls() {

  exit_code=0
  for i in {1..10}
  do
    testUrlsExpect2xx "${PINGDELEGATOR_CONSOLE}"
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
      log "The Ping Delegated Admin endpoints are inaccessible.  This is attempt ${i} of 10.  Wait 60 seconds and then try again..."
      sleep 60
    else
      break
    fi
  done

  assertEquals 0 $exit_code
}


# When arguments are passed to a script you must
# consume all of them before shunit is invoked
# or your script won't run.  For integration
# tests, you need this line.
shift $#

# load shunit
. ${SHUNIT_PATH}