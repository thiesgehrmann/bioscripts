#!/bin/sh

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

###############################################################################

function get_field_id() {
  local SRT="$1";
  local field="$2";
  id=`cat $SRT | head -n1 | tr '\t' '\n' | cat -n | grep "$field" | sed -e 's/^[ \t]\+//' | cut -f1`
  echo $((id-1))
}

###############################################################################

SRT="$1"
DIR="$2"

if [ -z "$DIR" ]; then
  DIR="./";
fi

###############################################################################

run_s_id=`get_field_id $SRT Run_s`

while read -u10 -r  -a line; do

  $SCRIPTDIR/ncbi_ascp.sh "$DIR" "${line[$run_s_id]}"

done 10< <(cat $SRT | tail -n+2)

