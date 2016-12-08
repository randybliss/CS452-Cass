#!/bin/bash
usage() {
  echo '# Check for proper number of command line args.
# Arguments accepted:
#     --tag - optional - user tag which uniquely identifies your AMI - default="master"
#     --reg - optional - region - default: us-east-1
#     --ami - optional - base AMI - default: Ubuntu 14.04 LTS (ami-018c9568)
#     --dse - optional flag - use datastax enterprise edition - default use community edition
#     --com - optional flag - use community edition - default use community edition
#'
}

source ./includes/functions.sh
E_BADARGS=65
USER_TAG='master'
REFERENCE_TAG='db'
SCRIPT_DIR=$(dirname $0)
BASE_AMI=ami-98aa1cf0
REGION=us-east-1
DATABASE_TYPE=cassandra
CASSANDRA_EDITION=dse
DSE_VERSION="4.7.0"
COMMUNITY_VERSION="2.1.4"
OPS_CENTER_VERSION="5.1.1"

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
    echo "--ref arg is deprecated - do not use - ignoring"
    shift
    ;;
    --reg)
    REGION="$1"
    shift
    ;;
    --ami)
    BASE_AMI="$1"
    shift
    ;;
    --dse)
    CASSANDRA_EDITION="dse"
    ;;
    --com)
    CASSANDRA_EDITION="community"
    ;;
    *)
    echo "unknown argument type $key - exiting"
    usage
    exit $E_BADARGS
    ;;
esac
done

setup-cassandra-run-environment


if [ -z "$USER_TAG" ]; then
  echo "Must specify user tag (usually your initials)"
  exit $E_BADARGS
else
  echo "Using user tag: $USER_TAG"
fi

echo "Cassandra Edition: $CASSANDRA_EDITION"

CODE_BUCKET="tf-migration-code/codesets/$USER_TAG-$REFERENCE_TAG"

if [ "$USER_TAG" == "master" ]; then
  if [ "$CASSANDRA_EDITION" == "dse" ]; then
    AMI_NAME="master-dse-db"
  else
    AMI_NAME="master-db"
  fi
else
  AMI_NAME="$USER_TAG-db"
fi

 dir=`dirname $0`
#determine if ami already exists and delete it
unset ami
echo  ".Images[] | if .Name == \"tf-cassandra-server-image-$AMI_NAME\" then .ImageId else empty end" > ami-filter
ami=`aws ec2 describe-images --region us-east-1 --owners $ACCOUNT | jq -f ami-filter | tr -d '"'`
rm ami-filter
if [[ $ami ]]; then
  echo "AMI already exists - deleting $ami ..."
  echo ".Images[] | if .ImageId == \"$ami\" then .BlockDeviceMappings[0].Ebs.SnapshotId else empty end" > snapshot-filter
  snapshot=`aws ec2 describe-images --region us-east-1 --owners $ACCOUNT | jq -f snapshot-filter | tr -d '"'`
  rm snapshot-filter
  echo "Associated snapshot to be deleted: $snapshot"
  aws ec2 deregister-image --region us-east-1 --image-id $ami
fi
echo "Creating TF webapp server instances from master image ${ami} ..."

