#!/usr/bin/env python2

import sys

import seq as seq
import vcf as vcf

###############################################################################

def usage(arg0):
  print "Usage: %s <vcf_file> <fa_file> <length>" % arg0
#edef

###############################################################################

if __name__ == "__main__":
  if len(sys.argv) < 4:
    usage(sys.argv[0])
    sys.exit(1)
  #fi

  
  vcf_file = sys.argv[1]
  fa_file  = sys.argv[2]
  length   = int(sys.argv[3])

  variants = vcf.read(vcf_file)
  fa_dict  = seq.read_fasta_dict(fa_file)

  flanks = []
  for var in variants:
    name = "%s|%s|%s" % (var.chrom, var.pos, var.get_info("SSN"))
    ups, downs = var.extract_flanks(fa_dict[var.chrom][1], length)
    print "%s\t%s[%s/%s]%s" % (name, ups, var.ref, var.alt, downs)
    if "%s%s%s" % (ups, var.ref, downs) != var.extract_region(fa_dict[var.chrom][1], length):
      print "ERROR! %s %d" % (var.chrom, var.pos)
      sys.exit(1)
    
  #efor

#fi
