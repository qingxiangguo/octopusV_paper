#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"

# Function to run union for 4 callers
run_union_4callers() {
    local dataset=$1
    local input_dir="$WORKDIR/$dataset/input_vcf"
    local output_dir="$WORKDIR/$dataset/union/octopusv_4callers"
    
    echo "Running union analysis for $dataset with 4 callers"
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Only use the 4 specific callers
    octopusv merge \
        "$input_dir/cutesv_corrected.svcf" \
        "$input_dir/pbsv_corrected.svcf" \
        "$input_dir/sniffles_corrected.svcf" \
        "$input_dir/svim_corrected.svcf" \
        --union \
        --output-file "$output_dir/merged_union.svcf"
}

# Process only the long-read datasets
for dataset in "visor_ont" "visor_pacbio" "NA12878_pacbio"; do
    echo "Starting processing of $dataset"
    run_union_4callers "$dataset"
    echo "Finished processing $dataset"
    echo "----------------------------------------"
done

echo "All OctopusV 4-callers union analyses completed"
