#!/bin/bash

declare -A basch_stats

function initSched() {

  local schedDir=`mktemp -d`

  setnVal $schedDir ntotal 0
  setnVal $schedDir ncompleted 0

  mkdir -p $schedDir/jobcommands
  mkdir -p $schedDir/queued
  mkdir -p $schedDir/running
  mkdir -p $schedDir/completed
  mkdir -p $schedDir/completed_stack
  mkdir -p $schedDir/output

  ( >&2 echo "#Initialized BASCHeduler in $schedDir" )

  echo $schedDir
}

###############################################################################

function getnVal() {
  local schedDir="$1"
  local key="$2"
  cat $schedDir/$key
}

###############################################################################

function setnVal() {
  local schedDir="$1"
  local key="$2"
  local val="$3"
  echo -en "$val" > $schedDir/$key
}

###############################################################################

function queueJob() {
  local schedDir="$1"
  local jobID="$2"
  touch "$schedDir/queued/$jobID"
  local total=`getnVal $schedDir ntotal`

  setnVal $schedDir ntotal $((total+1))

  if [ `expr $total % 100` -eq 0 ]; then
    printStatus $schedDir
  fi  
}

###############################################################################

  # If you need alternative scheduling, this here is what you need to change
function popQueue() {
  local schedDir="$1"
  # An attempt to optimize the jobs (because it hangs when there are many jobs queued)
  ls -U -1 $schedDir/queued | head -n 1
}

###############################################################################

function startJob() {

  local schedDir="$1"
  local jobID="$2"

  rm "$schedDir/queued/$jobID"
  touch "$schedDir/running/$jobID"

}

###############################################################################

function endJob() {

  local schedDir="$1"
  local jobID="$2"
  local rval="$3"

  rm "$schedDir/running/$jobID"
  echo "$rval" > "$schedDir/completed_stack/$jobID"

}

###############################################################################

function runJob() {

  local schedDir="$1"
  local jobID="$2"

  startJob "$schedDir" "$jobID"

  bash "$schedDir/jobcommands/$jobID" > $schedDir/output/$jobID 2>&1 
  local rval=$?

  endJob "$schedDir" "$jobID" "$rval"

}

###############################################################################

function updateCompletedJobs() {
  local schedDir="$1"
  local completed=`getnVal $schedDir ncompleted`
  local new_completed_files=(`ls $schedDir/completed_stack`)
  local new_completed_count=${#new_completed_files[@]}
  setnVal $schedDir ncompleted $((completed + new_completed_count))
  for f in ${new_completed_files[@]}; do
    mv $schedDir/completed_stack/$f $schedDir/completed
  done
}

###############################################################################

function getTotalJobs(){
  getnVal $schedDir ntotal
}

###############################################################################

function getQueuedJobs() {
  local schedDir="$1"
  local total=`getnVal $schedDir ntotal`
  local running=`getRunningJobs $schedDir`
  local completed=`getnVal $schedDir ncompleted`
  echo `expr $total - $running - $completed`
}

###############################################################################

function getRunningJobs() {
  local schedDir="$1"
  ls $schedDir/running | wc -l
}

###############################################################################

function getCompletedJobs() {
#  echo "getCompletedJobs" >&2

  local schedDir="$1"
  getnVal $schedDir ncompleted
}

###############################################################################

function printStatus() {
  local schedDir="$1"
  printf "\r#Queued: %10s, Running %10s, Complete %10s" `getQueuedJobs $schedDir` `getRunningJobs $schedDir` `getCompletedJobs $schedDir`
}

###############################################################################

function runBasch() {
  local schedDir="$1"
  local nProc="$2"
  local nJobs=`getTotalJobs $schedDir`

  while true; do

    updateCompletedJobs $schedDir

    while [ `getRunningJobs $schedDir` -lt $nProc ] && [ `getQueuedJobs $schedDir` -gt 0 ]; do

      local nextJob=`popQueue $schedDir`
      if [ -z "$nextJob" ]; then
        break
      fi
      ( runJob "$schedDir" "$nextJob" & )
      sleep 0.01
    done

    printStatus $schedDir

    if [ `getCompletedJobs $schedDir` -eq $nJobs ]; then
      echo ""
      break;
    fi

    sleep 1
  done

  retval=`find $schedDir/completed -type f | xargs cat | awk '{sum += $0} END {print sum}'`

  echo "#Command output in: $schedDir"
  echo "#Return value: $retval"

  return $retval
}

###############################################################################

function basch() {
 
  local schedDir=`initSched`

  declare -a jobs=("${!1}")
  local nProc="$2"
  
  if [ -z "$nProc" ]; then
      nProc=4
  fi
  
  local jobID=0
  for job in "${jobs[@]}"; do
    let jobID=jobID+1
    echo -e "#!/bin/bash\n$job" > $schedDir/jobcommands/$jobID
    queueJob $schedDir $jobID
  done

  getQueuedJobs $schedDir
  runBasch $schedDir $nProc
  return $?
}

###############################################################################

function baschf() {

  local schedDir=`initSched`

  local jobFile="$1"
  local nProc="$2"
  
  if [ -z "$nProc" ]; then
      nProc=4
  fi

  split -l 1 -d -a 10 $jobFile $schedDir/jobcommands/job.
  while read jobID; do
    queueJob $schedDir $jobID
  done <<<`ls $schedDir/jobcommands/`

  runBasch $schedDir $nProc
  return $?

}
