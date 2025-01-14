#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"

# Function to create file list for Jasmine
create_file_list() {
    local dataset=$1
    local list_file=$2
    local input_dir="$WORKDIR/$dataset/input_vcf"
    
    # Clear existing file if it exists
    > "$list_file"
    
    # Add only the 4 specific VCF files to the list
    echo "$input_dir/cutesv.vcf" >> "$list_file"
    echo "$input_dir/pbsv.vcf" >> "$list_file"
    echo "$input_dir/sniffles.vcf" >> "$list_file"
    echo "$input_dir/svim.vcf" >> "$list_file"
}

# Function to run Jasmine merge with parameters
run_jasmine_merge() {
    local list_file=$1
    local min_support=$2
    local output_file=$3
    local out_dir=$(dirname "$output_file")
    
    jasmine \
        file_list="$list_file" \
        out_file="$output_file" \
        min_support="$min_support" \
        out_dir="$out_dir" \
        threads=4 \
        --normalize_type
}

# Process each dataset
process_dataset() {
    local dataset=$1
    local temp_list="$WORKDIR/$dataset/jasmine_4callers_files.txt"
    
    echo "Processing $dataset with 4 callers"
    
    # Create file list
    create_file_list "$dataset" "$temp_list"
    
    # Union analysis (at least 1 caller must support)
    output_dir="$WORKDIR/$dataset/union/jasmine_4callers"
    mkdir -p "$output_dir"
    output_file="$output_dir/merged_union.vcf"
    run_jasmine_merge "$temp_list" 1 "$output_file"
    
    # Clean up
    rm "$temp_list"
}

# Process only the long-read datasets
for dataset in "visor_ont" "visor_pacbio" "NA12878_pacbio"; do
    echo "Starting processing of $dataset"
    process_dataset "$dataset"
    echo "Finished processing $dataset"
    echo "----------------------------------------"
done

echo "All Jasmine 4-callers union analyses completed"
