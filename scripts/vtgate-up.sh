#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/tmp"

# Start vtgate
vtgate \
  --topo_implementation "etcd2" \
  --topo_global_server_address "topology:2379" \
  --topo_global_root "/vitess/global" \
  --mysql_server_version "8.0.30" \
  --log_dir "/home/vitess/vtdataroot/tmp" \
  --log_queries_to_file "/home/vitess/vtdataroot/tmp/vtgate_querylog.txt" \
  --port "15001" \
  --grpc_port "15991" \
  --mysql_server_port "15306" \
  --mysql_server_socket_path "/tmp/mysql.sock" \
  --cell "somecell" \
  --cells_to_watch "somecell" \
  --tablet_types_to_wait "PRIMARY,REPLICA" \
  --service_map "grpc-vtgateservice" \
  --pid_file "/home/vitess/vtdataroot/tmp/vtgate.pid" \
  --mysql_auth_server_impl="static" \
  --mysql_auth_server_static_file="/app/scripts/users.json" \
  > "/home/vitess/vtdataroot/tmp/vtgate.out" 2>&1 &

sleep 3

# check status
curl -I "http://localhost:15001/debug/status"

disown -a

# Load dataset to main node
mysql -uroot -proot -h127.0.0.1 -P15306 --table < /app/scripts/dataset.sql
mysql -uroot -proot -h127.0.0.1 -P15306 --table <<EOL
    \! echo 'Using lolspace'
    use lolspace;
    \! echo 'Device'
    select * from Device;
    \! echo 'User'
    select * from User;
    \! echo 'RequestLog'
    select * from RequestLog;
EOL

mysql -uroot -proot -h127.0.0.1 -P15306 --table --execute="show vitess_tablets"
