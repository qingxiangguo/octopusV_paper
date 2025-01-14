#!/bin/bash

# Set base directory
BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241122_octopusv_correct_benchmark"

# Function to process short-read datasets (NGS)
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
        grep -E "^#|SVTYPE=BND" "${input_vcf}" > "${output_vcf}"
        echo "Processed ${caller} for ${dataset}"
    done
}

# Function to process long-read datasets (PacBio/ONT)
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
        grep -E "^#|SVTYPE=BND" "${input_vcf}" > "${output_vcf}"
        echo "Processed ${caller} for ${dataset}"
    done
}

# Process each dataset
process_short_read_dataset "giab_ngs"
process_short_read_dataset "visor_ngs"
process_long_read_dataset "giab_pacbio"
process_long_read_dataset "visor_ont"
process_long_read_dataset "visor_pacbio"

echo "BND extraction completed for all datasets"
