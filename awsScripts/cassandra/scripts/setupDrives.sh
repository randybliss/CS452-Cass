#!/bin/bash
usage() {
  echo '# Arguments accepted:
#     --useRAID - optional flag (no value)
#'
}
E_BADARGS=65

USE_RAID="no"

# Parse command line parameters
while [[ $# -ge 1 ]]
do
key="$1"
shift

case $key in
    --useRAID)
    USE_RAID="yes"
    ;;
    *)
    echo "unknown argument type $key - exiting"
    usage
    exit $E_BADARGS
    ;;
esac
done

rm /home/cassandra/dataDirs > /dev/null 2>&1
rm /home/cassandra/logDirs > /dev/null 2>&1
lsblk | grep disk >disks
  count=0
  while read line; do
    mount=`echo $line | awk '{print $7}'`
    device=`echo $line | awk '{print $1}'`
    if [ "$mount" != "/" ] && [ "$device" != "xvda" ]; then
      if [ $count -eq 0 ]; then
        mp=/mnt
      else
        mp=/mnt$count
      fi
      sudo mkdir -p $mp > /dev/null 2>&1
      devname=/dev/$device
      sudo mkfs.ext4 $devname
      sudo mount -t ext4 $devname $mp
      echo device: $device - mountPoint: $mp
      let count=$count+1
    fi
  done < disks
  sudo mkdir -p /mnt/cassandra/data
  sudo mkdir -p /mnt/cassandra/logs
  sudo mkdir -p /mnt/cassandra/commitlog
  sudo mkdir -p /mnt/cassandra/saved_caches
  sudo chown -R cassandra:cassandra /mnt/cassandra
  echo "/mnt/cassandra/data" >> /home/cassandra/dataDirs
  echo "/mnt/cassandra/logs" >> /home/cassandra/logDirs
  echo "/mnt/cassandra/commitlog" >> /home/cassandra/commitLogDirs
  echo "/mnt/cassandra/saved_caches" >> /home/cassandra/savedCachesDirs
rm disks > /dev/null 2>&1
sudo mkdir -p /var/log/cassandra; sudo chown -R  cassandra:cassandra /var/log/cassandra
sudo mkdir -p /var/log/spark; sudo chown -R  cassandra:cassandra /var/log/spark
sudo mkdir -p /var/lib/cassandra; sudo chown -R cassandra:cassandra /var/lib/cassandra
