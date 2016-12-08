#!/bin/bash
cd $HOME
test=`which yum`
if [ -z "$test" ]; then
  sudo apt-get -y install python-dateutil
fi
wget http://sourceforge.net/projects/s3tools/files/s3cmd/1.5.0-rc1/s3cmd-1.5.0-rc1.tar.gz
tar xzvf s3cmd-1.5.0-rc1.tar.gz
cd s3cmd-1.5.0-rc1/
sudo python setup.py install
cd $HOME
if [ -f ~/.s3cfg ]; then
  exit 0
fi
awsId=`cat .awssecret | head -1`
awsSecret=`cat .awssecret | tail -1`
unset nothing
s3cmd --configure <<EOF
$awsId
$awsSecret
$nothing
$nothing
No
$nothing
n
y
EOF





