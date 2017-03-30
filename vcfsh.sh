
###############################################################################

VCFSH_INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
vcfshawk="$VCFSH_INSTALL_DIR/vcfsh.awk"

export AWKPATH="$VCFSH_INSTALL_DIR:$AWKPATH"

###############################################################################

function vcf_set_col_val() {
# Set a specific column to the same value for all lines in a VCF file

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
# Add a field(name)/value(val) pair to the info field of all lines in a VCF file

function vcf_add_info() {

  local name="$1"
  local val="$2"

  awk -v name="$name" -v val="$val" '
  @include "vcfsh.awk"
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
# Produce a list with the number of times a specific value occurs in an info field

function vcf_count_info_feature(){

  field="$1"

  tr '\t' '\n' \
  | tr ';' '\n' \
  | grep -e "^$field" \
  | cut -d= -f2 \
  | sort \
  | uniq -c \
  | sed -e 's/^[ ]\+//' \
  | tr ' ' '\t' \
  | sort -k1,1n
}

###############################################################################
# Merge entries in a VCF file that are the same locus

function vcf_merge_same() {

  sort -rk1 -k2 -k4 -k5 \
  | uniq \
  | awk -F $'\t' '
   @include "vcfsh.awk"

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
# Filter a VCF file based on the number of values in an info field

function vcf_filter_info_length() {

  local field="$1"
  local lmin="$2"
  local lmax="$3"

  awk -v field="$field" -v lmin="$lmin" -v lmax="$lmax" '
    @include "vcfsh.awk"

    {
    if (substr($0,1,1) == "#") {
      print $0
    } else {
      str2var($0,var)
      nvals = info_field_len(var,field)
      if ((nvals >= lmin) && (nvals <= lmax)){
        print $0
      }
    }
  }'

}

###############################################################################
# Filter a VCF file based on the value of a field in the info field

function vcf_filter_info_value() {
  local field="$1"
  local val="$2"

  awk -v field="$field" -v val="$val" '
    @include "vcfsh.awk"

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

###############################################################################
# Filter a VCF file by an arbitrary function in vcfsh.awk that operates on the info field

function vcf_filter_info() {

  local func="$1"
  local field="$2"
  local val="$3"

  awk -v func="func" -v field="$field" -v val="$val" '
    @include "vcfsh.awk"

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
# Find the values in VCF file two that are not in VCF file one

function vcf_diff() {

  # Find vars in TWO that are not in ONE

  local one="$1"
  local two="$2"

  awk -F $'\t' '
   @include "vcfsh.awk"

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

###############################################################################

function vcf_filter_nearby() {

  local one="$1"
  local two="$2"
  local dist="$3"

  awk -F $'\t' -v dist="$dist" '
   @include "vcfsh.awk"

   BEGIN{
     OFS = FS
     emptyVCF(current)
     split("",vcfindex)
   }
   {
     if (FNR == NR) {
       if (substr($0,1,1) != "#") {
         addToIndex(vcfindex,$0)
       }
     } else if(substr($0,1,1) == "#"){
       print $0
     } else {
       str2var($0,var)
       split("",neighborindex)
       neighbors = 0
       for (d=1; d <= dist; d++){
         keyup   = var[1] ";" (var[2]+d)
         keydown = var[1] ";" (var[2]-d)
         if ( keyup in vcfindex){
           addToIndex(neighborindex,vcfindex[keyup])
           neighbors++
         }
         if ( keydown in vcfindex){
           addToIndex(neighborindex,vcfindex[keydown])
           neighbors++
         }
       }
       if (neighbors == 0){
         print $0
       } else {
         print "########################################"
         print "# " var[1] ";" var[2] " excluded because of these neighbors:"
         for (n in neighborindex) {
           print "#  " neighborindex[n]
         }
         print "########################################"
       }
     }
   }
  ' $one $two

}
