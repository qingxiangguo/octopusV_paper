#!/bin/bash

# Working directory
WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"

# Function to process files in a directory
process_directory() {
    local dir=$1
    echo "Processing directory: $dir"
    
    # Enter input_vcf directory
    cd "$dir/input_vcf"
    
    # Process each vcf file
    for vcf in *.vcf; do
        if [ -f "$vcf" ]; then
            # Get base name without extension
            base=$(basename "$vcf" .vcf)
            
            echo "Converting $vcf to ${base}_corrected.svcf"
            
            # Run octopusv correct
            octopusv correct \
                -i "$vcf" \
                -o "${base}_corrected.svcf"
        fi
    done
}

# Process each dataset
datasets=("visor_ngs" "visor_ont" "visor_pacbio" "NA12878_ngs" "NA12878_pacbio")

for dataset in "${datasets[@]}"; do
    if [ -d "$WORKDIR/$dataset" ]; then
        echo "Processing dataset: $dataset"
        process_directory "$WORKDIR/$dataset"
    else
        echo "Warning: Directory $WORKDIR/$dataset not found"
    fi
done

echo "All conversions completed"
