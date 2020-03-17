#!/bin/bash

function checknamespace {
  NAMESPACEINUSE=""
  IT_JADE_API_URL=""
  if [[ "${GOOGLE_APPLICATION_CREDENTIALS}" != "" ]] && [[ "${k8_cluster}"; then
    gcloud container clusters get-credentials ${k8_cluster}
  fi
  for i in "${k8_namespaces[@]}"
  do
    if kubectl get secrets -n ${i} ${i}-inuse > /dev/null 2>&1; then
      printf "Namespace ${i} in use Skipping\n"
    else
      printf "Namespace ${i} not in use Deploying integration test to ${i}\n"
      kubectl create secret generic ${i}-inuse --from-literal=inuse=${i} -n ${i}
      tail=$(echo $i | awk -F- {'print $2'})
      IT_JADE_API_URL="https://jade-${tail}.datarepo-integration.broadinstitute.org"
      NAMESPACEINUSE=${i}
      return 0
    fi
  done
  sleep 120
  checknamespace
}
