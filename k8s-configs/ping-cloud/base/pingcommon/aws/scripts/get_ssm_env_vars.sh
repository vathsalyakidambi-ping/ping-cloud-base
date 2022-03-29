#!/bin/sh

VERBOSE="${VERBOSE:-false}"

# Configuration file to share environment variables with main container.
CONFIG_FILE='/config/ds_env_vars'

# Enable debug flag for aws cli if VERBOSE is true
if "${VERBOSE}"; then
  AWS_DEBUG='--debug'
fi

# Verify that the mandatory variable is set.
if test -z "${REGION}"; then
  echo "REGION environment variable must be set"
  exit 1
fi

echo "AWSCLI VERSON: $(aws --version)"
echo "AWS_REGION: ${REGION}"

# Query aws endpoint to get value associated with the key.
get_ssm_val() {
  param_name="$1"
  if ! ssm_val="$(aws ${AWS_DEBUG} ssm --region "${REGION}"  get-parameters \
            --names "${param_name}" \
            --query 'Parameters[*].Value' \
            --with-decryption \
            --output text)"; then
    echo "$ssm_val"
    return 1
  fi
  echo "$ssm_val"
}

# Check all the environment variables
get_ssm_key() {
  for i in $(printenv); do
    key=${i%=*}
    val=${i#*=}
    case "$val" in "ssm://"*)
      if ! ssm_rv=$(get_ssm_val "${val#ssm:/}"); then
        return 1
      fi
      echo "$key=$ssm_rv" >>"${CONFIG_FILE}"
    esac
  done
}

echo "# Start Discovery Service" >>"${CONFIG_FILE}"

if ! get_ssm_key; then
  exit 1
fi

echo "# End Discovery Service" >>"${CONFIG_FILE}"

exit 0