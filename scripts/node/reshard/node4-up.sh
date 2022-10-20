#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/backups"
mkdir -p "/home/vitess/vtdataroot/tmp"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "400" \
  --mysql_port "17400" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000400_querylog.txt" \
  --tablet-path "somecell-0000000400" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "80-" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15400" \
  --grpc_port "16400" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000400/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000400/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15400/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "401" \
  --mysql_port "17401" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000401_querylog.txt" \
  --tablet-path "somecell-0000000401" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "80-" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15401" \
  --grpc_port "16401" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000401/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000401/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15401/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "402" \
  --mysql_port "17402" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000402_querylog.txt" \
  --tablet-path "somecell-0000000402" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "80-" \
  --init_tablet_type "rdonly" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15402" \
  --grpc_port "16402" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000402/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000402/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15402/debug/status"

vtctlclient --server vtctl:15999 InitShardPrimary -- --force kekspace/80- somecell-400

# Separate tables to sharding
vtctlclient --server vtctl:15999 ApplyVSchema -- --vschema_file /app/scripts/vschema_sharded.json kekspace
vtctlclient --server vtctl:15999 Reshard -- --source_shards '0' --target_shards '-80,80-' Create kekspace.kek2kek
sleep 3
vtctlclient --server vtctl:15999 Reshard -- --tablet_types=rdonly,replica SwitchTraffic kekspace.kek2kek
vtctlclient --server vtctl:15999 Reshard -- --tablet_types=primary SwitchTraffic kekspace.kek2kek
vtctlclient --server vtctl:15999 Reshard Complete kekspace.kek2kek
