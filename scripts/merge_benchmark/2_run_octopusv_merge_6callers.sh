#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"

# Function to run merge with min support
run_min_support() {
    local dataset=$1
    local min_support=$2
    local input_dir="$WORKDIR/$dataset/input_vcf"
    local output_dir="$WORKDIR/$dataset/support_threshold/octopusv"
    
    echo "Running min support $min_support analysis for $dataset"
    octopusv merge \
        $(ls $input_dir/*_corrected.svcf) \
        --min-support $min_support \
        --output-file "$output_dir/merged_min${min_support}.svcf"
}

# Function to run intersection
run_intersection() {
    local dataset=$1
    local input_dir="$WORKDIR/$dataset/input_vcf"
    local output_dir="$WORKDIR/$dataset/intersection/octopusv"
    
    echo "Running intersection analysis for $dataset"
    octopusv merge \
        $(ls $input_dir/*_corrected.svcf) \
        --intersect \
        --output-file "$output_dir/merged_intersection.svcf"
}

# Function to run union
run_union() {
    local dataset=$1
    local input_dir="$WORKDIR/$dataset/input_vcf"
    local output_dir="$WORKDIR/$dataset/union/octopusv"
    
    echo "Running union analysis for $dataset"
    octopusv merge \
        $(ls $input_dir/*_corrected.svcf) \
        --union \
        --output-file "$output_dir/merged_union.svcf"
}

# Process NGS datasets (4 callers)
for dataset in "visor_ngs" "NA12878_ngs"; do
    echo "Processing $dataset"
    # Min support analysis
    for support in 2 3; do
        run_min_support "$dataset" "$support"
    done
    
    # Intersection analysis
    run_intersection "$dataset"
    
    # Union analysis
    run_union "$dataset"
done

# Process long-read datasets (6 callers)
for dataset in "visor_ont" "visor_pacbio" "NA12878_pacbio"; do
    echo "Processing $dataset"
    # Min support analysis
    for support in 2 3 4 5; do
        run_min_support "$dataset" "$support"
    done
    
    # Intersection analysis
    run_intersection "$dataset"
    
    # Union analysis
    run_union "$dataset"
done

echo "All octopusv merge analyses completed"
