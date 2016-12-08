#!/bin/bash
PID=$1;
cqlsh -e "select * from tf.person_journal where entity_id = '$PID';" > ./srg/p_$PID.txt
ls -al srg/p_$PID.txt
cqlsh -e "select entity_id,record_id,sub_id,type,subtype from tf.person_journal where entity_id = '$PID';"
cqlsh -e "select count(*) from tf.person_view where entity_id = '$PID';"
cqlsh -e "select count(*) from tf.person_card_view where entity_id = '$PID';"
cqlsh -e "select count(*) from tf.person_change_history_view where entity_id = '$PID';"
echo "press any key to continue"
read -n1
cqlsh -e "delete from tf.person_journal where entity_id = '$PID';"
cqlsh -e "delete from tf.person_view where entity_id = '$PID';"
cqlsh -e "delete from tf.person_card_view where entity_id = '$PID';"
cqlsh -e "delete from tf.person_change_history_view where entity_id = '$PID';"
