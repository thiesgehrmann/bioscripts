###############################################################################
# AWK functions to handle VCF file data


###############################################################################

# Check if two VCF arrays, a and b, are the same at the contig, pos, ref and alt locations
# Return 0 if they are the same, 1 otherwise
function isSame(a,b) {
  if (a[1] == b[1] && a[2] == b[2] && a[4] == b[4] && a[5] == b[5]) {
    return 0
  } else{
    return 1
  }
}

###############################################################################
# Convert a VCF info string to a dictionary
# info: info string
# d: The output dictionary

function info_str2dict(info,d) {
  split(info,a,";")
  for (id in a) {
    n = split(a[id],kv,"=")
    if (n == 1) {
      d[kv[1]] = ""
    } else {
      d[kv[1]] = kv[2]
    }
  }
}

###############################################################################
# Convert an info dictionary to a string
# info: info dictionary e.g. produced by info_str2dict

function info_dict2str(info) {
  info_str = ""
  for (id in info) {
    if (info_str != "") {
      info_str = info_str ";"
    }
    if (info[id] == ""){
      info_str = info_str id
    } else {
      info_str = info_str id "=" info[id]
    }
  }
  return info_str
}

###############################################################################
# Filter an VCF line based on the number of fields in an info field
# variant: VCF array (e.g. from str2var)
# field: the name of the field
# len: The length that the field should have

function info_filter_len(variant,field,len) {
  info_str2dict(variant[8],info)
  if (field in info) {
    n = split(info[field],a,",")
    if (n == len){
      return 0
    }
  }
  return 1
}

###############################################################################
# Filter a VCF line based on the value of an info field
# variant: VCF array (e.g. from str2var)
# field: the name of the field
# val: The value the field should have

function info_filter_val(variant,field,val) {
  info_str2dict(variant[8],info)
  if (field in info) {
    if (info[field] == val){
      return 0
    }
  }
  return 1
}

###############################################################################
# Copy a VCF array into another array
# a: VCF array (output from str2var
# b: output array

function copy_variant(a,b) {

  b[1] = a[1]
  b[2] = a[2]
  b[3] = a[3]
  b[4] = a[4]
  b[5] = a[5]
  b[6] = a[6]
  b[7] = a[7]
  b[8] = a[8]

}

###############################################################################
# Merge two info fields
# a,b: info field strings
# output: A string with merged info fields

function merge_info(a,b) {
  # assumes same keys in a and b
  info_str2dict(a,ad)
  info_str2dict(b,bd)
  split("",merged)
  for (id in ad) {
    merged[id] = ad[id] "," bd[id]
  }
  return info_dict2str(merged)
}

###############################################################################
# Merge two variants
# a,b: vcf variants (output from str2var)
# o: output VCF line

function merge_variants(a,b,o) {
  o[1] = a[1]
  o[2] = a[2]
  o[3] = a[3] ";" b[3]
  o[4] = a[4]
  o[5] = a[5]
  o[6] = (a[6] + a[7]) / 2
  o[7] = a[7] ";" b[7]
  o[8] = merge_info(a[8],b[8])

  # Sort the SN array, this is important for later...

  info_str2dict(o[8],info)
  if ("SN" in info) {
    split(info["SN"],sn,",")
    asort(sn,sns)
    rs = ""
    for (i in sns) {
      if (rs != "") {
        rs = rs ","
      }
      rs = rs sns[i]
    }
    #print "sorting: " info["SN"] | "cat 1>&2"
    #print "sorted:  " rs | "cat 1>&2"
    info["SSN"] = rs
  }
  o[8] = info_dict2str(info)
}

###############################################################################
# Add an info value to a VCF line
# var: VCF line (from str2vcf)
# k: the field name
# v: the field value

function addInfo(var,k,v) {
  info_str2dict(var[8],d)
  d[k] = v
  var[8] = info_dict2str(d)
}

###############################################################################
# Put a dummy VCF array into array a (e.g. to start a loop)

function emptyVCF(a) {
  a[1] = "contig"
  a[2] = "position"
  a[3] = "sampleid"
  a[4] = "ref"
  a[5] = "alt"
  a[6] = "qual"
  a[7] = "filter"
  a[8] = "info"
}

###############################################################################
# Add a VCF line to an index of VCF lines, indexed by contig and position values
# I: An index (if calling for the first time, an empty array is ok)
# line: a vcf line

function addToIndex(I,line) {
  str2var(line,variant)
  I[variant[1] ";" variant[2]] = line
}

###############################################################################
# Convert a VCF line into a VCF array
# s: VCF line string
# a: output VCF array

function str2var(s,a) {
  split(s,a,"\t")
}

###############################################################################
# Convery a VCF array into a VCF line string
# a: VCF array
# output: VCF line String

function var2str(a) {
  return a[1] "\t" a[2] "\t" a[3] "\t" a[4] "\t" a[5] "\t" a[6] "\t" a[7] "\t" a[8] "\t"
}
