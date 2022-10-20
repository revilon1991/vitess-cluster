#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/etcd"
mkdir -p "/home/vitess/vtdataroot/tmp"

# Start etcd
etcd \
  --enable-v2=true \
  --data-dir "/home/vitess/vtdataroot/etcd/" \
  --listen-client-urls "http://0.0.0.0:2379" \
  --advertise-client-urls "http://0.0.0.0:2379" \
  > "/home/vitess/vtdataroot/tmp/etcd.out" 2>&1 &

sleep 3

echo $! > "/home/vitess/vtdataroot/tmp/etcd.pid"

etcdctl --endpoints "http://0.0.0.0:2379" mkdir /vitess/global &
etcdctl --endpoints "http://0.0.0.0:2379" mkdir /vitess/somecell &

disown -a
