#!/bin/bash
usage() {
echo "# Arguments accepted:
#     --tag - required  - cluster tag which uniquely identifies the cluster
#"
}
E_BADARGS=65

source ./includes/functions.sh
# Parse command line parameters
while [[ $# > 1 ]]
do
key="$1"
shift

case $key in
    -t|--tag)
    CLUSTER_TAG="$1"
    shift
    ;;
    -r|--ref)
    echo "--ref arg is deprecated - do not use - ignoring"
    shift
    ;;
    *)
    echo "unknown argument type $key - exiting"
    usage
    exit $E_BADARGS
    ;;
esac
done

setup-cassandra-run-environment

if [ -z "$CLUSTER_TAG" ]; then
  echo "Must specify cluster tag"
  usage
  exit $E_BADARGS
else
  echo "Using tag: $CLUSTER_TAG"
fi


echo Using region: $REGION
running="yes"

sshOpsCenter=`head -n 1 $HOST_DIR/sshOpsCenter`
for ip in `cat $HOST_DIR/corePrivateIps`; do
  running=`ssh $opts cassandra@$ip 'ps -ef | grep CassandraDaemon | grep -v grep'`
  if [ "$running" ]; then
    echo "Killing Cassandra on node: $ip"
    ssh $opts cassandra@$ip 'doKillCassandra.sh'
  else
    echo "Cassandra was not running on node: $ip"
  fi
done