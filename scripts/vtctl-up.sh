#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/tmp"

# Add the CellInfo description for the cell
vtctl \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  VtctldCommand AddCellInfo -- \
  --root "/vitess/somecell" \
  --server-address "topology:2379" \
  somecell

# Start vtctld
vtctld \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --cell "somecell" \
  --workflow_manager_init \
  --workflow_manager_use_election \
  --service_map 'grpc-vtctl,grpc-vtctld' \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --port "15000" \
  --grpc_port "15999" \
  --pid_file "/home/vitess/vtdataroot/tmp/vtctld.pid" \
   > "/home/vitess/vtdataroot/tmp/vtctld.out" 2>&1 &

sleep 3

disown -a