if [[ $IN_VPC ]]; then
  unset vpc
  echo ".Vpcs[] | if contains({Tags: [{Key: \"Name\", Value: \"aux\"}]}) then .VpcId else empty end" > vpc-filter
  vpc=`aws ec2 describe-vpcs --region us-east-1 | jq -f vpc-filter | tr -d '"'`
  rm vpc-filter

  unset amiGroup
  aws ec2 describe-security-groups --region us-east-1 >temp-sec-groups
  echo ".SecurityGroups[] | if .GroupName == \"$AMI_SEC_GROUP_NAME\" and .VpcId == \"$vpc\" then .GroupId else empty end" > group-filter
  amiGroup=`cat temp-sec-groups | jq -f group-filter | tr -d '"'`
  rm group-filter
  rm temp-sec-groups

  unset availzones
  echo ".Subnets[] | if .VpcId == \"$vpc\" then .AvailabilityZone + \":\" + .SubnetId else empty end" > subnet-filter
  availzones=`aws ec2 describe-subnets --region us-east-1 | jq -f subnet-filter | tr -d '"'`
  rm subnet-filter

  count=`echo "$availzones" | wc -l | awk '{print $1}'`
  echo "Select availability zone / subnet from the following:"
  PS3="(enter selection 1-${count})? "; select answer in ${availzones}; do
    zonesubnet=(`echo $answer | tr ':' ' '`)
    zone=${zonesubnet[0]}
    subnetId=${zonesubnet[1]}
    unset zonesubnet
    echo "Zone: $zone"
    echo "id: $subnetId"
    break
  done
  SECURITY_GROUP=${amiGroup}
else #NOT in VPC so assume us-east-1d as the availability zone
  SECURITY_GROUP=tf-etl-ami-build
  zone='us-east-1d'
fi

IAM_ROLE=tfAppRole
USER_DATA_FILE=setupScript.sh

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "AWS secret key id must be set in AWS_ACCESS_KEY_ID environment variable to run this script"
  exit 1
fi
if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "AWS secret key must be set in AWS_SECRET_ACCESS_KEY environment variable to run this script"
  exit 1
fi

cat <<EOF > ${USER_DATA_FILE}
#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "initializing" > /home/cassandra/instanceStatus
EOF

cat $SCRIPT_DIR/helpers/cassandraAMIsetupScript.sh >> ${USER_DATA_FILE}

chmod +x ${USER_DATA_FILE}

PARAMS="--region us-east-1"
PARAMS="${PARAMS} --image-id ${BASE_AMI}"
PARAMS="${PARAMS} --count 1"
PARAMS="${PARAMS} --key-name ${KEY_NAME}"
PARAMS="${PARAMS} --user-data file://${USER_DATA_FILE}"
PARAMS="${PARAMS} --instance-type hi1.4xlarge"
if [[ $IN_VPC ]]; then
  PARAMS="${PARAMS} --network-interfaces [{"
  PARAMS="$PARAMS\"DeviceIndex\":0,"
  PARAMS="$PARAMS\"Groups\":[\"$amiGroup\"],"
  PARAMS="$PARAMS\"SubnetId\":\"$subnetId\","
  PARAMS="$PARAMS\"AssociatePublicIpAddress\":true"
  PARAMS="$PARAMS}]"
else
  PARAMS="${PARAMS} --security-groups ${SECURITY_GROUP}"
fi
PARAMS="${PARAMS} --placement AvailabilityZone=${zone}"
PARAMS="$PARAMS --block-device-mappings ["
PARAMS="$PARAMS{\"VirtualName\":\"ephemeral0\","
PARAMS="$PARAMS\"DeviceName\":\"/dev/sdb\"},"
PARAMS="$PARAMS{\"VirtualName\":\"ephemeral1\","
PARAMS="$PARAMS\"DeviceName\":\"/dev/sdc\"},"
PARAMS="$PARAMS{\"VirtualName\":\"ephemeral2\","
PARAMS="$PARAMS\"DeviceName\":\"/dev/sdd\"},"
PARAMS="$PARAMS{\"VirtualName\":\"ephemeral3\","
PARAMS="$PARAMS\"DeviceName\":\"/dev/sde\"}"
PARAMS="$PARAMS]"
#PARAMS="${PARAMS} --iam-profile ${IAM_ROLE}"

echo $PARAMS
info=`aws ec2 run-instances ${PARAMS}`
instanceId=`echo "$info" | jq '.Instances[0].InstanceId' | tr -d '"'`
if [ -z "$instanceId" ]; then
  echo $info
  echo "Unable to create instance - aborting now"
  exit 1
fi
echo "Instance reservation made - instance ID is $instanceId"

rm -f ${USER_DATA_FILE}

