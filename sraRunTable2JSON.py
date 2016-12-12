#!/usr/bin/env python2

import os;
from ibidas import *
import json

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

def srt2dict(SRT, dir):
  SRTf = SRT.Get(_.bioproject_s, _.biosample_s, _.sample_name_s, _.sra_sample_s, _.experiment_s, _.run_s)
  SRT  = SRT.Get(*(SRTf.Names + list(set(SRT.Names) - set(SRTf.Names))))
  biop = SRT.GroupBy(_.bioproject_s)
  bios = biop.GroupBy(_.biosample_s)
  exp  = bios.GroupBy(_.experiment_s)

  JSON_S = ""
  D = {}

  D["origin"]       = "SRA Run Table"
  D["depth"]        = 4
  D["depth_labels"] = [ "project", "sample", "experiment", "measurement" ]

  D["project_list"]      = SRT.bioproject_s.Unique()().tolist()
  D["sample_list"]       = SRT.biosample_s.Unique()().tolist()
  D["experiment_list"]   = SRT.experiment_s.Unique()().tolist()
  D["measurement_list"]  = SRT.run_s.Unique()().tolist()

  projects = []
  for project_level in zip(*exp()):
    project = {}
    project["id"]   = project_level[0]
    project["type"] = "project"
    samples = []
    for sample_level in zip(*project_level[1:]):
      sample = {}
      sample["id"]   = sample_level[0]
      sample["name"] = sample_level[1][0][0]
      sample["sra_sample_s"] = sample_level[2][0][0]
      sample["type"] = "sample"
      experiments = []
      for experiment_level in zip(*sample_level[3:]):
        experiment = {}
        experiment["id"]   = experiment_level[0]
        experiment["type"] = "experiment"
        measurements = []
        for measurement_level in zip(*experiment_level[1:]):
          measurement_id = measurement_level[0]
          measurement = dict([(x[:-2], elemCast(x,y)) for (x,y) in zip(SRT.Names[-len(measurement_level[1:]):], measurement_level[1:])])
          measurement["id"]   = measurement_id
          measurement["type"] = "measurement"
          measurement["loc"]  = "%s/%s.sra" % (dir, measurement_id)
          if measurement.get("library_layout" == "SINGLE"):
            measurement["r"] = "%s/%s.fastq" % (dir, measurement_id)
          else:
            measurement["r1"] = "%s/%s_1.fastq" % (dir, measurement_id)
            measurement["r2"] = "%s/%s_2.fastq" % (dir, measurement_id)
          fi
          measurements.append(measurement)
        #efor
        experiment["data"] = measurements
        experiments.append(experiment)
      #efor
      sample["data"] = experiments
      samples.append(sample)
    #efor
    project["data"] = samples
    projects.append(project)
  #efor
  D["data"] = projects

  return D
#edef

###############################################################################

sraRunTable = os.sys.argv[1];
location_dir = os.sys.argv[2];

#######################################################

SRT  = Read(sraRunTable)
DICT = srt2dict(SRT, location_dir)
JSON = json.dumps(DICT, indent=3, sort_keys=True)

print JSON

