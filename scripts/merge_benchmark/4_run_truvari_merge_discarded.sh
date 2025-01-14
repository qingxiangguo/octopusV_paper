#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"

# Function to run truvari consistency
run_truvari_consistency() {
    local dataset=$1
    local input_dir="$WORKDIR/$dataset/input_vcf"
    local output_dir="$WORKDIR/$dataset/intersection/truvari"
    local vcfs=("$input_dir"/*.vcf)
    
    echo "Processing $dataset"
    
    # Run truvari consistency and capture both stdout and stderr
    truvari consistency "${vcfs[@]}" \
        > "$output_dir/merged_intersection.vcf" \
        2> "$output_dir/consistency_report.txt"
    
    # Save json report
    truvari consistency -j "${vcfs[@]}" \
        > "$output_dir/consistency_report.json" \
        2>/dev/null
}

# Process all datasets
datasets=("visor_ngs" "visor_ont" "visor_pacbio" "NA12878_ngs" "NA12878_pacbio")

for dataset in "${datasets[@]}"; do
    run_truvari_consistency "$dataset"
done

echo "All Truvari consistency analyses completed"
