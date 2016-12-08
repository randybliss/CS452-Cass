#!/bin/bash
usage() {
echo "# Arguments accepted:
#     --tag required  - user tag (usually your initials) - when combined with reference tag uniquely identifies the cluster
#     --reg optional  - region - default=\"us-east-1\"
#     --help optional - request usage info
#"
}

cancel_requests() {
  if [ -f $HOST_DIR/coreRequestIds ]; then
    count=0
    unset list
    for reqid in `cat $HOST_DIR/coreRequestIds`; do
      if [ $count -eq 0 ]; then
        list=$reqid
      fi
      let count=$count+1
      list="$list $reqid"
    done
    aws ec2 cancel-spot-instance-requests --region $REGION --spot-instance-request-ids $list
  fi
}
E_BADARGS=65
KEY_FILE=$HOME/.ssh/tf-dev.pem
if [[ -z $REFERENCE_TAG ]]; then
  REFERENCE_TAG="gencat"
fi
REGION=us-east-1
SCRIPT_DIR=$(dirname $0)
# Parse command line parameters
while [[ $# -ge 1 ]]
do
key="$1"
shift

case $key in
    -t|--tag)
    USER_TAG="$1"
    shift
    ;;
    -r|--ref)
    echo "--ref argument is deprecated - do not use - ignoring"
    shift
    ;;
    --reg)
    REGION="$1"
    shift
    ;;
    --help)
    usage
    exit 1
    ;;
    *)
    echo "unknown argument type $key - exiting"
    usage
    exit $E_BADARGS
    ;;
esac
done

if [ -z "$USER_TAG" ]; then
  echo "Must specify user tag"
  usage
  exit $E_BADARGS
else
  echo "Using user tag: $USER_TAG"
fi

echo Using region: $REGION

HOST_DIR=$SCRIPT_DIR/hosts/CASSANDRA-$USER_TAG-$REFERENCE_TAG

echo Terminating CORE nodes
count=0
unset list
for id in `cat $HOST_DIR/coreInstanceIds`; do
  if [ $count -eq 0 ]; then
    list=$id
  fi
  let count=$count+1
  list="$list $id"
done
result=`aws ec2 terminate-instances --region $REGION --instance-ids $list`
failed=`echo $result | grep "InvalidInstanceID.NotFound"`
if [ "$failed" ]; then
  for instanceId in `cat $HOST_DIR/coreInstanceIds`; do
    aws ec2 terminate-instances --region $REGION --instance-ids $instanceId
  done
fi
cancel_requests
rm -rf $HOST_DIR > /dev/null 2>&1
