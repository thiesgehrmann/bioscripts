#!/bin/bash

function initSched() {

  local schedDir=`mktemp -d`

  mkdir -p $schedDir/jobcommands
  mkdir -p $schedDir/queued
  mkdir -p $schedDir/running
  mkdir -p $schedDir/completed
  mkdir -p $schedDir/output

  ( >&2 echo "#Initialized BASCHeduler in $schedDir" )

  echo $schedDir
}

###############################################################################

function queueJob() {
  local schedDir="$1"
  local jobID="$2"
  touch "$schedDir/queued/$jobID"
}

###############################################################################

  # If you need alternative scheduling, this here is what you need to change
function popQueue() {
  local schedDir="$1"
  echo `ls $schedDir/queued | head -n 1`
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
  echo "$rval" > "$schedDir/completed/$jobID"

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

function getQueuedJobs() {
  local schedDir="$1"
  ls $schedDir/queued | wc -l
}

###############################################################################

function getRunningJobs() {
  local schedDir="$1"
  ls $schedDir/running | wc -l 
}

###############################################################################

function getCompletedJobs() {
  local schedDir="$1"
  ls $schedDir/completed | wc -l
}

###############################################################################

function getJobs() {
  local schedDir="$1"
  ls $schedDir/jobcommands | wc -l
}

###############################################################################

function runBasch() {
  local schedDir="$1"
  local nProc="$2"
  local nJobs=`getJobs $schedDir`

  while true; do

    while [ `getRunningJobs $schedDir` -lt $nProc ] && [ `getQueuedJobs $schedDir` -gt 0 ]; do
      local nextJob=`popQueue $schedDir`
      ( runJob "$schedDir" "$nextJob" & )
      sleep 0.01
    done

    echo -en "\r#Queued: `getQueuedJobs $schedDir`, Running: `getRunningJobs $schedDir`, Completed: `getCompletedJobs $schedDir`"

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
  
  local jobID=0
  for job in "${jobs[@]}"; do
    let jobID=jobID+1
    echo -e "#!/bin/bash\n$job" > $schedDir/jobcommands/$jobID
    queueJob $schedDir $jobID
  done

  runBasch $schedDir $nProc
  return $?
}

###############################################################################

function baschf() {

  local schedDir=`initSched`

  local jobFile="$1"
  local nProc="$2"

  split -l 1 -d -a 5 $jobFile $schedDir/jobcommands/job.
  ls $schedDir/jobcommands/ | while read jobID; do
    queueJob $schedDir $jobID
  done

  runBasch $schedDir $nProc
  return $?

}
