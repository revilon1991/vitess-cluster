#!/bin/bash

# To start semi sync replication requires as minimum 2 alive replicas and 1 potential primary
until /usr/local/bin/vtctldclient --server vtctl:15999 RunHealthCheck somecell-301 > /dev/null 2>&1; do sleep 0.1; done
until /usr/local/bin/vtctldclient --server vtctl:15999 RunHealthCheck somecell-302 > /dev/null 2>&1; do sleep 0.1; done
until /usr/local/bin/vtctldclient --server vtctl:15999 RunHealthCheck somecell-303 > /dev/null 2>&1; do sleep 0.1; done

set +e
/usr/local/bin/vtctldclient --server vtctl:15999 GetTablets --tablet-alias somecell-301 | grep -qw primary
exitCode=$?
set -e

if [[ ${exitCode} -eq 1 ]]; then
  /usr/local/bin/vtctldclient --server vtctl:15999 PlannedReparentShard sharded/-80 --new-primary somecell-301;
  echo "PlannedReparentShard is successfully done";
else
  echo "PlannedReparentShard was already successfully done, skipping...";
fi
