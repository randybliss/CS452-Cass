#!/bin/bash
export JAVA_HOME=`cat /home/cassandra/javaHome`
export DSE_HOME=/home/cassandra/dse
cd $DSE_HOME
bin/dse cassandra
