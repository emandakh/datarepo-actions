#!/bin/bash

function ct_render {
  find . -name "*.ctmpl" -print | while read file
    do
      rootname="${file%.ctmpl}"
      echo "$file -> $rootname"
      /usr/local/bin/consul-template \
      -once \
      -log-level=debug \
      -template=${file}:${rootname}
    done
  initExitCode=${?}

  exit ${initExitCode}
}
