#!/usr/bin/env python2

import os;
from ibidas import *
import json

###############################################################################

def srt2dict(SRT):
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
          measurement = dict(zip(SRT.Names[-len(measurement_level[1:]):], measurement_level[1:]))
          measurement["id"]   = measurement_id
          measurement["type"] = "measurement"
          measurements.append(measurement)
        #efor
        experiment["measurements"] = measurements
        experiments.append(experiment)
      #efor
      sample["experiments"] = experiments
      samples.append(sample)
    #efor
    project["samples"] = samples
    projects.append(project)
  #efor
  D["data"] = projects

  return D
#edef

###############################################################################

sraRunTable = os.sys.argv[1];

#######################################################

SRT  = Read(sraRunTable)
DICT = srt2dict(SRT)
JSON = json.dumps(DICT, indent=3, sort_keys=True)

print JSON

