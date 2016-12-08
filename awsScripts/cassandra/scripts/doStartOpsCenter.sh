#!/bin/bash
check=`tail -n 2 /home/cassandra/opscenter/conf/opscenterd.conf | grep orbited`
if [ -z $check ]; then
  echo "[labs]" >> /home/cassandra/opscenter/conf/opscenterd.conf
  echo "orbited_longpoll = true" >> /home/cassandra/opscenter/conf/opscenterd.conf
fi
cd /home/cassandra/opscenter
nohup bin/opscenter &

