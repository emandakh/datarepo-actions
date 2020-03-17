#!/bin/bash

function checknamespaceclean {

  if [[ "${GOOGLE_APPLICATION_CREDENTIALS}" != "" ]] && [[ "${NAMESPACEINUSE}"; then
    run: kubectl delete secret -n ${NAMESPACEINUSE} "${NAMESPACEINUSE}-inuse"
  else
    echo "required var not defined for function checknamespaceclean"
    exit 1
  fi
}
