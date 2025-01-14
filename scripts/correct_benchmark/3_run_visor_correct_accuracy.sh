#!/bin/bash

# Base directory
BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241122_octopusv_correct_benchmark"

# Truth VCF file
TRUTH_VCF="/projects/b1171/qgn1237/6_SV_VCF_merger/20241113_octopusv_final_benchmarking/Simulation_data/downloaded_SV_data_and_simulated_genome/truth_set_preparation/visor_truth.vcf"

# Create Python script for matching logic
cat > "${BASE_DIR}/compare_sv.py" << 'EOL'
import sys
import re

def parse_sv_line(line):
    parts = line.strip().split('\t')
    chrom = parts[0]
    pos = int(parts[1])
    
    # Extract SVTYPE
    svtype_match = re.search(r'SVTYPE=([^;]+)', line)
    svtype = svtype_match.group(1) if svtype_match else None
    
    # Extract END and CHR2 for TRA
    end_match = re.search(r'END=(\d+)', line)
    end = int(end_match.group(1)) if end_match else None
    
    chr2_match = re.search(r'CHR2=([^;]+)', line)
    chr2 = chr2_match.group(1) if chr2_match else None
    
    return {'chrom': chrom, 'pos': pos, 'svtype': svtype, 'end': end, 'chr2': chr2, 'line': line}

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
        # Check both breakpoints within TRA tolerance
        if abs(corrected['end'] - truth['end']) > 5000:
            return False
        return True
    
    # For non-TRA events, check type match
    if corrected['svtype'] == truth['svtype']:
        return True
    # Special case: DUP in corrected matching INS in truth
    if corrected['svtype'] == 'DUP' and truth['svtype'] == 'INS':
        return True
        
    return False

def main():
    corrected_file = sys.argv[1]
    truth_file = sys.argv[2]
    output_file = sys.argv[3]
    log_file = sys.argv[4]
    
    # Read truth file into memory
    truth_events = []
    with open(truth_file) as f:
        for line in f:
            if line.startswith('#'):
                continue
            truth_events.append(parse_sv_line(line))
    
    matches = []
    correct_type = 0
    total_matched = 0
    
    # Process corrected file
    with open(corrected_file) as f, open(output_file, 'w') as out:
        # Write header
        out.write("corrected_SVCF\tground_truth\n")
        
        for line in f:
            if line.startswith('#'):
                continue
                
            corrected_sv = parse_sv_line(line)
            tolerance = 5000 if corrected_sv['svtype'] == 'TRA' else 50
            
            # Find matching event in truth
            for truth_sv in truth_events:
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
    
    # Create evaluation directory if it doesn't exist
    mkdir -p "${BASE_DIR}/${dataset}/evaluation"
    
    # Process each corrected SVCF file
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
        
        python3 "${BASE_DIR}/compare_sv.py" \
                "${corrected_svcf}" \
                "${TRUTH_VCF}" \
                "${output_file}" \
                "${log_file}"
        
        echo "Completed evaluation for ${caller}"
        echo "Results written to ${output_file} and ${log_file}"
    done
}

# Process VISOR datasets
for dataset in "visor_ngs" "visor_ont" "visor_pacbio"; do
    process_dataset "$dataset"
done

echo "Evaluation completed for all VISOR datasets"
