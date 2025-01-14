#!/usr/bin/env python3

import argparse
import sys
import os
from datetime import datetime

def create_vcf_header():
    """
    Create a standard VCF header with properly ordered INFO fields
    """
    header = [
        '##fileformat=VCFv4.2',
        f'##fileDate={datetime.now().strftime("%Y%m%d")}',
        '##source=NA12878_ground_truth'
    ]
    
    # Add contig information
    contigs = {
        '1': '249250621', '2': '243199373', '3': '198022430', 
        '4': '191154276', '5': '180915260', '6': '171115067',
        '7': '159138663', '8': '146364022', '9': '141213431',
        '10': '135534747', '11': '135006516', '12': '133851895',
        '13': '115169878', '14': '107349540', '15': '102531392',
        '16': '90354753', '17': '81195210', '18': '78077248',
        '19': '59128983', '20': '63025520', '21': '48129895',
        '22': '51304566', 'X': '155270560', 'Y': '59373566'
    }
    
    for chrom, length in contigs.items():
        header.append(f'##contig=<ID={chrom},length={length}>')
    
    # Define ALT types first
    header.extend([
        '##ALT=<ID=DEL,Description="Deletion">',
        '##ALT=<ID=DUP,Description="Duplication">',
        '##ALT=<ID=INS,Description="Insertion">'
    ])
    
    # Define FILTER
    header.append('##FILTER=<ID=PASS,Description="All filters passed">')
    
    # Define INFO fields in specific order
    header.extend([
        '##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">',
        '##INFO=<ID=SVLEN,Number=1,Type=Integer,Description="Difference in length between REF and ALT alleles">',
        '##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the variant">',
        '##INFO=<ID=SOURCE,Number=1,Type=String,Description="Source of variant">'
    ])
    
    # Define FORMAT
    header.extend([
        '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
        '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tNA12878'
    ])
    
    return header

def process_vcf(input_vcf, output_vcf):
    """
    Process the input VCF file:
    1. Simplify REF field to just "N"
    2. Standardize INFO field format
    """
    
    with open(input_vcf, 'r') as infile, open(output_vcf, 'w') as outfile:
        # Write VCF header
        header = create_vcf_header()
        for line in header:
            outfile.write(line + '\n')
        
        # Process variant lines
        for line in infile:
            if line.startswith('#'):
                continue
                
            fields = line.strip().split('\t')
            chrom, pos, svtype = fields[0], fields[1], fields[2]
            info = fields[7]
            
            # Extract SVLEN from INFO field
            info_dict = dict(item.split('=') for item in info.split(';'))
            svlen = abs(int(info_dict.get('SVLEN', '0')))
            source = info_dict.get('SOURCE', 'UNKNOWN')
            
            # Generate variant ID
            variant_id = f"{svtype}_{chrom}_{pos}"
            
            # Calculate END position
            end_pos = int(pos) + svlen if svtype == 'DEL' else pos
            
            # Simplify REF field - always use "N"
            ref = 'N'
            
            # Set ALT based on SVTYPE
            alt = f'<{svtype}>'
            
            # Create standardized INFO field with controlled order
            new_info = f"SVTYPE={svtype};SVLEN={svlen};END={end_pos};SOURCE={source}"
            
            # Create new line with all required fields
            new_fields = [
                chrom,          # CHROM
                pos,            # POS
                variant_id,     # ID
                ref,           # REF
                alt,           # ALT
                '.',           # QUAL
                'PASS',        # FILTER
                new_info,      # INFO
                'GT',          # FORMAT
                '1/1'          # Sample GT
            ]
            
            outfile.write('\t'.join(new_fields) + '\n')

def main():
    parser = argparse.ArgumentParser(description='Format NA12878 ground truth VCF file for Truvari compatibility')
    parser.add_argument('-i', '--input', required=True, help='Input VCF file')
    parser.add_argument('-o', '--output', help='Output VCF file')
    
    args = parser.parse_args()
    
    if not args.output:
        base = os.path.splitext(args.input)[0]
        args.output = f"{base}_formatted.vcf"
    
    process_vcf(args.input, args.output)
    print(f"Formatted VCF has been written to: {args.output}")

if __name__ == '__main__':
    main()
