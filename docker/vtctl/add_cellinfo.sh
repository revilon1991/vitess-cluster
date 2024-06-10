#!/bin/bash
set -e

until nc -z localhost 15999; do sleep 0.1; done

set +e
/usr/local/bin/vtctldclient GetCellInfo --server localhost:15999 somecell > /dev/null 2>&1
exitCode=$?
set -e

if [[ ${exitCode} -eq 1 ]]; then
  /usr/local/bin/vtctldclient AddCellInfo --server localhost:15999 --root /vitess/somecell --server-address topology:2181 somecell;
  echo "Cell was created";
else
  echo "Cell is already existed, skipping...";
fi
