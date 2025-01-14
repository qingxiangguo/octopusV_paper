#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"
GRCH38_REF="/projects/b1171/qgn1237/1_my_database/GRCh38_p13/GRCh38.p13.genome.fa"
GRCH37_REF="/projects/b1171/qgn1237/1_my_database/GRCh37_hs37d5/hs37d5.fa"

# Function to preprocess svdss.vcf to handle duplicate IDs
preprocess_svdss() {
    local input_vcf=$1
    local output_vcf="${input_vcf%.vcf}.unique.vcf"
    local counter=1

    # Create temp directory if it doesn't exist
    mkdir -p "$(dirname $input_vcf)/temp"

    echo "Preprocessing svdss.vcf to handle duplicate IDs"

    # Process VCF file: add unique counter to duplicate IDs
    awk '
    BEGIN {counter = 1}
    /^#/ {print; next}
    {
        if ($3 in seen) {
            $3 = $3 "_" counter
            counter++
        }
        seen[$3] = 1
        print
    }' OFS="\t" "$input_vcf" > "$output_vcf"

    echo "$output_vcf"
}

# Function to create file of files (fof) for SVmerge
create_fof() {
    local dataset=$1
    local fof_file=$2
    local input_dir="$WORKDIR/$dataset/input_vcf"
    
    # Clear existing file if it exists
    > "$fof_file"
    
    # For NGS datasets (4 callers)
    if [[ $dataset == *"ngs"* ]]; then
        echo "$input_dir/delly.vcf" >> "$fof_file"
        echo "$input_dir/lumpy.vcf" >> "$fof_file"
        echo "$input_dir/manta.vcf" >> "$fof_file"
        echo "$input_dir/svaba.vcf" >> "$fof_file"
    else
        # For long-read datasets (6 callers)
        echo "$input_dir/cutesv.vcf" >> "$fof_file"
        echo "$input_dir/debreak.vcf" >> "$fof_file"
        echo "$input_dir/pbsv.vcf" >> "$fof_file"
        echo "$input_dir/sniffles.vcf" >> "$fof_file"
        
        # Special handling for svdss.vcf
        local processed_svdss=$(preprocess_svdss "$input_dir/svdss.vcf")
        echo "$processed_svdss" >> "$fof_file"
        
        echo "$input_dir/svim.vcf" >> "$fof_file"
    fi
}

# Function to run SVmerge
run_svmerge() {
    local dataset=$1
    local fof_file=$2
    local output_dir="$WORKDIR/$dataset/union/svmerge"
    local ref_genome
    
    # Select reference genome based on dataset
    if [[ $dataset == NA12878* ]]; then
        ref_genome="$GRCH37_REF"
    else
        ref_genome="$GRCH38_REF"
    fi
    
    echo "Running SVmerge for $dataset"
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Run SVmerge
    SVmerge \
        --ref "$ref_genome" \
        --fof "$fof_file" \
        --prefix "$output_dir/merged_union"
}

# Function to cleanup temporary files
cleanup() {
    local dataset=$1
    local input_dir="$WORKDIR/$dataset/input_vcf"
    
    echo "Cleaning up temporary files for $dataset"
    rm -f "$input_dir/temp"/*.unique.vcf
    rmdir "$input_dir/temp" 2>/dev/null || true
}

# Process each dataset
process_dataset() {
    local dataset=$1
    local temp_fof="$WORKDIR/$dataset/svmerge_files.txt"
    
    echo "Processing $dataset"
    
    # Create file of files
    create_fof "$dataset" "$temp_fof"
    
    # Run SVmerge
    run_svmerge "$dataset" "$temp_fof"
    
    # Clean up
    rm "$temp_fof"
    cleanup "$dataset"
}

# Process all datasets
for dataset in "NA12878_ngs" "NA12878_pacbio" "visor_ngs" "visor_ont" "visor_pacbio"; do
    echo "Starting processing of $dataset"
    process_dataset "$dataset"
    echo "Finished processing $dataset"
    echo "----------------------------------------"
done

echo "All SVmerge analyses completed"
