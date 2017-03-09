function isSame(a,b) {
  if (a[1] == b[1] && a[2] == b[2] && a[4] == b[4] && a[5] == b[5]) {
    return 0
  } else{
    return 1
  }
}

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

function info_filter_val(variant,field,val) {
  info_str2dict(variant[8],info)
  if (field in info) {
    if (info[field] == val){
      return 0
    }
  }
  return 1
}


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

function addInfo(var,k,v) {
  info_str2dict(var[8],d)
  d[k] = v
  var[8] = info_dict2str(d)
}

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

function addToIndex(I,line) {
  str2var(line,variant)
  I[variant[1] ";" variant[2]] = line
}

function str2var(s,a) {
  split(s,a,"\t")
}

function var2str(a) {
  return a[1] "\t" a[2] "\t" a[3] "\t" a[4] "\t" a[5] "\t" a[6] "\t" a[7] "\t" a[8] "\t"
}
