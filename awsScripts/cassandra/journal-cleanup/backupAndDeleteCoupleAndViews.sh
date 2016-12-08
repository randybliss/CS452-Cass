#!/bin/bash
COUPLE_ID=$1;
cqlsh -e "select * from tf.couple_journal where entity_id = '$COUPLE_ID';" > ./srg/c_$COUPLE_ID.txt
ls -al srg/c_$COUPLE_ID.txt
cat srg/c_$COUPLE_ID.txt | cut -b 1-120
cqlsh -e "select entity_id,record_id,sub_id,type,subtype from tf.couple_journal where entity_id = '$COUPLE_ID';"
cqlsh -e "select count(*) from tf.couple_view where entity_id = '$COUPLE_ID';"
cqlsh -e "select count(*) from tf.couple_change_history_view where entity_id = '$COUPLE_ID';"
echo "press any key to continue"
read -n1
cqlsh -e "delete from tf.couple_journal where entity_id = '$COUPLE_ID';"
cqlsh -e "delete from tf.couple_view where entity_id = '$COUPLE_ID';"
cqlsh -e "delete from tf.couple_change_history_view where entity_id = '$COUPLE_ID';"