#!/bin/bash

usage() {
 echo '# Arguments accepted:
#     --tag required  - user tag (usually your initials) - when combined with reference tag uniquely identifies the cluster
#     --nt optional  - node instance type - default="hi1.4xlarge"
#     --bp optional  - master node bid price - default="0.00" which causes the master node to be an"demand" instance
#     --num required  - core nodes qty - # of core nodes to start
#     --sz optional - Storage volume size in Gigabytes - minimum 500 - default 500
#     --az  optional  - availability zone - default="us-east-1e"
#     --dse - optional flag - if present, use datastax enterprise edition - default: use cassandra community edition
#     --zoneCount - optional - number of availability zones to use - default: 1
#     --zoneList - required if --zoneCount is greater than 1 - comma separated list of availability zones (enclose in quotes)
#     --reg optional  - region - default="us-east-1"
#'
}

if [ -z "$HOST_DIR" ]; then
  source ./includes/functions.sh
  echo "HOST_DIR=$HOST_DIR"
fi

if [ ! -f ~/.awssecret ]; then
  if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo "AWS secret key id must be set in AWS_ACCESS_KEY_ID environment variable to run this script"
    exit 1
  fi
  if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "AWS secret key must be set in AWS_SECRET_ACCESS_KEY environment variable to run this script"
    exit 1
  fi
  echo $AWS_ACCESS_KEY_ID > ~/.awssecret
  echo $AWS_SECRET_ACCESS_KEY >> ~/.awssecret
fi

#KEY_NAME="tf-dev"
#KEY_FILE=~/.ssh/$KEY_NAME.pem
if [[ -z $REFERENCE_TAG ]]; then
  REFERENCE_TAG="db"
fi

SCRIPT_DIR=$(dirname $0)
SERVER_PREFIX="TfCassandraCluster"

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
    echo "--ref tag is deprecated - do not use - ignoring"
    shift
    ;;
    --nt)
    INSTANCE_TYPE="$1"
    shift
    ;;
    --bp)
    BID_PRICE="$1"
    shift
    ;;
    --num)
    NODE_COUNT="$1"
    shift
    ;;
    --sz)
    EBS_DISK_SIZE="$1"
    shift
    ;;
    --az)
    AVAILABILITY_ZONE="$1"
    shift
    ;;
    --reg)
    REGION="$1"
    shift
    ;;
    --dse)
    CASSANDRA_EDITION="dse"
    ;;
    --zoneCount)
    ZONE_COUNT="$1"
    shift
    ;;
    --zoneList)
    ZONE_LIST="$1"
    shift
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
fi

CONFIG_DIR=$SCRIPT_DIR/config/CASSANDRA-$USER_TAG-$REFERENCE_TAG
if [ -d $CONFIG_DIR ]; then
  load_cluster_config
else
  mkdir -p $CONFIG_DIR
fi

if [ -z "$INSTANCE_TYPE" ]; then
  if [ "$CONF_CORE_INSTANCE_TYPE" ]; then
    read -p "Node instance type is: $CONF_CORE_INSTANCE_TYPE - do you want to keep it (Y/n)? " answer
    if [ -z "$answer" ] || [[ $answer = [Yy] ]]; then
      INSTANCE_TYPE=$CONF_CORE_INSTANCE_TYPE
    fi
  fi
  if [ -z "$INSTANCE_TYPE" ]; then
    zoneCount=`wc -l $SCRIPT_DIR/helpers/types.txt | awk '/types.txt/ {print $1}'`
    echo "Select node instance type from the following:"
    PS3="(enter selection 1-$zoneCount)? "; select answer in `cat $SCRIPT_DIR/helpers/types.txt`; do
      INSTANCE_TYPE=$answer
      break
    done
  fi
fi
echo $INSTANCE_TYPE > $CONFIG_DIR/CoreNodeInstanceType

while [ -z "$BID_PRICE" ]; do
  if [ "$CONF_CORE_BID_PRICE" ]; then
    read -p "Node bid price (enter '0' for demand instances) [$CONF_CORE_BID_PRICE]: " answer
    if [ -z "$answer" ]; then
      BID_PRICE=$CONF_CORE_BID_PRICE
    else
      BID_PRICE=$answer
    fi
  else
    read -p "Enter node bid price (enter '0' for demand instance): " BID_PRICE
    if [ -z "$BID_PRICE" ]; then
      BID_PRICE=0
    fi
  fi
  PRICE=$BID_PRICE
  validate_price
  if [ "$VALID" == "bad" ]; then
    unset CORE_BID_PRICE
  elif [ "$VALID" == "demand" ]; then
    BID_PRICE=0
  fi
done
echo $BID_PRICE > $CONFIG_DIR/CoreNodeBidPrice

while [ -z "$NODE_COUNT" ]; do
  if [ "$CONF_CORE_SERVER_COUNT" ]; then
    read -p "Enter number of nodes [$CONF_CORE_SERVER_COUNT]: " answer
    if [ -z "$answer" ]; then
      NODE_COUNT=$CONF_CORE_SERVER_COUNT
    else
      NODE_COUNT=$answer
    fi
  else
    read -p "Enter number of nodes: " NODE_COUNT
  fi
