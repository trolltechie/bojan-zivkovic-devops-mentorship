#! /bin/bash
# creating a temp file in /tmp

tempfile=$(mktemp -t tmp.XXXXXX)
echo "this is a test file." > $tempfile
echo "This is a second line of the test." >> $tempfile

echo "The temp file is located at: $tempfile"
cat $tempfile
rm -f $tempfile