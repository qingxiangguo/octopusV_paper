#!/bin/bash

# Base directory
BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241122_octopusv_correct_benchmark"

# Truth VCF files
TRUTH_VCF1="/projects/b1171/qgn1237/6_SV_VCF_merger/20241113_octopusv_final_benchmarking/NA12878_truth_data/NA12878_DGV-2016_LR-assembly_ground_truth.vcf"
TRUTH_VCF2="/projects/b1171/qgn1237/6_SV_VCF_merger/20241113_octopusv_final_benchmarking/NA12878_truth_data/ALL.wgs.mergedSV.v8.20130502.svs.genotypes.vcf"

# Create Python script for matching logic
cat > "${BASE_DIR}/compare_na12878_sv_two_truth.py" << 'EOL'
import sys
import re

def parse_corrected_sv_line(line):
    parts = line.strip().split('\t')
    chrom = parts[0].replace('chr', '')  # Remove 'chr' prefix if present
    pos = int(parts[1])
    
    # Extract SVTYPE
    svtype_match = re.search(r'SVTYPE=([^;]+)', line)
    svtype = svtype_match.group(1) if svtype_match else None
    
    # Extract END and CHR2 for TRA
    end_match = re.search(r'END=(\d+)', line)
    end = int(end_match.group(1)) if end_match else None
    
    chr2_match = re.search(r'CHR2=([^;]+)', line)
    chr2 = chr2_match.group(1).replace('chr', '') if chr2_match else None
    
    return {'chrom': chrom, 'pos': pos, 'svtype': svtype, 'end': end, 'chr2': chr2, 'line': line}

def parse_truth1_sv_line(line):
    # For DGV truth file
    parts = line.strip().split('\t')
    chrom = parts[0].replace('chr', '')
    pos = int(parts[1])
    svtype = parts[2]  # In truth file, column 3 is the SVTYPE
    
    # Parse SVLEN to get END position
    svlen_match = re.search(r'SVLEN=(\d+)', line)
    svlen = int(svlen_match.group(1)) if svlen_match else None
    end = pos + svlen if svlen else None
    
    # Extract SVTYPE from INFO field if present
    svtype_match = re.search(r'SVTYPE=([^;]+)', line)
    if svtype_match:
        svtype = svtype_match.group(1)
    
    return {'chrom': chrom, 'pos': pos, 'svtype': svtype, 'end': end, 'chr2': None, 'line': line}

def parse_truth2_sv_line(line):
    # For ALL.wgs truth file
    parts = line.strip().split('\t')
    chrom = parts[0].replace('chr', '')
    pos = int(parts[1])
    
    # Extract SVTYPE from INFO field
    svtype_match = re.search(r'SVTYPE=([^;]+)', parts[7])
    svtype = svtype_match.group(1) if svtype_match else None
    
    # Try to get END position
    end_match = re.search(r'END=(\d+)', parts[7])
    end = int(end_match.group(1)) if end_match else None
    
    return {'chrom': chrom, 'pos': pos, 'svtype': svtype, 'end': end, 'chr2': None, 'line': line}

def is_matching_sv(corrected, truth, tolerance):
    # Same chromosome check
    if corrected['chrom'] != truth['chrom']:
        return False
    
    # Position within tolerance
    if abs(corrected['pos'] - truth['pos']) > tolerance:
        return False
    
    # For TRA events
    if corrected['svtype'] == 'TRA' and truth['svtype'] == 'TRA':
        if corrected['chr2'] != truth['chr2']:
            return False
        # Check both breakpoints within TRA tolerance (5000bp)
        if abs(corrected['end'] - truth['end']) > 5000:
            return False
        return True
    
    # For non-TRA events
    if corrected['svtype'] == truth['svtype']:
        return True
    # Special case: DUP in corrected matching INS in truth
    if corrected['svtype'] == 'DUP' and truth['svtype'] == 'INS':
        return True
    
    return False

