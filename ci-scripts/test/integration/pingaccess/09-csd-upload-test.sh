#!/bin/bash

. "${PROJECT_DIR}"/ci-scripts/common.sh "${1}"

if skipTest "${0}"; then
  log "Skipping test ${0}"
  exit 0
fi

testPingAccessRuntimeCsdUpload() {
  csd_upload "pingaccess-periodic-csd-upload" "${PROJECT_DIR}"/k8s-configs/ping-cloud/base/pingaccess/engine/aws/periodic-csd-upload.yaml
  assertEquals 0 $?
}

testPingAccessAdminCsdUpload() {
  csd_upload "pingaccess-admin-periodic-csd-upload" "${PROJECT_DIR}"/k8s-configs/ping-cloud/base/pingaccess/admin/aws/periodic-csd-upload.yaml
  assertEquals 0 $?
}

csd_upload() {
  local upload_csd_job_name="${1}"
  local upload_job="${2}"

  log "Applying the CSD upload job"
  kubectl delete -f "${upload_job}" -n "${NAMESPACE}"
  assertEquals "The kubectl delete command to remove an existing ${upload_csd_job_name} should have succeeded" 0 $?

  kubectl apply -f "${upload_job}" -n "${NAMESPACE}"
  assertEquals "The kubectl apply command to create the ${upload_csd_job_name} should have succeeded" 0 $?

  kubectl create job --from=cronjob/${upload_csd_job_name} ${upload_csd_job_name} -n "${NAMESPACE}"
  assertEquals "The kubectl create command to create the job should have succeeded" 0 $?

  log "Waiting for CSD upload job to complete..."
  kubectl wait --for=condition=complete --timeout=900s job.batch/${upload_csd_job_name} -n "${NAMESPACE}"
  assertEquals "The kubectl wait command for the job should have succeeded" 0 $?

  sleep 5

  log "Expected CSD files:"
  expected_files "${upload_csd_job_name}" | tee /tmp/expected.txt

  if ! verify_upload_with_timeout "pingaccess"; then
    return 1
  fi
  return 0
}

# When arguments are passed to a script you must
# consume all of them before shunit is invoked
# or your script won't run.  For integration
# tests, you need this line.
shift $#

# load shunit
. ${SHUNIT_PATH}