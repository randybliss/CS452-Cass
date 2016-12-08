#!/bin/bash
usage() {
  echo '# Arguments accepted:
#     --tag required  - cluster tag (usually your initials) - uniquely identifies the cluster
#'
}
E_BADARGS=65
if [ -z "$HOST_DIR" ]; then
  source ./includes/functions.sh
  echo "HOST_DIR=$HOST_DIR"
fi

if [[ -z $REFERENCE_TAG ]]; then
  REFERENCE_TAG="db"
fi
REGION=us-east-1
# Parse command line parameters
while [[ $# > 1 ]]
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
    *)
    echo "unknown argument type $key - exiting"
    echo $usage
    exit $E_BADARGS
    ;;
esac
done

if [ -z "$USER_TAG" ]; then
  echo "Must specify user tag"
  exit $E_BADARGS
else
  echo "Using user tag: $USER_TAG"
fi

CONFIG_ROOT=$SCRIPT_DIR/cassandraConf-$USER_TAG-$REFERENCE_TAG
CONFIG_DIR=$CONFIG_ROOT/cassandraConfig

rm -r -f $CONFIG_ROOT > /dev/null
mkdir -p $CONFIG_ROOT
sshCoreNode=`head -n 1 $HOST_DIR/sshCoreIps`
sshOpsCenter=`cat $HOST_DIR/sshOpsCenter`
opsCenterNodePrivateIp=`head -n 1 $HOST_DIR/corePrivateIps`
seedNode1=`head -n 1 $HOST_DIR/seedNodePrivateIps`
seedNode2=`tail -n 1 $HOST_DIR/seedNodePrivateIps`
seedList="$seedNode1,$seedNode2"
awsAccessKeyId=`head -n 1 ~/.awssecret | tr -d '\n' | tr -d '\r'`
awsSecretKey=`tail -n 1 ~/.awssecret | tr -d '\n' | tr -d '\r'`
opts="-i $KEY_FILE -o StrictHostKeyChecking=no"
ssh $opts cassandra@$sshCoreNode 'cat /home/cassandra/dataDirs' > coreDataDirs
ssh $opts cassandra@$sshCoreNode 'cat /home/cassandra/logDirs' > coreLogDirs
ssh $opts cassandra@$sshCoreNode 'cat /home/cassandra/commitLogDirs' > commitLogDirs
ssh $opts cassandra@$sshCoreNode 'cat /home/cassandra/savedCachesDirs' > savedCachesDirs
dataDirsList=`$SCRIPT_DIR/helpers/makeDirList.sh --file coreDataDirs`
commitLogList=`$SCRIPT_DIR/helpers/makeDirList.sh --file commitLogDirs`
savedCachesList=`$SCRIPT_DIR/helpers/makeDirList.sh --file savedCachesDirs`

echo Data dirs: $dataDirsList
echo Commit log dirs: $commitLogList
echo Saved caches dirs: $savedCachesList

ssh $opts cassandra@$sshCoreNode 'cat /home/cassandra/cassandraEdition' > cassandraEdition
cassandraEdition=`head -n 1 cassandraEdition`

rm coreDataDirs
rm coreLogDirs
rm commitLogDirs
rm savedCachesDirs

rm -rf ./cassandraConfig >/dev/null 2>&1
scp $opts -r cassandra@$sshOpsCenter:/home/cassandra/originalConf/ ./cassandraConfig

cp -r ./cassandraConfig $CONFIG_ROOT
rm -rf ./cassandraConfig

#cassandra.yaml
echo building cassandra.yaml template
sed "s/^cluster_name:.*/cluster_name: Gencat-$USER_TAG/" $CONFIG_DIR/cassandra.yaml >cf1
sed "s/.*num_tokens:.*/num_tokens: 24/" cf1 >cf2
sed "s/- seeds:.*/- seeds: $seedList/" cf2 >cf1
sed "s#- /var/lib/cassandra/data#- /mnt/cassandra/data#" cf1 >cf2
sed "s#^commitlog_directory:.*#commitlog_directory: /mnt/cassandra/commitlog#" cf2 >cf1
sed "s#^saved_caches_directory:.*#saved_caches_directory: /mnt/cassandra/saved_caches#" cf1 >cf2
sed "s/^authenticator:.*/authenticator: PasswordAuthenticator/" cf2 >cf1
sed "s/^authorizer:.*/authorizer: CassandraAuthorizer/" cf1 >cf2
sed "s/^row_cache_size_in_mb:.*/row_cache_size_in_mb: 16384/" cf2 >cf1
sed "s/^endpoint_snitch:.*/endpoint_snitch: Ec2Snitch/" cf1 >cf2
cp cf2 $CONFIG_DIR/cassandra.yaml

#echo "concurrent_reads: 128" >> $file
#echo "concurrent_writes: 128" >> $file
#echo "memtable_flush_writers: 16" >> $file
#echo "trickle_fsync: true" >> $file
#echo "concurrent_compactors: 8" >> $file
#echo "compaction_throughput_mb_per_sec: 2048" >> $file
#echo "write_request_timeout_in_ms: 5000" >> $file
#echo "phi_convict_threshold: 12" >> $file
#echo "auto_bootstrap: false" >> $file

#node list for convenience
cat $HOST_DIR/corePrivateDnsNames > $CONFIG_DIR/nodes

echo loading cassandra configuration on all core nodes
cp $CONFIG_DIR/cassandra.yaml cfMaster
count=1
for sshIp in `cat $HOST_DIR/sshCoreIps`; do
  ipcount=1
  for checkip in `cat $HOST_DIR/corePrivateIps`; do
   if [ $ipcount -eq $count ]; then
    sed "s/^listen_address:.*/listen_address: $checkip/" cfMaster >cf1
    sed "s/^rpc_address:.*/rpc_address: 0.0.0.0/" cf1 >cf2
    sed "s/.*broadcast_rpc_address:.*/broadcast_rpc_address: $checkip/" cf2 >cf1
    # For convenience copy current node Ip address and list of nodes to cassandra user home directory
    ssh $opts cassandra@$sshIp "echo $checkip > /home/cassandra/myIpAddress"
    scp $opts $HOST_DIR/corePrivateIps cassandra@$sshIp:/home/cassandra/nodeList
   fi
   let ipcount=$ipcount+1
  done
  cp cf1 cassandra$count.yaml
  scp $opts cassandra$count.yaml cassandra@$sshIp:/home/cassandra/conf/cassandra.yaml
  rm -rf cassandra$count.yaml >/dev/null 2>&1
  let count=$count+1
done
