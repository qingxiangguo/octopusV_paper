#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"

# Define datasets and analysis directories
datasets=("visor_ngs" "visor_ont" "visor_pacbio" "NA12878_ngs" "NA12878_pacbio")
analysis=("intersection" "support_threshold" "union")
tools=("octopusv" "survivor" "jasmine" "truvari")

# Create directory structure for each dataset
for dataset in "${datasets[@]}"; do
    # Create main directories
    mkdir -p "$WORKDIR/$dataset/input_vcf"
    
    # Create analysis directories
    for method in "${analysis[@]}"; do
        for tool in "${tools[@]}"; do
            # Skip truvari for support_threshold and union analysis
            if [ "$tool" = "truvari" ] && [ "$method" != "intersection" ]; then
                continue
            fi
            mkdir -p "$WORKDIR/$dataset/$method/$tool"
        done
    done
    
    # Create evaluation directory with tool-specific subdirectories
    for tool in "${tools[@]}"; do
        # Skip truvari for evaluation of support_threshold and union
        if [ "$tool" = "truvari" ]; then
            mkdir -p "$WORKDIR/$dataset/evaluation/$tool/intersection"
        else
            mkdir -p "$WORKDIR/$dataset/evaluation/$tool"/{intersection,support_threshold,union}
        fi
    done
done

echo "Directory structure created successfully in $WORKDIR"
