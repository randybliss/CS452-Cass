#!/bin/bash
if [ -z "$3" ]
  then
    echo "need 3 arguments.  personId recordId subId"
    exit 1
fi
PID=$1;
RECORD_ID=$2;
SUB_ID=$3;
FILE=p_${1}_${2}_${3}.txt

echo "here is the record you are about to delete"
cqlsh -e "select * from tf.person_journal where entity_id = '$PID' AND record_id = $RECORD_ID AND sub_id = $SUB_ID AND type = 'j' AND subtype = '';"
echo "press any key to continue to write this backup to disk and display the backup file"
read -n1
cqlsh -e "select * from tf.person_journal where entity_id = '$PID' AND record_id = $RECORD_ID AND sub_id = $SUB_ID AND type = 'j' AND subtype = '';" > ./srg/$FILE
ls -al ./srg/$FILE
cat ./srg/$FILE | cut -b 1-120
echo "press any key to delete the records"
read -n1
# delete cell
cqlsh -e "delete from tf.person_journal where entity_id = '$PID' AND record_id = $RECORD_ID AND sub_id = $SUB_ID AND type = 'j' AND subtype = '';"
# delete all this person's views
cqlsh -e "delete from tf.person_view where entity_id = '$PID';"
cqlsh -e "delete from tf.person_card_view where entity_id = '$PID';"
cqlsh -e "delete from tf.person_change_history_view where entity_id = '$PID';"

