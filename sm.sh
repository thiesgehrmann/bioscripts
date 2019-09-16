#!/usr/bin/env bash

function error() {
  echo "ERROR: $@" 1>&2
}

function warning() {
  echo "WARNING: $@" 1>&2
}

name="$1"


case "$name" in
  "-l")
    screen -ls
    exit 0
    ;;
  *)
   echo "Attempting to connect to $name"
   ;;
esac

nhits=`screen -ls | tail -n+2 | head -n-1 | cut -d. --complement -f1 | cut -f1 | grep $name | wc -l`

case $nhits in
 1)
   screen -rd $name
   ;;
 0)
   screen -t $name -S $name
   ;;
 *)
  error "Too many screens with similar name"
  screen -ls | grep $name
  exit 1
   ;;
esac
