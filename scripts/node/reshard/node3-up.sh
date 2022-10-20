#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/backups"
mkdir -p "/home/vitess/vtdataroot/tmp"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "300" \
  --mysql_port "17300" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000300_querylog.txt" \
  --tablet-path "somecell-0000000300" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "-80" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15300" \
  --grpc_port "16300" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000300/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000300/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15300/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "301" \
  --mysql_port "17301" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000301_querylog.txt" \
  --tablet-path "somecell-0000000301" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "-80" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15301" \
  --grpc_port "16301" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000301/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000301/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15301/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "302" \
  --mysql_port "17302" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000302_querylog.txt" \
  --tablet-path "somecell-0000000302" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "-80" \
  --init_tablet_type "rdonly" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15302" \
  --grpc_port "16302" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000302/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000302/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15302/debug/status"

vtctlclient --server vtctl:15999 InitShardPrimary -- --force kekspace/-80 somecell-300