created=0
while [ $created -lt 1 ]
do
  echo "PENDING - $created of 1 etl AMI pattern instances created"
  sleep 5s
  echo ".Reservations[] | .Instances[] | if .InstanceId == \"$instanceId\" and .State.Name == \"running\" then .InstanceId  else empty end" > id-filter
  aws ec2 describe-instances --region us-east-1 | jq -f id-filter  | tr -d '"' > test_file
  created=`wc -l test_file | awk '/test_file/ {print $1}'`
done
echo ".Reservations[] | .Instances[] | if .InstanceId == \"$instanceId\" and .State.Name == \"running\" then .PublicDnsName  else empty end" > dns-filter
instanceDNS=`aws ec2 describe-instances --region us-east-1 | jq -f dns-filter | tr -d '"'`
echo ".Reservations[] | .Instances[] | if .InstanceId == \"$instanceId\" and .State.Name == \"running\" then .PublicIpAddress  else empty end" > public-ip-filter
instancePublicIp=`aws ec2 describe-instances --region us-east-1 | jq -f public-ip-filter | tr -d '"'`
echo ".Reservations[] | .Instances[] | if .InstanceId == \"$instanceId\" and .State.Name == \"running\" then .PrivateIpAddress  else empty end" > private-ip-filter
instancePrivateIp=`aws ec2 describe-instances --region us-east-1 | jq -f private-ip-filter | tr -d '"'`
echo "SUCCESS - AMI master instance created instance ID is $instanceId - instance DNS name is $instanceDNS"
echo "InstancePublicIpAddress is $instancePublicIp - InstancePrivateIpAddress is $instancePrivateIp"
rm test_file
rm dns-filter
rm public-ip-filter
rm private-ip-filter

if [ -z "$IN_VPC" ] || [ "$VPC_ENV" == "dev" ]; then
  sshIpAddress=$instancePublicIp
else
  sshIpAddress=$instancePrivateIp
fi

unset test
echo "WAITING for instance setup script to finish"
while [ "$test" != "ready" ]
do
   test=`ssh -i $KEY_FILE -o StrictHostKeyChecking=no ubuntu@$sshIpAddress "cat /home/ubuntu/instanceStatus"`
   echo "Setup script status: ${test}"
   sleep 5s
done
echo "Instance DNS is: $instanceDNS"
opts="-i $KEY_FILE -o StrictHostKeyChecking=no"

#install common scripts (required by all master and slave nodes)
ssh $opts cassandra@$sshIpAddress 'sudo chown -R cassandra:cassandra /usr/local/bin'
#scp $opts $SCRIPT_DIR/scripts/pullConfig.sh cassandra@$sshIpAddress:/usr/local/bin
#scp $opts $SCRIPT_DIR/scripts/propagateConfig.sh cassandra@$sshIpAddress:/usr/local/bin
scp $opts $SCRIPT_DIR/scripts/setupDrives.sh cassandra@$sshIpAddress:/usr/local/bin
scp $opts $SCRIPT_DIR/scripts/doStartCassandra.sh cassandra@$sshIpAddress:/usr/local/bin
ssh $opts cassandra@$sshIpAddress 'ln -s /usr/local/bin/doStartCassandra.sh /usr/local/bin/startCassandra'
scp $opts $SCRIPT_DIR/scripts/doKillCassandra.sh cassandra@$sshIpAddress:/usr/local/bin
ssh $opts cassandra@$sshIpAddress 'ln -s /usr/local/bin/doKillCassandra.sh /usr/local/bin/killCassandra'
scp $opts $SCRIPT_DIR/scripts/doStartOpsCenter.sh cassandra@$sshIpAddress:/usr/local/bin
scp $opts $SCRIPT_DIR/scripts/doStartOpsCenterAgent.sh cassandra@$sshIpAddress:/usr/local/bin
#scp $opts $SCRIPT_DIR/scripts/installGanglia.sh cassandra@$sshIpAddress:/usr/local/bin

