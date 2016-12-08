#!/bin/bash
usage() {
echo "# Arguments accepted:
#     --tag - required  - cluster tag which uniquely identifies the cluster
#     --opsCenter - optional - if 'yes' start opsCenter and agents - allowed values [yes|no]
#"
}
E_BADARGS=65
if [ -z "$HOST_DIR" ]; then
  source ./includes/functions.sh
  echo "HOST_DIR=$HOST_DIR"
fi

OPS_CENTER="no"
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
    --opsCenter)
    if [ "$1" != "yes" ] && [ "$1" != "no" ]; then
      echo '--opsCenter value must be either "yes" or "no"'
      usage
      exit $E_BADARGS
    fi
    OPS_CENTER="$1"
    shift
    ;;
    *)
    echo "unknown argument type $key - exiting"
    usage
    exit $E_BADARGS
    ;;
esac
done

if [ -z "$HOST_DIR" ]; then
  setup-cassandra-run-environment
fi

if [ -z "$CLUSTER_TAG" ]; then
  echo "Must specify cluster tag"
  usage
  exit $E_BADARGS
else
  echo "Using tag: $CLUSTER_TAG"
fi


echo Using region: $REGION

sshOpsCenter=`head -n 1 $HOST_DIR/sshOpsCenter`
running=`ssh $opts cassandra@$sshOpsCenter 'ps -ef | grep CassandraDaemon | grep -v grep'`
if [ -z "$running" ]; then
  for ip in `cat $HOST_DIR/seedNodes`; do
    echo "Starting Cassandra on seed node: $ip"
    ssh $opts cassandra@$ip 'doStartCassandra.sh'
  done
  sleep 10s
  for ip in `cat $HOST_DIR/nonSeedNodes`; do
    echo "Starting Cassandra on cluster node: $ip"
    ssh $opts cassandra@$ip 'doStartCassandra.sh'
  done

  if [ "$OPS_CENTER" == "yes" ]; then
    . $SCRIPT_DIR/startOpsCenter.sh
  fi
fi

#mvn -f $PROJECT_DIR/webapp/pom.xml -Dddl exec:java | sed -n -e '/AWS Datastax DDL/,/end of ddl/p' | tail -n +2 > $SCRIPT_DIR/gencat-aws-ddl.cql
echo "CREATE USER gencat WITH PASSWORD 'gencat' SUPERUSER;" >$SCRIPT_DIR/gencat-aws-ddl.cql
scp $opts $SCRIPT_DIR/gencat-aws-ddl.cql cassandra@$sshOpsCenter:/home/cassandra/
ssh $opts cassandra@$sshOpsCenter '/home/cassandra/bin/cqlsh -u cassandra -p cassandra -f /home/cassandra/gencat-aws-ddl.cql'
#ssh $opts cassandra@$sshOpsCenter 'rm -rf /home/cassandra/gencat-aws-ddl.cql' > /dev/null 2>&1
rm $SCRIPT_DIR/gencat-aws-ddl.cql >/dev/null 2>&1

#echo "ALTER USER cassandra WITH PASSWORD 'hellomynameisinigomontoyayoukilledmyfatherpreparetodie'" > $SCRIPT_DIR/tf-aws-ddl2.cql
#scp $opts $SCRIPT_DIR/tf-aws-ddl2.cql cassandra@$sshOpsCenter:/home/cassandra/
#ssh $opts cassandra@$sshOpsCenter '/home/cassandra/bin/cqlsh -u cassandra -p cassandra -f /home/cassandra/tf-aws-ddl2.cql'
#ssh $opts cassandra@$sshOpsCenter 'rm -rf /home/cassandra/tf-aws-ddl2.cql' > /dev/null 2>&1
#rm $SCRIPT_DIR/tf-aws-ddl2.cql >/dev/null 2>&1



