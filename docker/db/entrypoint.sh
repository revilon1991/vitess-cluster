#!/bin/bash

sudo service mysql stop
sudo service etcd stop
sudo systemctl disable mysql
sudo systemctl disable etcd
sudo service syslog-ng start

while :; do sleep 10; done
