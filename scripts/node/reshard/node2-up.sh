#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/backups"
mkdir -p "/home/vitess/vtdataroot/tmp"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "200" \
  --mysql_port "17200" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000200_querylog.txt" \
  --tablet-path "somecell-0000000200" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "0" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15200" \
  --grpc_port "16200" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000200/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000200/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15200/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "201" \
  --mysql_port "17201" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000201_querylog.txt" \
  --tablet-path "somecell-0000000201" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "0" \
  --init_tablet_type "replica" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15201" \
  --grpc_port "16201" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000201/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000201/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15201/debug/status"

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --tablet_uid "202" \
  --mysql_port "17202" \
  init

VTDATAROOT="/home/vitess/vtdataroot" vttablet \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vttablet_0000000202_querylog.txt" \
  --tablet-path "somecell-0000000202" \
  --tablet_hostname "" \
  --init_keyspace "kekspace" \
  --init_shard "0" \
  --init_tablet_type "rdonly" \
  --health_check_interval "5s" \
  --enable_semi_sync \
  --enable_replication_reporter \
  --backup_storage_implementation "file" \
  --file_backup_storage_root "/home/vitess/vtdataroot/backups" \
  --restore_from_backup \
  --port "15202" \
  --grpc_port "16202" \
  --service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  --pid_file "/home/vitess/vtdataroot/vt_0000000202/vttablet.pid" \
  --vtctld_addr "http://vtctl:15000/" \
  > "/home/vitess/vtdataroot/vt_0000000202/vttablet.out" 2>&1 &

sleep 3

# Check status
curl -I "http://localhost:15202/debug/status"

vtctlclient --server vtctl:15999 InitShardPrimary -- --force kekspace/0 somecell-200
vtctlclient --server vtctl:15999 ReloadSchemaKeyspace kekspace

# Move tables to sharding
vtctlclient --server vtctl:15999 MoveTables -- --source lolspace --tables 'Device,User' Create kekspace.lolspace2kekspace
sleep 3
vtctlclient --server vtctl:15999 MoveTables -- --tablet_types=rdonly,replica SwitchTraffic kekspace.lolspace2kekspace
vtctlclient --server vtctl:15999 MoveTables -- --tablet_types=primary SwitchTraffic kekspace.lolspace2kekspace
vtctlclient --server vtctl:15999 MoveTables Complete kekspace.lolspace2kekspace
