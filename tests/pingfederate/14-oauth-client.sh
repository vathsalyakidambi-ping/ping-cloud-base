#!/bin/bash

CI_SCRIPTS_DIR="${SHARED_CI_SCRIPTS_DIR:-/ci-scripts}"
. "${CI_SCRIPTS_DIR}"/common.sh "${1}"

if skipTest "${0}"; then
  log "Skipping test ${0}"
  exit 0
fi

export PF_ADMIN_USERNAME="administrator"
export PF_ADMIN_PASSWORD="2FederateM0re"
export templates_dir_path="${PROJECT_DIR}"/tests/pingfederate/templates

create_token_payload=$(envsubst < ${templates_dir_path}/refresh_oauth_token.json)
function make_api_request() {
  http_code=$(curl -Sk -o /tmp/api_response.txt -w "%{http_code}" \
        -u ${PF_ADMIN_USERNAME}:${PF_ADMIN_PASSWORD} \
        -H "Content-Type: application/json" \
        -H 'X-Xsrf-Header: PingFederate' "$@")
  curl_result=$?

  if test "${curl_result}" -ne 0; then
    return ${curl_result}
  fi

  if test "${http_code}" -ne 200; then
    return 1
  fi
  
  return 0
}

testOauthClients() {
  response=$(make_api_request -s -X POST -d "${create_token_payload}" "${PINGFEDERATE_ADMIN_API}/oauth/clients" > /dev/null)
  cat /tmp/api_response.txt | jq
  assertEquals "Response value was ${response}" 0 $?
}

# When arguments are passed to a script you must
# consume all of them before shunit is invoked
# or your script won't run.  For integration
# tests, you need this line.
shift $#

# load shunit
. ${SHUNIT_PATH}


