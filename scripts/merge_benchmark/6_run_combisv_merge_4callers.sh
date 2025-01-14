#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"
COMBISV="/home/qgn1237/2_software/combiSV/combiSV2.3.pl"

# Function to run CombiSV merge
run_combisv_merge() {
    local dataset=$1
    local input_dir="$WORKDIR/$dataset/input_vcf"
    local output_dir="$WORKDIR/$dataset/union/combisv"
    local output_prefix="$output_dir/merged_union"
    
    echo "Processing $dataset"
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Run CombiSV with all available supported callers
    perl "$COMBISV" \
        -pbsv "$input_dir/pbsv.vcf" \
        -sniffles "$input_dir/sniffles.vcf" \
        -cutesv "$input_dir/cutesv.vcf" \
        -svim "$input_dir/svim.vcf" \
        -o "$output_prefix" \
        -c 1  # Set minimum coverage to 1 for union analysis
    
    echo "CombiSV merge completed for $dataset"
}

# Process only the long-read datasets
for dataset in "visor_ont" "visor_pacbio" "NA12878_pacbio"; do
    echo "Starting processing of $dataset"
    run_combisv_merge "$dataset"
    echo "Finished processing $dataset"
    echo "----------------------------------------"
done

echo "All CombiSV merge analyses completed"
