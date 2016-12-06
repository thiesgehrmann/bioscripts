#!/bin/bash

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
DDIR="$3";

if [ -z "$DDIR" ]; then
  DDIR="$DIR"
fi

###############################################################################

run_s_id=`get_field_id $SRT Run_s`
liblayout_id=`get_field_id $SRT LibraryLayout_s`

while read -u10 -r  -a line; do

  if [ "${line[$liblayout_id]}" == 'PAIRED' ]; then
    split="--split-files"
  else
    split=""
  fi

  fastq-dump $split -O "$DDIR" "$DIR/${line[$run_s_id]}.sra"

done 10< <(cat $SRT | tail -n+2)

