#!/bin/bash
PC_ID=$1;
cqlsh -e "select * from tf.parent_child_journal where entity_id = '$PC_ID';" > ./srg/pc_$PC_ID.txt
ls -al srg/c_$PC_ID.txt
cat srg/pc_$PC_ID.txt | cut -b 1-120
cqlsh -e "select entity_id,record_id,sub_id,type,subtype from tf.parent_child_journal where entity_id = '$PC_ID';"
cqlsh -e "select count(*) from tf.parent_child_view where entity_id = '$PC_ID';"
cqlsh -e "select count(*) from tf.parent_child_change_history_view where entity_id = '$PC_ID';"
echo "press any key to continue"
read -n1
cqlsh -e "delete from tf.parent_child_journal where entity_id = '$PC_ID';"
cqlsh -e "delete from tf.parent_child_view where entity_id = '$PC_ID';"
cqlsh -e "delete from tf.parent_child_change_history_view where entity_id = '$PC_ID';"
