#! /bin/bash
# using variable to hold the list

list="Alabama Arizona Arkansas Colorado"
list=$list" Connecticut"

for state in $list
do
    echo "Have you ever visited $state?"
done