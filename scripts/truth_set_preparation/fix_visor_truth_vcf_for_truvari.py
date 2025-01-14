#!/usr/bin/env python3

import sys

def fix_header(line):
    """Fix the header line by adding FORMAT and SAMPLE columns"""
    if line.startswith('#CHROM'):
        return line.strip() + "\tFORMAT\tSAMPLE\n"
    return line

def fix_content(line):
    """Fix content lines by adding GT format field"""
    # Add GT:1/1 for structural variants
    return line.strip() + "\tGT\t1/1\n"

def main():
    with open('visor_truth.vcf', 'r') as infile, \
         open('visor_truth_fixed_truvari.vcf', 'w') as outfile:
        
        # Write the additional format header lines
        outfile.write('##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">\n')
        
        for line in infile:
            if line.startswith('#'):
                outfile.write(fix_header(line))
            else:
                outfile.write(fix_content(line))

if __name__ == "__main__":
    main()
