#!/bin/bash

# Set input files and reference genome paths
INPUT1="nstd106.GRCh38.variant_true_call_corrected.vcf"
INPUT2="nstd137.GRCh38.variant_true_call_corrected.vcf"
REF="/projects/b1171/qgn1237/1_my_database/GRCh38_p13/GRCh38.p13.genome.fa"

# 1. Sort VCF files
echo "Step 1: Sorting VCF files..."
bcftools sort $INPUT1 -o nstd106.sorted.vcf
bcftools sort $INPUT2 -o nstd137.sorted.vcf

# 2. Normalize VCF files using reference genome
echo "Step 2: Normalizing VCF files..."
bcftools norm -f $REF nstd106.sorted.vcf -o nstd106.norm.vcf
bcftools norm -f $REF nstd137.sorted.vcf -o nstd137.norm.vcf

# 3. Compress normalized files
echo "Step 3: Compressing normalized files..."
bgzip -f nstd106.norm.vcf
bgzip -f nstd137.norm.vcf

# 4. Index compressed files
echo "Step 4: Indexing compressed files..."
bcftools index nstd106.norm.vcf.gz
bcftools index nstd137.norm.vcf.gz

# 5. Concatenate compressed files
echo "Step 5: Concatenating files..."
bcftools concat -a nstd106.norm.vcf.gz nstd137.norm.vcf.gz -O v -o combined.vcf

# 6. Sort and remove duplicates
echo "Step 6: Sorting and removing duplicates..."
bcftools sort combined.vcf | bcftools norm -d both -o visor_truth.vcf

# 7. Generate statistics
echo "Step 7: Generating statistics..."
bcftools stats visor_truth.vcf > visor_truth.stats

# 8. Get SV type distribution
echo "Step 8: SV type distribution:"
bcftools query -f '%SVTYPE\n' visor_truth.vcf | sort | uniq -c > sv_type_counts.txt

# 9. Print processing results
echo "Original file variant counts:"
echo "nstd106: $(grep -v '^#' $INPUT1 | wc -l)"
echo "nstd137: $(grep -v '^#' $INPUT2 | wc -l)"
echo "Final merged file: $(grep -v '^#' visor_truth.vcf | wc -l)"

echo "SV type distribution:"
cat sv_type_counts.txt

# Clean up intermediate files
echo "Cleaning up intermediate files..."
rm nstd106.sorted.vcf nstd137.sorted.vcf nstd106.norm.vcf.gz nstd137.norm.vcf.gz combined.vcf
rm nstd106.norm.vcf.gz.csi nstd137.norm.vcf.gz.csi

echo "Process completed. Final truth set is in visor_truth.vcf"
echo "Statistics can be found in visor_truth.stats and sv_type_counts.txt"
