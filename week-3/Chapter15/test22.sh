#! /bin/bash
# using the tee comand for logging

tempfile=test22file

echo "This is the start of the test" | tee $tempfile
echo "This is a second line of the test" | tee -a $tempfile
echo "This is the end of the test" | tee -a $tempfile
