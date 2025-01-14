#!/bin/bash

WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"
GRCH37_REF="/projects/b1171/qgn1237/1_my_database/GRCh37_hs37d5/hs37d5.fa"

# Create file of files (fof) for SVmerge
create_fof() {
    local input_dir="$WORKDIR/NA12878_pacbio/input_vcf"
    local fof_file="$WORKDIR/NA12878_pacbio/svmerge_4callers_files.txt"
    
    # Clear existing file if it exists
    > "$fof_file"
    
    # Add only the 4 specific callers
    echo "$input_dir/cutesv.vcf" >> "$fof_file"
    echo "$input_dir/pbsv.vcf" >> "$fof_file"
    echo "$input_dir/sniffles.vcf" >> "$fof_file"
    echo "$input_dir/svim.vcf" >> "$fof_file"
    
    echo "$fof_file"
}

# Run SVmerge
run_svmerge() {
    local fof_file=$1
    local output_dir="$WORKDIR/NA12878_pacbio/union/svmerge_4callers"
    
    echo "Running SVmerge for NA12878_pacbio"
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Run SVmerge
    SVmerge \
        --ref "$GRCH37_REF" \
        --fof "$fof_file" \
        --prefix "$output_dir/merged_union"
}

# Main process
echo "Starting SVmerge analysis for NA12878_pacbio with 4 callers"
fof_file=$(create_fof)
run_svmerge "$fof_file"
rm "$fof_file"
echo "SVmerge analysis completed for NA12878_pacbio"
