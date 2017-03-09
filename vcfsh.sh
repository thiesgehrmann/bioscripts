
###############################################################################

VCFSH_INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

function vcf_set_col_val() {

  local col=$1
  local val=$2

  awk -v col="$col" -v val="$val" '{
    if (substr($0,1,1) == "#") {
      print $0
    } else {
      for (i=1; i <= NF; i++) {
        if (i == col) {
          printf "%s", val
        } else {
          printf "%s", $i
        }
        printf "\t"
      }
      printf "\n"
    }
   }'
}

###############################################################################

function vcf_add_info() {

  local name="$1"
  local val="$2"

  awk -v name="$name" -v val="$val"  -v sd="$VCFSH_INSTALL_DIR" '
    @include sd "/vcfsh.awk"
  {
    if (substr($0,1,1) == "#") {
      print $0
    } else {
      str2var($0,variant)
      addInfo(variant,name,val)
      print var2str(variant)
    }

  }'

}

###############################################################################

function vcf_count_info_feature(){
  tr '\t' '\n' \
  | tr ';' '\n' \
  | grep -e "^$1" \
  | cut -d= -f2 \
  | sort \
  | uniq -c \
  | sed -e 's/^[ ]\+//' \
  | tr ' ' '\t' \
  | sort -k1,1n
}

###############################################################################

function vcf_merge_same() {

  sort -rk1 -k2 -k4 -k5 \
  | uniq \
  | awk -F $'\t' -v sd="$VCFSH_INSTALL_DIR" '
   @include sd "/vcfsh.awk"

   BEGIN{
     OFS = FS
     emptyVCF(current)
   }
   {

     if (substr($0,1,1) == "#") {
       print $0
     } else {
       str2var($0,current)
       if (isSame(current,prev) == 0){
         merge_variants(prev,current,new)
         copy_variant(new,prev)
       } else {
         if (prev[1] != "contig"){
           print var2str(prev)
         }
         copy_variant(current,prev)
       }
     }

   }'

}

###############################################################################

function vcf_filter_info_length() {

  local field="$1"
  local len="$2"

  awk -v field="$field" -v len="$len" -v sd="$VCFSH_INSTALL_DIR" '
    @include sd "/vcfsh.awk"
    {
    if (substr($0,1,1) == "#") {
      print $0
    } else {
      str2var($0,var)
      if (info_filter_len(var,field,len) == 0){
        print $0
      }
    }
  }'

}

###############################################################################

function vcf_filter_info_value() {
  local field="$1"
  local val="$2"

  awk -v field="$field" -v val="$val" -v sd="$VCFSH_INSTALL_DIR" '
    @include sd "/vcfsh.awk"
    {
    if (substr($0,1,1) == "#") {
      print $0
    } else {
      str2var($0,var)
      if (info_filter_val(var,field,val) == 0){
        print $0
      }
    }
  }'
}

function vcf_filter_info() {

  local func="$1"
  local field="$2"
  local val="$3"

  awk -v func="func" -v field="$field" -v val="$val" -v sd="$VCFSH_INSTALL_DIR" '
    @include sd "/vcfsh.awk"
    {
    if (substr($0,1,1) == "#") {
      print $0
    } else {
      str2var($0,var)
      if (@func(var,field,val) == 0){
        print $0
      }
    }
  }'


}

###############################################################################

function vcf_diff() {

  # Find vars in TWO that are not in ONE

  local one="$1"
  local two="$2"

  awk -F $'\t' -v sd="$VCFSH_INSTALL_DIR" '
   @include sd "/vcfsh.awk"
   BEGIN{
     OFS = FS
     emptyVCF(current)
     split("",vcfindex)
   }
   {
     if (substr($0,1,1) == "#") {
       print $0
     } else if (FNR == NR) {
       addToIndex(vcfindex,$0)
     } else { #NOW WE ARE IN SECOND FILE!
       str2var($0,var)
       key = var[1] ";" var[2]
       if (! (key in vcfindex)) {
         print $0
       } else {
         print "#########################################"
         print "#---PRESENT IN BOTH (next two lines)"
         print "#---" $0
         print "#---" vcfindex[key]
         print "#########################################"
       }
     }
   }
  ' $one $two

}

