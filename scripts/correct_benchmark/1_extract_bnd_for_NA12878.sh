#!/bin/bash

# Set base directory
BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241122_octopusv_correct_benchmark"

# Function to process short-read dataset (NGS)
process_short_read_dataset() {
    dataset=$1
    echo "Processing ${dataset}..."
    
    # Create directory for BND VCFs if it doesn't exist
    mkdir -p "${BASE_DIR}/${dataset}/bnd_vcfs"
    
    # Process each caller's VCF
    for caller in delly lumpy manta svaba; do
        input_vcf="${BASE_DIR}/${dataset}/raw_vcfs/${caller}.vcf"
        output_vcf="${BASE_DIR}/${dataset}/bnd_vcfs/${caller}_bnd.vcf"
        
        # Extract BND events using grep
        # Keep header lines (starting with #) and lines containing SVTYPE=BND
        grep -E "^#|SVTYPE=BND" "${input_vcf}" > "${output_vcf}"
        echo "Processed ${caller} for ${dataset}"
    done
}

# Function to process long-read dataset (PacBio)
process_long_read_dataset() {
    dataset=$1
    echo "Processing ${dataset}..."
    
    # Create directory for BND VCFs if it doesn't exist
    mkdir -p "${BASE_DIR}/${dataset}/bnd_vcfs"
    
    # Process each caller's VCF
    for caller in cutesv pbsv sniffles svim; do
        input_vcf="${BASE_DIR}/${dataset}/raw_vcfs/${caller}.vcf"
        output_vcf="${BASE_DIR}/${dataset}/bnd_vcfs/${caller}_bnd.vcf"
        
        # Extract BND events using grep
        # Keep header lines (starting with #) and lines containing SVTYPE=BND
        grep -E "^#|SVTYPE=BND" "${input_vcf}" > "${output_vcf}"
        echo "Processed ${caller} for ${dataset}"
    done
}

# Process NA12878 datasets
process_short_read_dataset "NA12878_ngs"
process_long_read_dataset "NA12878_pacbio"

echo "BND extraction completed for NA12878 datasets"
