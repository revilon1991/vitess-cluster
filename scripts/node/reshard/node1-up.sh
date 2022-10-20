#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/backups"
mkdir -p "/home/vitess/vtdataroot/tmp"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "100" \
  --mysql_port "17100" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000100_querylog.txt" \
  --tablet-path "somecell-0000000100" \
  --tablet_hostname "" \
  --init_keyspace "lolspace" \
  --init_shard "0" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15100" \
  --grpc_port "16100" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000100/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000100/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15100/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "101" \
  --mysql_port "17101" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000101_querylog.txt" \
  --tablet-path "somecell-0000000101" \
  --tablet_hostname "" \
  --init_keyspace "lolspace" \
  --init_shard "0" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15101" \
  --grpc_port "16101" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000101/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000101/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15101/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "102" \
  --mysql_port "17102" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000102_querylog.txt" \
  --tablet-path "somecell-0000000102" \
  --tablet_hostname "" \
  --init_keyspace "lolspace" \
  --init_shard "0" \
  --init_tablet_type "rdonly" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15102" \
  --grpc_port "16102" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000102/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000102/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15102/debug/status"

# Load DDL schema
vtctldclient --server vtctl:15999 SetKeyspaceDurabilityPolicy --durability-policy=semi_sync lolspace
vtctldclient --server vtctl:15999 PlannedReparentShard lolspace/0 --new-primary somecell-100
vtctldclient --server vtctl:15999 ApplySchema --sql-file /app/scripts/schema.sql lolspace
vtctldclient --server vtctl:15999 ApplyVSchema --vschema-file /app/scripts/vschema.json lolspace
