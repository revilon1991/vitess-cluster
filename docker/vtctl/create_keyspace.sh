#!/bin/bash
set -e

until nc -z localhost 15999; do sleep 0.1; done

set +e
/usr/local/bin/vtctldclient --server localhost:15999 GetKeyspace unsharded > /dev/null 2>&1
exitCode=$?
set -e

if [[ ${exitCode} -eq 1 ]]; then
  /usr/local/bin/vtctldclient --server localhost:15999 CreateKeyspace unsharded > /dev/null;
  echo "Unsharded keyspace was created";
else
  echo "Unsharded keyspace was already created, skipping...";
fi

set +e
/usr/local/bin/vtctldclient --server localhost:15999 GetKeyspace sharded > /dev/null 2>&1
exitCode=$?
set -e

if [[ ${exitCode} -eq 1 ]]; then
  /usr/local/bin/vtctldclient --server localhost:15999 CreateKeyspace sharded > /dev/null;
  echo "Sharded keyspace was created";
else
  echo "Sharded keyspace was already created, skipping...";
fi