done
echo $NODE_COUNT > $CONFIG_DIR/NumCoreNodes

while [ -z "$EBS_DISK_SIZE" ]; do
  read -p "Enter ebs volume size in Gigabytes: " EBS_DISK_SIZE
  if [ $EBS_DISK_SIZE -lt 500 ]; then
    echo "Ebs volume size must be at least 500Gb"
    unset EBS_DISK_SIZE
  fi
done
echo $EBS_DISK_SIZE > $CONFIG_DIR/EbsDiskSize
echo

while [ -z "$ZONE_COUNT" ]; do
  if [ "$CONF_ZONE_COUNT" ]; then
    read -p "Enter number of availability zones where cluster nodes will be created [$CONF_ZONE_COUNT]: " answer
    if [ -z "$answer" ]; then
      ZONE_COUNT=$CONF_ZONE_COUNT
    else
      ZONE_COUNT=$answer
    fi
  else
    read -p "Enter number of availability zones where cluster nodes will be created: " ZONE_COUNT
  fi
  if [ $ZONE_COUNT -lt 1 ] || [ $ZONE_COUNT -gt 3 ]; then
    echo "Number of availability zones must be between 1 and 3"
    unset $ZONE_COUNT
  fi
  unset ZONE_LIST
done
echo $ZONE_COUNT > $CONFIG_DIR/ZoneCount
echo

if [ $ZONE_COUNT -gt 1 ] && [ "$ZONE_LIST" ]; then
  IFS=","
  zoneCount=0
  for zoneItem in $ZONE_LIST; do
    let zoneCount=$zoneCount+1
  done
  unset IFS
  if [ $zoneCount -ne $ZONE_COUNT ]; then
    unset ZONE_LIST
  fi
fi

if [ $ZONE_COUNT -gt 1 ] && [ -z "$ZONE_LIST" ]; then
  zcount=1
  while [ $zcount -le $ZONE_COUNT ]; do
    count=`wc -l $SCRIPT_DIR/helpers/zones.txt | awk '/zones.txt/ {print $1}'`
    echo "Select availability zone $zcount from the following:"
    PS3="(enter selection 1-$count)? "; select answer in `cat $SCRIPT_DIR/helpers/zones.txt`; do
      if [ -z "$ZONE_LIST" ]; then
        ZONE_LIST=$answer
        AVAILABILITY_ZONE=$answer
      else
        ZONE_LIST="$ZONE_LIST $answer"
      fi
      break
    done
    let zcount=$zcount+1
  done
fi

if [ "$ZONE_LIST" ]; then
  echo $ZONE_LIST > $CONFIG_DIR/ZoneList
fi
echo

if [ -z "$REGION" ]; then
  if [ "$CONF_REGION" ]; then
    read -p "Region is: $CONF_REGION - do you want to keep it (Y/n)? " answer
    if [ -z "$answer" ] || [[ $answer = [Yy] ]]; then
      REGION=$CONF_REGION
    fi
  fi
  if [ -z "$REGION" ]; then
    count=`wc -l $SCRIPT_DIR/helpers/regions.txt | awk '/regions.txt/ {print $1}'`
    echo "Select region from the following:"
    PS3="(enter selection 1-$count)? "; select answer in `cat $SCRIPT_DIR/helpers/regions.txt`; do
      REGION=$answer
      break
    done
  fi
fi
echo $REGION > $CONFIG_DIR/Region
echo
if [ -z "$AVAILABILITY_ZONE" ]; then
  if [ "$CONF_AVAILABILITY_ZONE" ]; then
    read -p "Availability zone is: $CONF_AVAILABILITY_ZONE - do you want to keep it (Y/n)? " answer
    if [ -z "$answer" ] || [[ $answer = [Yy] ]]; then
      AVAILABILITY_ZONE=$CONF_AVAILABILITY_ZONE
    fi
  fi
  if [ -z "$AVAILABILITY_ZONE" ]; then
    count=`wc -l $SCRIPT_DIR/helpers/zones.txt | awk '/zones.txt/ {print $1}'`
    echo "Select availability zone from the following:"
    PS3="(enter selection 1-$count)? "; select answer in `cat $SCRIPT_DIR/helpers/zones.txt`; do
      AVAILABILITY_ZONE=$answer
      break
    done
  fi
fi
echo $AVAILABILITY_ZONE > $CONFIG_DIR/AvailabilityZone
echo
echo Configuration settings for $SERVER_PREFIX:$USER_TAG-$REFERENCE_TAG
echo
echo User Tag is: $USER_TAG
echo
echo Node instance type is: `cat $CONFIG_DIR/CoreNodeInstanceType`
echo Node EBS data volume size is ${EBS_DISK_SIZE}GB
echo Node bid price is: `cat $CONFIG_DIR/CoreNodeBidPrice`
echo Number of nodes to start is: `cat $CONFIG_DIR/NumCoreNodes`
echo
echo Region is: `cat $CONFIG_DIR/Region`
echo Availability zone is: `cat $CONFIG_DIR/AvailabilityZone`
echo