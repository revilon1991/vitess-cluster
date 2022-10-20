#!/bin/bash

uid=$TABLET_UID

printf -v tablet_dir 'vt_%010d' $uid
pid=`cat /home/vitess/vtdataroot/$tablet_dir/vttablet.pid`

kill $pid

# Wait for vttablet to die.
while ps -p $pid > /dev/null; do sleep 1; done

VTDATAROOT="/home/vitess/vtdataroot" mysqlctl --tablet_uid $uid shutdown
