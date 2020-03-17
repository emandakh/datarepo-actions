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
  if [ "${INPUT_ACTIONS_SUBCOMMAND}" != "" ]; then
    subcommand=${INPUT_ACTIONS_SUBCOMMAND}
  else
    echo "Input subcommand cannot be empty"
    exit 1
  fi

  # Optional inputs
  role_id=""
  if [ -n "${INPUT_ROLE_ID}" ]; then
    role_id=${INPUT_ROLE_ID}
  fi
  secret_id=""
  if [ -n "${INPUT_SECRET_ID}" ]; then
    secret_id=${INPUT_SECRET_ID}
  fi
  vault_address="${INPUT_VAULT_ADDRESS}"
  google_zone="${INPUT_GOOGLE_ZONE}"
  google_project="${INPUT_GOOGLE_PROJECT}"
  gcr_google_project="${INPUT_GCR_GOOGLE_PROJECT}"
  google_application_credentials=""
  if [ -n "${INPUT_GOOGLE_APPLICATION_CREDENTIALS}" ]; then
    google_application_credentials="${INPUT_GOOGLE_APPLICATION_CREDENTIALS}"
  fi
  k8_cluster=""
  if [ -n "${INPUT_K8_CLUSTER}" ]; then
    k8_cluster="${INPUT_K8_CLUSTER}"
  fi
  k8_namespaces=""
  if [ -n "${INPUT_K8_NAMESPACES}" ]; then
    k8_cluster="${INPUT_K8_NAMESPACES}"
  fi
  helm_secret_chart_version=""
  if [ -n "${INPUT_HELM_SECRET_CHART_VERSION}" ]; then
    helm_secret_chart_version="${INPUT_HELM_SECRET_CHART_VERSION}"
  fi
  helm_datarepo_chart_version=""
  if [ -n "${INPUT_HELM_DATAREPO_CHART_VERSION}" ]; then
    helm_datarepo_chart_version="${INPUT_HELM_DATAREPO_CHART_VERSION}"
  fi
  gcr_tag=""
  if [ -n "${INPUT_GCR_TAG}" ]; then
    gcr_tag="${INPUT_GCR_TAG}"
  fi
  workingDir="."
  if [[ -n "${INPUT_ACTIONS_WORKING_DIR}" ]]; then
    workingDir=${INPUT_ACTIONS_WORKING_DIR}
  fi
}

function configureCredentials {
  if [[ "${role_id}" != "" ]] && [[ "${secret_id}" != "" ]] && [[ "${vault_address}" != "" ]]; then
    export VAULT_TOKEN=$(curl \
      --request POST \
      --data '{"role_id":"'"${role_id}"'","secret_id":"'"${secret_id}"'"}' \
      ${vault_address}/v1/auth/approle/login | jq -r .auth.client_token)
    vault read -format=json secret/dsde/datarepo/dev/sa-key.json | \
      jq .data > /tmp/${GOOGLE_APPLICATION_CREDENTIALS}
    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/${GOOGLE_APPLICATION_CREDENTIALS}
  fi
}

function googleAuth {
  if [[ "${GOOGLE_APPLICATION_CREDENTIALS}" != "" ]] && [[ "${google_zone}" != "" ]] && [[ "${google_project}" != "" ]]; then
    gcloud auth activate-service-account --key-file /tmp/${GOOGLE_APPLICATION_CREDENTIALS}
    # configure integration prerequisites
    gcloud config set compute/zone ${google_zone}
    gcloud config set project ${google_project}
    gcloud auth configure-docker
  fi
}


function main {
  su - jade
  # Source the other files to gain access to their functions
  scriptDir=$(dirname ${0})
  source ${scriptDir}/consul-template.sh
  source ${scriptDir}/whitelist.sh
  source ${scriptDir}/checknamespace.sh
  source ${scriptDir}/helmdeploy.sh
  source ${scriptDir}/whitelistclean.sh
  source ${scriptDir}/checknamespaceclean.sh
  source ${scriptDir}/test.sh


  parseInputs
  configureCredentials
  googleAuth
  cd ${GITHUB_WORKSPACE}/${workingDir}

  case "${subcommand}" in
    ct_render)
      ct_render ${*}
      ;;
    gcp_whitelist)
      whitelist ${*}
      ;;
    k8_checknamespace)
      checknamespace ${*}
      ;;
    helmdeploy)
      helmdeploy ${*}
      ;;
    gcp_whitelist_clean)
      whitelistclean ${*}
      ;;
    k8_checknamespace_clean)
      checknamespaceclean ${*}
      ;;
    test)
      test ${*}
      ;;
    *)
      echo "Error: Must provide a valid value for actions_subcommand"
      exit 1
      ;;
  esac
}

main "${*}"
