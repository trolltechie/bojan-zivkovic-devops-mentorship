#! /bin/bash
# testing for the variable after the looping

for test in Alabama Alaska Arkansas California Colorado
do
    echo "The next state is $test"
done
echo "The last state we wisited was $test"
test=Connecticut
echo "Wait, now ve're visiting $test"