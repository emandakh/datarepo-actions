#!/bin/bash

function stripColors {
  echo "${1}" | sed 's/\x1b\[[0-9;]*m//g'
}

function hasPrefix {
  case ${2} in
    "${1}"*)
      true
      ;;
    *)
      false
      ;;
  esac
}

function parseInputs {
  # Required inputs
  if [ "${INPUT_CT_ACTIONS_VERSION}" != "" ]; then
    ctVersion=${INPUT_CT_ACTIONS_VERSION}
  else
    echo "Input consul_templateversion cannot be empty"
    exit 1
  fi

  if [ "${INPUT_ACTIONS_SUBCOMMAND}" != "" ]; then
    subcommand=${INPUT_ACTIONS_SUBCOMMAND}
  else
    echo "Input subcommand cannot be empty"
    exit 1
  fi

  # Optional inputs
  workingDir="."
  if [[ -n "${INPUT_TF_ACTIONS_WORKING_DIR}" ]]; then
    workingDir=${INPUT_TF_ACTIONS_WORKING_DIR}
  fi

  role_id=""
  if [ "${INPUT_ROLE_ID}" != "" ]; then
    role_id=${INPUT_ROLE_ID}
  fi

  secret_id=""
  if [ "${INPUT_SECRET_ID}" != "" ]; then
    secret_id=${INPUT_SECRET_ID}
  fi

  ctWorkspace="default"
  if [ -n "${CT_WORKSPACE}" ]; then
    ctWorkspace="${CT_WORKSPACE}"
  fi

  vault_address="https://clotho.broadinstitute.org:8200"
  if [ -n "${VAULT_ADDRESS}" ]; then
    vault_address="${CT_WORKSPACE}"
  fi
}

function configureCtCredentials {
  if [[ "${role_id}" != "" ]] && [[ "${secret_id}" != "" ]]; then
    VAULT_TOKEN=$(curl \
            --request POST \
            --data '{"role_id":"'"${role_id}"'","secret_id":"'"${role_id}"'"}' \
            ${vault_address}/v1/auth/approle/login | jq -r .auth.client_token)
  fi
}

function main {
  # Source the other files to gain access to their functions
  scriptDir=$(dirname ${0})
  source ${scriptDir}/consul_template.sh


  parseInputs
  configureCtCredentials
  cd ${GITHUB_WORKSPACE}/${workingDir}

  case "${subcommand}" in
    ct_render)
      ct_render ${*}
      ;;
    *)
      echo "Error: Must provide a valid value for consul_templatesubcommand"
      exit 1
      ;;
  esac
}

main "${*}"
