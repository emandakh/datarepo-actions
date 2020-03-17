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

function installConsulTemplate {
  if [[ "${ctVersion}" == "latest" ]]; then
    echo "Checking the latest version of Consul-Template"
    ctVersion=$(curl -sL https://releases.hashicorp.com/consul-template/index.json | jq -r '.versions[].version' | grep -v '[-].*' | sort -rV | head -n 1)

    if [[ -z "${ctVersion}" ]]; then
      echo "Failed to fetch the latest version"
      exit 1
    fi
  fi

  url="https://releases.hashicorp.com/consul-template/${ctVersion}/consul-template_${ctVersion}_linux_amd64.zip"

  echo "Downloading Consul-Template v${ctVersion}"
  curl -s -S -L -o /tmp/consul_template${ctVersion} ${url}
  if [ "${?}" -ne 0 ]; then
    echo "Failed to download Consul-Template v${ctVersion}"
    exit 1
  fi
  echo "Successfully downloaded Consul-Template v${ctVersion}"

  echo "Unzipping Consul-Template v${ctVersion}"
  unzip -d /usr/local/bin /tmp/consul_template${ctVersion} &> /dev/null
  if [ "${?}" -ne 0 ]; then
    echo "Failed to unzip Consul-Template v${ctVersion}"
    exit 1
  fi
  echo "Successfully unzipped Consul-Template v${ctVersion}"
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
      installConsulTemplate
      ct_render ${*}
      ;;
    *)
      echo "Error: Must provide a valid value for consul_templatesubcommand"
      exit 1
      ;;
  esac
}

main "${*}"
