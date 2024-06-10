#!/bin/bash
set -e

until /usr/local/bin/vtctldclient --server vtctl:15999 GetKeyspace unsharded > /dev/null 2>&1; do sleep 0.1; done

set +e
/usr/local/bin/vtctldclient --server vtctl:15999 GetKeyspace unsharded | grep -qw semi_sync
exitCode=$?
set -e

if [[ ${exitCode} -eq 1 ]]; then
  /usr/local/bin/vtctldclient --server vtctl:15999 SetKeyspaceDurabilityPolicy --durability-policy=semi_sync unsharded > /dev/null;
  echo "Durability policy semi_sync for unsharded was setted";
else
  echo "Durability policy semi_sync for unsharded was already setted, skipping...";
fi

until /usr/local/bin/vtctldclient --server vtctl:15999 GetKeyspace sharded > /dev/null 2>&1; do sleep 0.1; done

set +e
/usr/local/bin/vtctldclient --server vtctl:15999 GetKeyspace sharded | grep -qw semi_sync
exitCode=$?
set -e

if [[ ${exitCode} -eq 1 ]]; then
  /usr/local/bin/vtctldclient --server vtctl:15999 SetKeyspaceDurabilityPolicy --durability-policy=semi_sync sharded > /dev/null;
  echo "Durability policy semi_sync for sharded was setted";
else
  echo "Durability policy semi_sync for sharded was already setted, skipping...";
fi
