#!/usr/bin/env python2

import os;
from ibidas import *
import json

###############################################################################

def srt2PipelineDict(SRT, dir):

  SRTf = SRT.Get(_.bioproject_s, _.biosample_s, _.sample_name_s, _.sra_sample_s, _.experiment_s, _.run_s)
  SRT  = SRT.Get(*(SRTf.Names + list(set(SRT.Names) - set(SRTf.Names))))
  biop = SRT.GroupBy(_.bioproject_s)
  bios = biop.GroupBy(_.biosample_s)
  exp  = bios.GroupBy(_.experiment_s)

  D = {}

  D["project_list"]     = SRT.bioproject_s.Unique()().tolist()
  D["sample_list"]      = SRT.biosample_s.Unique()().tolist()
  D["experiment_list"]   = SRT.experiment_s.Unique()().tolist()
  D["measurement_list"] = SRT.run_s.Unique()().tolist()
  D["data_types"]       = SRT.platform_s.Unique()().tolist()

  data = []
  for project_level in zip(*exp()):
    project = {}
    project["project_id"]   = project_level[0]
    for sample_level in zip(*project_level[1:]):
      sample = project.copy()
      sample["sample_id"]   = sample_level[0]
      sample["sample_name"] = sample_level[1][0][0]
      for experiment_level in zip(*sample_level[3:]):
        experiment = sample.copy()
        experiment["experiment_id"]   = experiment_level[0]
        for measurement_level in zip(*experiment_level[1:]):
          measurement = experiment.copy()
          measurement_id = measurement_level[0]
          other_values = dict([(x[:-2], elemCast(x,y)) for (x,y) in zip(SRT.Names[-len(measurement_level[1:]):], measurement_level[1:])])
          measurement["measurement_id"] = measurement_id
          print other_values.keys()
          measurement["library_layout"] = other_values["librarylayout"]
          measurement["organism_name"] = other_values["organism"]
          measurement["data_type"] = other_values["platform"]
          measurement["loc"]  = "%s/%s.sra" % (dir, measurement_id)
          if measurement["library_layout"] == "SINGLE":
            measurement["r"] = "%s/%s.fastq" % (dir, measurement_id)
          else:
            measurement["r1"] = "%s/%s_1.fastq" % (dir, measurement_id)
            measurement["r2"] = "%s/%s_2.fastq" % (dir, measurement_id)
          #fi
          data.append(measurement)
        #efor
      #efor
    #efor
  #efor
  D["data"] = data

  return D


#edef

###############################################################################

def elemCast(name, value):

  map = {
    "s": lambda x: x,
    "l": lambda x: int(x),
    "f": lambda x: float(x),
  }

  return map[name[-1]](value)

#edef

###############################################################################

sraRunTable = os.sys.argv[1];
location_dir = os.sys.argv[2];

#######################################################

SRT  = Read(sraRunTable)
DICT = srt2PipelineDict(SRT, location_dir)
JSON = json.dumps(DICT, indent=3, sort_keys=True)

print JSON

