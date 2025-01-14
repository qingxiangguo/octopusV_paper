# OctopusV Paper Analysis

This repository contains analysis scripts, benchmarking workflows, and results for the OctopusV paper. OctopusV is a comprehensive toolkit for standardizing and merging structural variant (SV) calls from multiple callers and sequencing platforms.

## Overview

The analysis is organized into three main components:
1. **Truth Set Preparation**: Scripts for processing and formatting ground truth datasets
2. **Correction Benchmarking**: Evaluation of OctopusV's BND correction capabilities
3. **Merging Benchmarking**: Comprehensive comparison of OctopusV's merging functionality against existing tools

## Repository Structure

```
octopusV_paper/
├── scripts/
│   ├── truth_set_preparation/     # Scripts for ground truth dataset preparation
│   ├── correct_benchmark/         # BND correction evaluation scripts
│   └── merge_benchmark/           # Merging functionality comparison scripts
└── results/                       # Analysis results and figures
```

## Dependencies

### Software Requirements
- [OctopusV](https://github.com/ylab-hi/octopusV) v1.0.0
- [TentacleSV](https://github.com/ylab-hi/TentacleSV) v1.0.0
- [SURVIVOR](https://github.com/fritzsedlazeck/SURVIVOR) v1.0.7
- [Jasmine](https://github.com/mkirsche/Jasmine) v1.1.5
- [Truvari](https://github.com/ACEnglish/truvari) v3.5.0
- Python ≥ 3.8
  - pandas
  - numpy
  - matplotlib
  - seaborn

### Input Datasets
The analysis utilizes several public datasets:

- **Real Data**
  - NA12878 NIST HG001 HiSeq 300x WGS data
  - NA12878 PacBio SequelII CCS data from GIAB
  - 1000 Genomes Project structural variants (ALL.wgs.mergedSV.v8.20130502)
  - Database of Genomic Variants (NA12878_DGV-2016)

- **Simulation Data**
  - VISOR-simulated NGS, ONT, and PacBio datasets
  - Ground truth variants from dbVAR (nstd137, nstd106)

## Usage

Each analysis component contains numbered scripts that should be run in sequence:

1. **Truth Set Preparation**
   ```bash
   cd scripts/truth_set_preparation
   # Run scripts in numerical order
   ```

2. **Correction Benchmarking**
   ```bash
   cd scripts/correct_benchmark
   # Run scripts in numerical order
   ```

3. **Merging Benchmarking**
   ```bash
   cd scripts/merge_benchmark
   # Run scripts in numerical order
   ```

## Results

The `results/` directory contains:
- Benchmark summary tables
- Performance comparison heatmaps
- Accuracy evaluation plots

## Related Projects

- [OctopusV](https://github.com/ylab-hi/octopusV): Main software package for SV standardization and merging
- [TentacleSV](https://github.com/ylab-hi/TentacleSV): Automated pipeline for end-to-end SV analysis

## Citation

If you use these analysis scripts or results, please cite:
```
[Paper citation placeholder]
```

## License

MIT License

Copyright (c) 2024 Yang Lab @ Northwestern University
