#!/bin/sh

###############################################################################

output_dir="$1"
shift

if [ -e $1 ]; then
  list=`cat $1`;
else
  list="$@"
fi

aspera_key="`which asperaconnect| rev | cut -d/ -f1 --complement | rev`/../etc/asperaweb_id_dsa.openssh"
aspera_key="`readlink -f $aspera_key`"

if [ ! -e "$aspera_key" ]; then
  echo "ERROR: can't find aspera key"
  exit 1;
fi

###############################################################################

function get_srv_loc() {
  local acc="$1"

  x3="${acc:0:3}"
  x6="${acc:0:6}"

  srv_loc="sra/sra-instant/reads/ByRun/sra/${x3}/${x6}/${acc}/${acc}.sra"

  echo $srv_loc
}

###############################################################################

function download_acc() {

  local acc="$1";
  local odir="$2";
  local key="$3"
  local srv_loc=`get_srv_loc $acc`

  ascp -i $key -k 1 -T -l200m anonftp@ftp.ncbi.nlm.nih.gov:$srv_loc $odir

}

###############################################################################

for acc in $list; do
  echo "$acc -> $output_dir"
  download_acc $acc $output_dir $aspera_key
done