def main():
    corrected_file = sys.argv[1]
    truth_file1 = sys.argv[2]
    truth_file2 = sys.argv[3]
    output_file = sys.argv[4]
    log_file = sys.argv[5]
    
    # Read both truth files into memory
    truth_events1 = []
    truth_events2 = []
    
    with open(truth_file1) as f:
        for line in f:
            if line.startswith('#'):
                continue
            truth_events1.append(parse_truth1_sv_line(line))
    
    with open(truth_file2) as f:
        for line in f:
            if line.startswith('#'):
                continue
            truth_events2.append(parse_truth2_sv_line(line))
    
    matches = []
    correct_type = 0
    total_matched = 0
    
    # Process corrected file
    with open(corrected_file) as f, open(output_file, 'w') as out:
        out.write("corrected_SVCF\tground_truth\n")
        
        for line in f:
            if line.startswith('#'):
                continue
                
            corrected_sv = parse_corrected_sv_line(line)
            tolerance = 5000 if corrected_sv['svtype'] == 'TRA' else 50
            
            # Try matching against both truth sets
            matched = False
            
            # Try truth set 1
            for truth_sv in truth_events1:
                if is_matching_sv(corrected_sv, truth_sv, tolerance):
                    total_matched += 1
                    if corrected_sv['svtype'] == truth_sv['svtype'] or \
                       (corrected_sv['svtype'] == 'DUP' and truth_sv['svtype'] == 'INS'):
                        correct_type += 1
                    out.write(f"{corrected_sv['line'].strip()}\t{truth_sv['line'].strip()}\n")
                    matched = True
                    break
            
            # If no match in truth set 1, try truth set 2
            if not matched:
                for truth_sv in truth_events2:
                    if is_matching_sv(corrected_sv, truth_sv, tolerance):
                        total_matched += 1
                        if corrected_sv['svtype'] == truth_sv['svtype'] or \
                           (corrected_sv['svtype'] == 'DUP' and truth_sv['svtype'] == 'INS'):
                            correct_type += 1
                        out.write(f"{corrected_sv['line'].strip()}\t{truth_sv['line'].strip()}\n")
                        break
    
    # Write statistics to log file
    accuracy = (correct_type / total_matched * 100) if total_matched > 0 else 0
    with open(log_file, 'w') as log:
        log.write(f"Total matched events: {total_matched}\n")
        log.write(f"Correctly typed events: {correct_type}\n")
        log.write(f"Accuracy: {accuracy:.2f}%\n")

if __name__ == "__main__":
    main()
EOL

# Function to process a single dataset
process_dataset() {
    dataset=$1
    echo "Processing ${dataset}..."
    
    mkdir -p "${BASE_DIR}/${dataset}/evaluation"
    
    if [[ $dataset == *"ngs"* ]]; then
        callers=("delly" "lumpy" "manta" "svaba")
    else
        callers=("cutesv" "pbsv" "sniffles" "svim")
    fi
    
    for caller in "${callers[@]}"; do
        echo "Evaluating ${caller}..."
        corrected_svcf="${BASE_DIR}/${dataset}/corrected/${caller}_corrected.svcf"
        output_file="${BASE_DIR}/${dataset}/evaluation/${caller}_matches.txt"
        log_file="${BASE_DIR}/${dataset}/evaluation/${caller}_statistics.log"
        
        python3 "${BASE_DIR}/compare_na12878_sv_two_truth.py" \
                "${corrected_svcf}" \
                "${TRUTH_VCF1}" \
                "${TRUTH_VCF2}" \
                "${output_file}" \
                "${log_file}"
        
        echo "Completed evaluation for ${caller}"
        echo "Results written to ${output_file} and ${log_file}"
    done
}

# Process NA12878 datasets
for dataset in "NA12878_ngs" "NA12878_pacbio"; do
    process_dataset "$dataset"
done

echo "Evaluation completed for all NA12878 datasets"
