#!/usr/bin/env python2

import os;
import ibidas
import json

###############################################################################

def srt2dict(SRT):
  SRTf = SRT.Get(_.bioproject_s, _.biosample_s, _.experiment_s, _.run_s)
  SRT  = SRT.Get(*(SRTf.Names + list(set(SRT.Names) - set(SRTf.Names))))
  biop = SRT.GroupBy(_.bioproject_s)
  bios = biop.GroupBy(_.biosample_s)
  exp  = bios.GroupBy(_.experiment_s)

  JSON_S = ""
  D = {}

  D["bioprojects"] = SRT.bioproject_s.Unique()().tolist()
  D["biosamples"]  = SRT.biosample_s.Unique()().tolist()
  D["experiments"] = SRT.experiment_s.Unique()().tolist()
  D["runs"]        = SRT.run_s.Unique()().tolist()

  bioprojects = {}
  for bioproject_level in zip(*exp()):
    bioproject = {}
    bioproject["id"] = bioproject_level[0]
    biosamples = []
    for biosample_level in zip(*bioproject_level[1:]):
      biosample = {}
      biosample["id"] = biosample_level[0]
      experiments = []
      for experiment_level in zip(*biosample_level[1:]):
        experiment = {}
        experiment["id"] = experiment_level[0]
        runs = []
        for run_level in zip(*experiment_level[1:]):
          run = dict(zip(SRT.Names[3:], run_level))
          runs.append(run)
        #efor
        experiment["runs"] = runs
        experiments.append(runs)
      #efor
      biosample["experiments"] = experiments
      biosamples.append(biosample)
    #efor
    bioproject["biosamples"] = biosamples
    bioprojects[bioproject_level[0]] = bioproject
  #efor
  D["data"] = bioprojects

  return D
#edef

###############################################################################

sraRunTable = os.sys.argv[1];

#######################################################

SRT  = Read(sraRunTable)
DICT = srt2dict(SRT)
JSON = json.dumps(DICT)

print JSON

