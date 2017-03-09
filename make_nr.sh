#!/usr/bin/env bash

input="$1"
tmpdir=`mktemp -d`

cd-hit-est -i "$input" -o "$tmpdir/clust" -c 0.7 -n4 -d 0 -M 16000 -T 8
echo $tmpdir
