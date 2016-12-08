#!/bin/bash
usage() {
  echo '# Arguments accepted:
#     --stomp - required - ip address of cluster node where OpsCenter is running
#'
}
E_BADARGS=65

# Parse command line parameters
while [[ $# -ge 1 ]]
do
key="$1"
shift

case $key in
    --stomp)
    STOMP_INTERFACE="$1"
    shift
    ;;
    *)
    echo "unknown argument type $key - exiting"
    usage
    exit $E_BADARGS
    ;;
esac
done

if [ -z "$STOMP_INTERFACE" ]; then
  echo "--stomp argument (ip address where OpsCenter is running) must be provided"
  usage
  exit $E_BADARGS
fi


export JAVA_HOME=`cat /home/cassandra/javaHome`
export CASSANDRA_BASE=/home/cassandra
export PATH=/home/cassandra/dse/bin:$PATH
export DS_AGENT_HOME=/home/cassandra/datastax-agent
DSE_AGENT_CONF=$DS_AGENT_HOME/conf
rm $DSE_AGENT_CONF/address.yaml >/dev/null 2>&1
echo "stomp_interface: $STOMP_INTERFACE" > $DSE_AGENT_CONF/address.yaml
echo "local_interface: `head -n 1 /home/cassandra/myIpAddress`" >> $DSE_AGENT_CONF/address.yaml
echo "jmx_port: 7199" >> $DSE_AGENT_CONF/address.yaml
echo "cassandra-conf: /home/cassandra/dse/resources/cassandra/conf/cassandra.yaml" >> $DSE_AGENT_CONF/address.yaml
echo "cassandra_user: cassandra" >> $DSE_AGENT_CONF/address.yaml
echo "cassandra_pass: cassandra" >> $DSE_AGENT_CONF/address.yaml
cd $DS_AGENT_HOME
nohup bin/datastax-agent &
