#!/bin/bash
source /root/keystonerc_admin
for ((n=1;n<9;n++)) ; do nova delete aio23${n} compute24${n}; sleep 3; ./build-tenant.sh 23${n} 24${n} 1 2 ; sleep 10 ; nova list | grep "23${n}\|24${n}" ;done
