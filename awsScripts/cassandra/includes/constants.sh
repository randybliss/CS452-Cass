#!/bin/bash
E_BADARGS=65
CLUSTER_HOST="unknown"
IN_VPC=""
VPC_ENV=""
DEV_ACCOUNT='074150922133'
TEST_ACCOUNT='643055571372'
PROD_ACCOUNT='914248642252'
AMI_SEC_GROUP_NAME='gencat-ami-build'
APP_SEC_GROUP_NAME='gencat-app'
DB_SEC_GROUP_NAME='gencat-cassandra'
DEV_VPC_KEY_NAME='vpc-instance'
AUX_VPC_KEY_NAME='adhoc-tf-dev'
TEST_VPC_KEY_NAME='adhoc-tf-test'
PROD_VPC_KEY_NAME='adhoc-tf-prod'

DEV_VPC_NAME='development-fh5-useast1-primary'
TEST_VPC_NAME='test-fh5-useast1-primary'
PROD_VPC_NAME='prod-fh5-useast1-primary'
DEV_AUX_VPC_NAME='development-fh5-useast1-aux1'
TEST_AUX_VPC_NAME='test-fh5-useast1-aux1'
PROD_AUX_VPC_NAME='prod-fh5-useast1-aux1'

ACCOUNT=${DEV_ACCOUNT}
KEY_NAME=${DEV_VPC_KEY_NAME}
SEC_GROUP_NAME=gencat-cassandra-db-server
VPC_NAME=${DEV_VPC_NAME}
REFERENCE_TAG='GENCAT'
SERVER_DISPLAY_NAME_PREFIX='Cassandra'
MUSER='gencat'