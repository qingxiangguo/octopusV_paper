#!/bin/bash

# Define paths
WORKDIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"
GRCH38_REF="/projects/b1171/qgn1237/1_my_database/GRCh38_p13/GRCh38.p13.genome.fa"
DATASET="visor_pacbio"

# Function to preprocess svdss.vcf to handle duplicate IDs
preprocess_svdss() {
    local input_vcf=$1
    local output_vcf="${input_vcf%.vcf}.unique.vcf"
    echo "Preprocessing svdss.vcf to handle duplicate IDs"
    
    # Create temp directory if it doesn't exist
    mkdir -p "$(dirname $input_vcf)/temp"
    
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

# Create file of files (fof) for SVmerge
echo "Creating file of files for SVmerge"
INPUT_DIR="$WORKDIR/$DATASET/input_vcf"
FOF_FILE="$WORKDIR/$DATASET/svmerge_files.txt"

# Clear existing FOF file if it exists
> "$FOF_FILE"

# Add all caller VCFs to FOF
echo "$INPUT_DIR/cutesv.vcf" >> "$FOF_FILE"
echo "$INPUT_DIR/debreak.vcf" >> "$FOF_FILE"
echo "$INPUT_DIR/pbsv.vcf" >> "$FOF_FILE"
echo "$INPUT_DIR/sniffles.vcf" >> "$FOF_FILE"

# Process SVDSS VCF and add to FOF
PROCESSED_SVDSS=$(preprocess_svdss "$INPUT_DIR/svdss.vcf")
echo "$PROCESSED_SVDSS" >> "$FOF_FILE"

echo "$INPUT_DIR/svim.vcf" >> "$FOF_FILE"

# Create output directory
OUTPUT_DIR="$WORKDIR/$DATASET/union/svmerge"
mkdir -p "$OUTPUT_DIR"

# Run SVmerge
echo "Running SVmerge for $DATASET"
SVmerge \
    --ref "$GRCH38_REF" \
    --fof "$FOF_FILE" \
    --prefix "$OUTPUT_DIR/merged_union"

# Cleanup
echo "Cleaning up temporary files"
rm -f "$INPUT_DIR/temp"/*.unique.vcf
rmdir "$INPUT_DIR/temp" 2>/dev/null || true
rm "$FOF_FILE"

echo "SVmerge analysis completed for $DATASET"
