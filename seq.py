# Tools to deal with Sequences

def read_fasta(fname):
    # Modified from my own code at
    # https://github.com/mhulsman/ibidas/blob/677f64a293826d800376a64d1705b97079a0ac60/ibidas/wrappers/fasta.py#L6

    fas  = [];
    seqs = []

    seqid = "";
    seq   = "";

    with open(fname) as fd:
      for line in fd:
          line = line.strip('\n\r');
          if not line or line[0] == ">":
              if seqid:
                  fas.append(seqid);
                  seqs.append(seq.replace(' ',''));
              #fi
              seqid = line[1:];
              seq = "";
              continue;
          #fi
          seq = seq + line;
    #efor

    if seq:
        fas.append(seqid);
        seqs.append(seq.replace(' ',''));
    #fi

    return (fas, seqs)
#edef

###############################################################################

def read_fasta_dict(fname):
  fas, seqs = read_fasta(fname)
  firstpart = [ f.split()[0] for f in fas ]
  return dict(zip(firstpart,zip(fas, seqs)))

###############################################################################
