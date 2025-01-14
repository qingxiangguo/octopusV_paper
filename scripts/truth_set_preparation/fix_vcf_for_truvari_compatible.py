#!/usr/bin/env python3
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Fix VCF header and format to be Truvari-compatible.")
    parser.add_argument("-i", "--input", required=True, help="Input VCF file")
    parser.add_argument("-o", "--output", required=True, help="Output VCF file")
    args = parser.parse_args()

    # We will:
    # 1) Ensure the fileformat line is present and properly formatted (prefer v4.2).
    # 2) Ensure that we have a GT format line in the header.
    # 3) Ensure FILTER=<ID=PASS> is present.
    # 4) Ensure CHROM line includes FORMAT and SAMPLE columns if missing.
    # 5) Remove duplicate INFO lines if any.
    # 6) Ensure contig lines and other necessary lines are in proper place.
    # Note: We assume the input is a near-VCF file but with some formatting issues.
    #       This script attempts minimal fixes. More complicated cases may require
    #       manual edits or stricter validation.

    # Read entire file
    with open(args.input, 'r') as infile:
        lines = [l.strip('\n') for l in infile]

    header_lines = []
    variant_lines = []
    in_header = True

    # Collect header lines and variant lines separately
    for line in lines:
        if line.startswith("#"):
            header_lines.append(line)
        else:
            in_header = False
            variant_lines.append(line)

    # At this point, header_lines should contain all lines starting with '#'.
    # The last header line should start with '#CHROM'
    # We'll process header lines (those starting with '##') separately from the #CHROM line.
    meta_lines = [l for l in header_lines if l.startswith("##")]
    chrom_line_candidates = [l for l in header_lines if l.startswith("#CHROM")]
    if len(chrom_line_candidates) == 0:
        sys.stderr.write("Error: No #CHROM line found in the input VCF.\n")
        sys.exit(1)
    chrom_line = chrom_line_candidates[-1]  # Ideally there's only one

    # Check if we have a fileformat line
    # If not present, prepend it
    has_fileformat = any(l.startswith("##fileformat=") for l in meta_lines)
    if not has_fileformat:
        # Insert at the top
        meta_lines.insert(0, "##fileformat=VCFv4.2")

    # Ensure we have a FILTER=PASS line
    has_filter_pass = any(l.startswith("##FILTER=<ID=PASS") for l in meta_lines)
    if not has_filter_pass:
        # Add a PASS filter line after fileformat line
        insert_idx = 1
        meta_lines.insert(insert_idx, '##FILTER=<ID=PASS,Description="All filters passed">')

    # Ensure we have a GT format line
    # If FORMAT=GT doesn't exist, add it
    has_gt_format = any("##FORMAT=<ID=GT," in l for l in meta_lines)
    if not has_gt_format:
        # Insert a GT line near the end of meta lines
        # Just before contigs or before chrom line would be fine
        meta_lines.append('##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">')

    # Remove duplicate INFO lines if any. For example, CLNACC is repeated.
    info_lines = {}
    cleaned_meta_lines = []
    for l in meta_lines:
        if l.startswith("##INFO=<ID="):
            # Extract ID
            start = l.find("##INFO=<ID=") + len("##INFO=<ID=")
            end = l.find(",", start)
            info_id = l[start:end]
            if info_id in info_lines:
                # Duplicate line - skip it
                continue
            else:
                info_lines[info_id] = True
                cleaned_meta_lines.append(l)
        else:
            cleaned_meta_lines.append(l)

    meta_lines = cleaned_meta_lines

    # Check the #CHROM line. According to VCF spec, it should have at least
    # #CHROM  POS  ID  REF  ALT  QUAL  FILTER  INFO
    # If we need Truvari to do genotyping comparisons, we also need FORMAT and SAMPLE columns.
    chrom_fields = chrom_line.split('\t')
    # If there's no FORMAT column, add FORMAT and SAMPLE
    # Minimum: #CHROM POS ID REF ALT QUAL FILTER INFO
    # If length < 9, we must add FORMAT and SAMPLE
    if len(chrom_fields) < 9:
        # Add FORMAT and SAMPLE columns
        # Assume at least one sample named 'SAMPLE'
        needed = 9 - len(chrom_fields)
        # If we have exactly 8 columns (#CHROM,POS,ID,REF,ALT,QUAL,FILTER,INFO) => need FORMAT + SAMPLE
        if needed == 1:
            # This would be odd, but add FORMAT and SAMPLE anyway
            chrom_fields.append('FORMAT')
            chrom_fields.append('SAMPLE')
        elif needed == 2:
            chrom_fields.append('FORMAT')
            chrom_fields.append('SAMPLE')
        else:
            # If missing more than 2, something is very off.
            # We'll just ensure at least FORMAT and SAMPLE
            if 'FORMAT' not in chrom_fields:
                chrom_fields.append('FORMAT')
            if len(chrom_fields) < 10: 
                chrom_fields.append('SAMPLE')
    else:
        # Check if FORMAT in line
        if 'FORMAT' not in chrom_fields:
            # Insert FORMAT before any SAMPLE columns if none found
            chrom_fields.append('FORMAT')
            chrom_fields.append('SAMPLE')

        # If FORMAT exists, but no SAMPLE column, add one
        if 'FORMAT' in chrom_fields and (chrom_fields.index('FORMAT') == len(chrom_fields)-1):
            # FORMAT is the last field, add SAMPLE
            chrom_fields.append('SAMPLE')

    fixed_chrom_line = '\t'.join(chrom_fields)

    # Now we have:
    # meta_lines (## lines)
    # fixed_chrom_line (#CHROM line)
    # variant_lines (variants)

    # Also ensure all meta lines start with ##
    # If there's any line that doesn't start with ## (except #CHROM), remove or fix it
    final_meta_lines = [l for l in meta_lines if l.startswith("##")]

    # Output the result
    with open(args.output, 'w') as outfile:
        for l in final_meta_lines:
            outfile.write(l + "\n")
        outfile.write(fixed_chrom_line + "\n")
        for v in variant_lines:
            outfile.write(v + "\n")


if __name__ == "__main__":
    main()

