#!/usr/bin/env python2

from ibidas import *;
import os;

sraRunTable = os.sys.argv[1];

SRT = Read(sraRunTable);

SRT = SRT.Get(_.bioproject_s, _.biosample_s,  _.organism_s, _.sample_name_s, _.platform_s, _.experiment_s, _.run_s, _.librarylayout_s, _.bioproject_s.Each(lambda x: "./").Cast(str), _.run_s + ".fastq", _.run_s + "_R1.fastq", _.run_s + "_R2.fastq")
SRT = SRT / ("project_id", "sample_id", "organism_name", "sample_name", "data_type", "experiment_id", "measurement_id", "library_layout", "location", "r", "r1", "r2")

Export(SRT, os.sys.argv[2]);

