#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"

# Function to create file list for SURVIVOR
create_file_list() {
    local dataset=$1
    local list_file=$2
    local input_dir="$WORKDIR/$dataset/input_vcf"
    
    # Clear existing file if it exists
    > "$list_file"
    
    # Add all VCF files to the list
    for vcf in "$input_dir"/*.vcf; do
        echo "$vcf" >> "$list_file"
    done
}

# Function to run SURVIVOR merge with parameters
run_survivor_merge() {
    local list_file=$1
    local min_support=$2
    local output_file=$3
    
    SURVIVOR merge "$list_file" 1000 "$min_support" 1 1 0 30 "$output_file"
}

# Process each dataset
process_dataset() {
    local dataset=$1
    local num_callers=$2
    local temp_list="$WORKDIR/$dataset/survivor_files.txt"
    
    echo "Processing $dataset with $num_callers callers"
    
    # Create file list
    create_file_list "$dataset" "$temp_list"
    
    # Support threshold analysis
    if [ "$num_callers" -eq 4 ]; then
        # For NGS datasets (4 callers)
        for support in 2 3; do
            output_file="$WORKDIR/$dataset/support_threshold/survivor/merged_min${support}.vcf"
            run_survivor_merge "$temp_list" "$support" "$output_file"
        done
    else
        # For long-read datasets (6 callers)
        for support in 2 3 4 5; do
            output_file="$WORKDIR/$dataset/support_threshold/survivor/merged_min${support}.vcf"
            run_survivor_merge "$temp_list" "$support" "$output_file"
        done
    fi
    
    # Intersection analysis (all callers must support)
    output_file="$WORKDIR/$dataset/intersection/survivor/merged_intersection.vcf"
    run_survivor_merge "$temp_list" "$num_callers" "$output_file"
    
    # Union analysis (at least 1 caller must support)
    output_file="$WORKDIR/$dataset/union/survivor/merged_union.vcf"
    run_survivor_merge "$temp_list" 1 "$output_file"
    
    # Clean up
    rm "$temp_list"
}

# Process NGS datasets (4 callers)
for dataset in "visor_ngs" "NA12878_ngs"; do
    process_dataset "$dataset" 4
done

# Process long-read datasets (6 callers)
for dataset in "visor_ont" "visor_pacbio" "NA12878_pacbio"; do
    process_dataset "$dataset" 6
done

echo "All SURVIVOR merge analyses completed"
