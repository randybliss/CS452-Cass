#!/bin/bash
usage="# Arguments accepted:
#     --file - required  - file of directory base paths (one per line) that are to be added to a comma separated list
#     --name - optional - directory name that will be appended to the base dir for each list entry
#     --list - optional -  file where list will be written
#"
E_BADARGS=65
KEY_FILE=$HOME/.ssh/tf-dev.pem
if [[ -z $REFERENCE_TAG ]]; then
  REFERENCE_TAG="db"
fi
REGION=us-east-1
SCRIPT_DIR=$(dirname $0)
# Parse command line parameters
while [[ $# > 1 ]]
do
  key="$1"
  shift

  case $key in
      --file)
      file="$1"
      shift
      ;;
      --name)
      DIR_NAME="$1"
      shift
      ;;
      --list)
      LIST_FILE="$1"
      shift
      ;;
      *)
      echo "unknown argument type $key - exiting"
      echo $usage
      exit $E_BADARGS
      ;;
  esac
done

count=0
for basePath in `cat $file`; do
  if [ $count -eq 0 ]; then
    if [ "$DIR_NAME" ]; then
      list=$basePath/$DIR_NAME
    else
      list=$basePath
    fi
  else
    if [ "$DIR_NAME" ]; then
      list=$list,$basePath/$DIR_NAME
    else
      list=$list,$basePath
    fi
  fi
  let count=$count+1
done

echo $list

if [ "$LIST_FILE" ]; then
  echo $list > $LIST_FILE
fi