#install s3cmd for cassandra user
scp $opts ~/.awssecret cassandra@$sshIpAddress:/home/cassandra
scp $opts $SCRIPT_DIR/scripts/installS3Cmd.sh cassandra@$sshIpAddress:/home/cassandra
ssh $opts cassandra@$sshIpAddress 'chmod +x /home/cassandra/installS3Cmd.sh'
if [ -f ~/.s3cfg ]; then
  scp $opts ~/.s3cfg cassandra@$sshIpAddress:/home/cassandra
fi
ssh $opts cassandra@$sshIpAddress '/home/cassandra/installS3Cmd.sh'
ssh $opts cassandra@$sshIpAddress 'sudo chown -R cassandra:cassandra /usr/local/bin'

#get cassandra binaries from s3 and setup symlinks

echo "installing Cassandra binaries from s3"
if [ "$CASSANDRA_EDITION" == "dse" ]; then
  cassandraVersion="dse-$DSE_VERSION"
  ssh $opts cassandra@$sshIpAddress "s3cmd get s3://tf-migration-code/cassandra/$cassandraVersion-bin.tar.gz /home/cassandra/$cassandraVersion-bin.tar.gz"
  ssh $opts cassandra@$sshIpAddress "tar xzf $cassandraVersion-bin.tar.gz"
  ssh $opts cassandra@$sshIpAddress "mkdir -p /home/cassandra/.versions"
  ssh $opts cassandra@$sshIpAddress "mv $cassandraVersion /home/cassandra/.versions"
  ssh $opts cassandra@$sshIpAddress "chown -R cassandra:cassandra /home/cassandra/.versions"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion dse"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/resources/cassandra cassandraHome"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/resources/cassandra/bin bin"
  ssh $opts cassandra@$sshIpAddress "mkdir -p /home/cassandra/cassandraConfig"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/resources/cassandra/conf conf"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/resources/cassandra/conf originalConf"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/resources/cassandra/lib lib"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/resources/cassandra/tools tools"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/resources/cassandra/pylib pylib"
  ssh $opts cassandra@$sshIpAddress "sudo mkdir -p /mnt/cassandra/logs"
  ssh $opts cassandra@$sshIpAddress "sudo ln -s /mnt/cassandra/logs logs"
  ssh $opts cassandra@$sshIpAddress "sudo chown -R cassandra:cassandra /home/cassandra"
  ssh $opts cassandra@$sshIpAddress "sudo chown -R cassandra:cassandra /usr/local/bin"
  ssh $opts cassandra@$sshIpAddress "echo 'dse' > /home/cassandra/cassandraEdition"
else
  cassandraVersion="dsc-cassandra-$COMMUNITY_VERSION"
  ssh $opts cassandra@$sshIpAddress "s3cmd get s3://tf-migration-code/cassandra/$cassandraVersion-bin.tar.gz /home/cassandra/$cassandraVersion-bin.tar.gz"
  ssh $opts cassandra@$sshIpAddress "tar xzf $cassandraVersion-bin.tar.gz"
  ssh $opts cassandra@$sshIpAddress "mkdir -p /home/cassandra/.versions"
  ssh $opts cassandra@$sshIpAddress "mv $cassandraVersion /home/cassandra/.versions"
  ssh $opts cassandra@$sshIpAddress "chown -R cassandra:cassandra /home/cassandra/.versions"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion dsc"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion cassandraHome"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/bin bin"
  ssh $opts cassandra@$sshIpAddress "mkdir -p /home/cassandra/cassandraConfig"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/conf conf"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/conf originalConf"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/lib lib"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/tools tools"
  ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/.versions/$cassandraVersion/pylib pylib"
  ssh $opts cassandra@$sshIpAddress "sudo mkdir -p /mnt/cassandra/logs"
  ssh $opts cassandra@$sshIpAddress "sudo ln -s /mnt/cassandra/logs logs"
  ssh $opts cassandra@$sshIpAddress "sudo chown -R cassandra:cassandra /home/cassandra"
  ssh $opts cassandra@$sshIpAddress "sudo chown -R cassandra:cassandra /usr/local/bin"
  ssh $opts cassandra@$sshIpAddress "echo 'community' > /home/cassandra/cassandraEdition"
