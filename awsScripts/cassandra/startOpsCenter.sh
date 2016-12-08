#!/bin/bash
usage() {
echo "# Arguments accepted:
#     --tag - required  - cluster tag which uniquely identifies the cluster
#"
}
E_BADARGS=65
KEY_FILE=$HOME/.ssh/vpc-instance.pem
if [[ -z $REFERENCE_TAG ]]; then
  REFERENCE_TAG="gencat"
fi
REGION=us-east-1
SCRIPT_DIR=$(dirname $0)
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

sshOpsCenter=`cat $HOST_DIR/sshOpsCenter`
ssh $opts cassandra@$sshOpsCenter 'doStartOpsCenter.sh'
echo
echo "Pausing 30 seconds - allow OpsCenter to come online before starting Datastax agents on cluster nodes"
sleep 30s
opsCenterIp=`head -n 1 $HOST_DIR/corePrivateIps`
ssh $opts cassandra@$sshOpsCenter "doStartOpsCenterAgent.sh --stomp $opsCenterIp"

for dns in `cat $HOST_DIR/nonOpsCenterNodes`; do
  ssh $opts cassandra@$dns "doStartOpsCenterAgent.sh --stomp $opsCenterIp"
done

echo
echo
echo "********************SUCCESS*************************"
echo
echo "Browse to the OpsCenter URL: http://$opsCenterIp:8888"
echo
echo "When the 'Welcome to DataStax OpsCenter' dialog appears, click on 'Manage existing cluster' radio button, then click the 'Get Started' button"
echo
echo "   Enter \"$opsCenterIp\" in the 'Enter at least one host/IP in the cluster' field"
echo
echo "   Click on 'add credentials' - enter 'gencat' as the native transport username and 'gencat' as the native transport password'"
echo "     Leave the 'JMX' credentials fields blank"
echo
echo "   Click 'next >>' and wait while OpsCenter connects to the cluster"
echo "    - when the 'install datastax agents' dialog appears, select the 'install agents manually' radio button then click the 'Close' button"
echo
echo "         (The Datastax agents are already installed on the cluster, you won't need to install them manually)"
echo
echo "   Sit back and watch your cluster come up in OpsCenter"
echo
echo "****************************************************"
echo
echo
