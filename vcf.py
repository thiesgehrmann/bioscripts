class vcfVar(object):
  def __init__(self, line):
    split = line.split("\t")
    self.chrom    = split[0]
    self.pos      = int(split[1])
    self.id       = split[2]
    self.ref      = split[3]
    self.alt      = split[4]
    self.qual     = split[5]
    self.filter   = split[6]
    self.info_str = split[7]
    self.info     = -1

  #############################################################################

  def get_info_dict(self):
    if self.info == -1:
      self.parse_info()
    return self.info

  #############################################################################

  def parse_info(self):
    split = self.info_str.split(";")
    self.info = {}
    for i in split:
      split_kv = i.split("=")
      if len(split_kv) == 1:
        self.info[split_kv[0]] = ""
      else:
        self.info[split_kv[0]] = split_kv[1]
      #fi

  #############################################################################

  def get_info(self, key):
    return self.get_info_dict().get(key, "")
  #edef

  #############################################################################

  def extract_flanks(self, refseq, length):
    ups   = refseq[self.pos-length:self.pos-1]
    downs = refseq[self.pos:self.pos+length]
    return (ups, downs)
  #edef

  #############################################################################

  def extract_region(self, refseq, length):
    return refseq[self.pos-length:self.pos+length]

  #############################################################################

#eclass

###############################################################################

def read(vcf_file):
  variants = []
  with open(vcf_file, "r") as fd:
    for line in fd:
      if len(line) == 0 or line[0] == "#":
        continue
      #fi
      variants.append(vcfVar(line))
    #efor
  #ewith
  return variants
#edef

###############################################################################
