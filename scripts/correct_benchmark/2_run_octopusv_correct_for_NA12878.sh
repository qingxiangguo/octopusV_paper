#!/bin/bash

# Set base directory
BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241122_octopusv_correct_benchmark"

# Function to process short-read dataset (NGS)
process_short_read_dataset() {
    dataset=$1
    echo "Processing ${dataset}..."
    
    # Create directory for corrected VCFs if it doesn't exist
    mkdir -p "${BASE_DIR}/${dataset}/corrected"
    
    # Process each caller's BND VCF
    for caller in delly lumpy manta svaba; do
        input_vcf="${BASE_DIR}/${dataset}/bnd_vcfs/${caller}_bnd.vcf"
        output_vcf="${BASE_DIR}/${dataset}/corrected/${caller}_corrected.svcf"
        
        echo "Running octopusv correct on ${caller} for ${dataset}"
        
        # Run octopusv correct with default position tolerance (3)
        octopusv correct "${input_vcf}" "${output_vcf}"
        
        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "Successfully processed ${caller} for ${dataset}"
        else
            echo "Error processing ${caller} for ${dataset}"
        fi
    done
}

# Function to process long-read dataset (PacBio)
process_long_read_dataset() {
    dataset=$1
    echo "Processing ${dataset}..."
    
    # Create directory for corrected VCFs if it doesn't exist
    mkdir -p "${BASE_DIR}/${dataset}/corrected"
    
    # Process each caller's BND VCF
    for caller in cutesv pbsv sniffles svim; do
        input_vcf="${BASE_DIR}/${dataset}/bnd_vcfs/${caller}_bnd.vcf"
        output_vcf="${BASE_DIR}/${dataset}/corrected/${caller}_corrected.svcf"
        
        echo "Running octopusv correct on ${caller} for ${dataset}"
        
        # Run octopusv correct with default position tolerance (3)
        octopusv correct "${input_vcf}" "${output_vcf}"
        
        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "Successfully processed ${caller} for ${dataset}"
        else
            echo "Error processing ${caller} for ${dataset}"
        fi
    done
}

# Process NA12878 datasets
echo "Starting octopusV correct process for NA12878 datasets..."

process_short_read_dataset "NA12878_ngs"
process_long_read_dataset "NA12878_pacbio"

echo "octopusV correct completed for NA12878 datasets"
