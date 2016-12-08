#!/bin/bash
usage() {
echo "# Arguments accepted:
#     --tag - required  - cluster tag which uniquely identifies the cluster
#     --opsCenter - optional - if 'yes' start opsCenter and agents - allowed values [yes|no]
#"
}
E_BADARGS=65
KEY_FILE=$HOME/.ssh/tf-dev.pem
if [[ -z $REFERENCE_TAG ]]; then
  REFERENCE_TAG="db"
fi
REGION=us-east-1
SCRIPT_DIR=$(dirname $0)
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

if [ -z "$CLUSTER_TAG" ]; then
  echo "Must specify cluster tag"
  usage
  exit $E_BADARGS
else
  echo "Using tag: $CLUSTER_TAG"
fi


echo Using region: $REGION

HOST_DIR=$SCRIPT_DIR/hosts/CASSANDRA-$CLUSTER_TAG-$REFERENCE_TAG
opts="-i $KEY_FILE -o StrictHostKeyChecking=no"
for dns in `cat $HOST_DIR/seedNodes`; do
  echo "Starting Cassandra on seed node: $dns"
  ssh $opts cassandra@$dns 'doStartCassandra.sh'
done
sleep 15s
for dns in `cat $HOST_DIR/nonSeedNodes`; do
  echo "Starting Cassandra on cluster node: $dns"
  ssh $opts cassandra@$dns 'doStartCassandra.sh'
done

if [ "$OPS_CENTER" == "yes" ]; then
  . $SCRIPT_DIR/startOpsCenter.sh
fi