fi
opsCenterVersion="opscenter-$OPS_CENTER_VERSION"

#get opscenter binaries from s3 and setup symlinks
echo "installing Datastax OpsCenter binaries from s3"
ssh $opts cassandra@$sshIpAddress "s3cmd get s3://tf-migration-code/cassandra/$opsCenterVersion.tar.gz /home/cassandra/$opsCenterVersion.tar.gz"
ssh $opts cassandra@$sshIpAddress "tar xzf $opsCenterVersion.tar.gz"
ssh $opts cassandra@$sshIpAddress "ln -s /home/cassandra/$opsCenterVersion opscenter"

#generate ssh keys for master and slave nodes to talk to each other
ssh $opts cassandra@$sshIpAddress 'ssh-keygen -t rsa -P "" -C "id_cassandra" -f  ~/.ssh/id_cassandra'
#scp $opts cassandra@$sshIpAddress:/home/cassandra/.ssh/id_cassandra.pub $SCRIPT_DIR/helpers/id_cassandra.pub
#scp $opts cassandra@$sshIpAddress:/home/cassandra/.ssh/id_cassandra $SCRIPT_DIR/helpers/id_cassandra
ssh $opts cassandra@$sshIpAddress 'cat /home/cassandra/.ssh/id_cassandra.pub >> /home/cassandra/.ssh/authorized_keys'
scp $opts $SCRIPT_DIR/helpers/sshConfig.txt cassandra@$sshIpAddress:/home/cassandra/.ssh/config

ssh $opts cassandra@$sshIpAddress 'rm ~/.awssecret'
ssh $opts cassandra@$sshIpAddress 'rm ~/.s3cfg'

echo "SUCCESS - INSTANCE SETUP COMPLETE"

#make sure existing AMI has been deleted
if [[ $ami ]]; then
  unset test
  echo  ".Images[] | if .ImageId == \"$ami\" then .ImageId else empty end" > ami-id-filter
  test=`aws ec2 describe-images --region us-east-1 --owners $ACCOUNT | jq -f ami-id-filter | tr -d '"'`
  while [[ $test ]]; do
    sleep 5s
    test=`aws ec2 describe-images --region us-east-1 --owners $ACCOUNT | jq -f ami-id-filter | tr -d '"'`
  done
  rm ami-id-filter
  sleep 10s
  aws ec2 delete-snapshot --region us-east-1 --snapshot-id ${snapshot}
fi

#read -p "Pausing for additional instance setup - press enter to continue" answer
echo "Creating AMI image from master instance ..."
aws ec2 create-image --region us-east-1 --instance-id $instanceId --name tf-cassandra-server-image-$AMI_NAME --description "Tree Foundation etl AMI"
unset ami
echo  ".Images[] | if .Name == \"tf-cassandra-server-image-$AMI_NAME\" and .State == \"available\" then .ImageId else empty end" > ami-filter
ami=`aws ec2 describe-images --region us-east-1 --owners $ACCOUNT | jq -f ami-filter | tr -d '"'`
while [[ -z $ami ]]; do
  sleep 5s
  ami=`aws ec2 describe-images --region us-east-1 --owners $ACCOUNT | jq -f ami-filter | tr -d '"'`
done
rm ami-filter
aws ec2 create-tags --region us-east-1 --resources ${ami} --tags Key=Name,Value=TfCassandraServerImage-$AMI_NAME

echo "AMI successfully created - deleting master builder instance - instance ID is $instanceId"
#aws ec2 terminate-instances --region us-east-1 --instance-ids ${instanceId}
rm id-filter
echo ".............and we're done!"

