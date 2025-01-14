#!/bin/bash

# --------------------------------------
# This script runs Truvari benchmarking for the NA12878_ngs dataset using absolute paths for mamba.
#
# Steps:
# - Use: /home/qgn1237/2_software/mambaforge/condabin/mamba run -n ENV_NAME COMMAND
#   to directly run commands in the specified environment.
#
# - For VCF_savior.py: use mamba run -n mamba666 python ...
# - For truvari: use mamba run -n truvari truvari ...
# - For octopusv: use mamba run -n octopusv octopusv ...
#
# Ensure:
# - mamba666 env has Python 3.6+ for VCF_savior.py.
# - truvari env has truvari installed.
# - octopusv env has octopusv installed.
#
# No environment activation, no sourcing needed.
# --------------------------------------

MAMBA_PATH="/home/qgn1237/2_software/mambaforge/condabin/mamba"

BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"
NA12878_DIR="${BASE_DIR}/NA12878_ngs"
TRUTH_VCF="/projects/b1171/qgn1237/6_SV_VCF_merger/20241113_octopusv_final_benchmarking/NA12878_truth_data/fixed_merged_na12878_1kg_sorted.vcf.gz"
REF_GENOME="/projects/b1171/qgn1237/1_my_database/GRCh37_hs37d5/hs37d5.fa"

OCTOPUSV_ENV="octopusv"
TRUVARI_ENV="truvari"
MAMBA666_ENV="mamba666"

process_vcf() {
    local input_vcf=$1
    local output_dir=$2
    local tool_name=$3
    local analysis_type=$4

    mkdir -p "${output_dir}"

    base_name=$(basename "${input_vcf}")
    base_name=${base_name%.vcf}
    base_name=${base_name%.clustered}

    echo "Processing ${tool_name} ${analysis_type}: ${base_name}"

    # Run VCF_savior.py in mamba666 environment
    "${MAMBA_PATH}" run -n "${MAMBA666_ENV}" python "${BASE_DIR}/VCF_savior.py" -i "${input_vcf}" -o "${output_dir}/${base_name}_fixed.vcf" -g 37

    # Check and remove existing evaluation directory if it exists
    eval_dir="${output_dir}/${base_name}_evaluation"
    if [ -d "${eval_dir}" ]; then
        echo "Found existing evaluation directory: ${eval_dir}"
        echo "Removing it safely using rip..."
        rip "${eval_dir}"
    fi

    # Run truvari in truvari environment
    "${MAMBA_PATH}" run -n "${TRUVARI_ENV}" truvari bench \
        -b "${TRUTH_VCF}" \
        -c "${output_dir}/${base_name}_fixed_sorted.vcf.gz" \
        -f "${REF_GENOME}" \
        --pctseq 0 \
        -o "${output_dir}/${base_name}_evaluation"

    # Cleanup
    rm -f "${output_dir}/${base_name}_fixed.vcf"
    rm -f "${output_dir}/${base_name}_fixed_sorted.vcf"
    rm -f "${output_dir}/${base_name}_fixed_sorted.vcf.gz"
    rm -f "${output_dir}/${base_name}_fixed_sorted.vcf.gz.tbi"
}

process_octopusv() {
    local input_svcf=$1
    local output_dir=$2
    local analysis_type=$3

    mkdir -p "${output_dir}"
    base_name=$(basename "${input_svcf}" .svcf)

    echo "Processing octopusv ${analysis_type}: ${base_name}"

    # Convert SVCF to VCF using octopusv environment
    "${MAMBA_PATH}" run -n "${OCTOPUSV_ENV}" octopusv svcf2vcf -i "${input_svcf}" -o "${output_dir}/${base_name}.vcf"

    # Then process the VCF as normal
    process_vcf "${output_dir}/${base_name}.vcf" "${output_dir}" "octopusv" "${analysis_type}"

    rm -f "${output_dir}/${base_name}.vcf"
}

echo "Processing intersection results..."
INTERSECTION_EVAL_DIR="${NA12878_DIR}/evaluation"

process_vcf "${NA12878_DIR}/intersection/jasmine/merged_intersection.vcf" \
    "${INTERSECTION_EVAL_DIR}/jasmine/intersection" "jasmine" "intersection"

process_vcf "${NA12878_DIR}/intersection/survivor/merged_intersection.vcf" \
    "${INTERSECTION_EVAL_DIR}/survivor/intersection" "survivor" "intersection"

process_octopusv "${NA12878_DIR}/intersection/octopusv/merged_intersection.svcf" \
    "${INTERSECTION_EVAL_DIR}/octopusv/intersection" "intersection"

echo "Processing support threshold results..."
SUPPORT_EVAL_DIR="${NA12878_DIR}/evaluation"

for min in 2 3; do
    process_vcf "${NA12878_DIR}/support_threshold/jasmine/merged_min${min}.vcf" \
        "${SUPPORT_EVAL_DIR}/jasmine/support_threshold/min${min}" "jasmine" "support_threshold_${min}"

    process_vcf "${NA12878_DIR}/support_threshold/survivor/merged_min${min}.vcf" \
        "${SUPPORT_EVAL_DIR}/survivor/support_threshold/min${min}" "survivor" "support_threshold_${min}"

    process_octopusv "${NA12878_DIR}/support_threshold/octopusv/merged_min${min}.svcf" \
        "${SUPPORT_EVAL_DIR}/octopusv/support_threshold/min${min}" "support_threshold_${min}"
done

echo "Processing union results..."
UNION_EVAL_DIR="${NA12878_DIR}/evaluation"

process_vcf "${NA12878_DIR}/union/jasmine/merged_union.vcf" \
    "${UNION_EVAL_DIR}/jasmine/union" "jasmine" "union"

process_vcf "${NA12878_DIR}/union/survivor/merged_union.vcf" \
    "${UNION_EVAL_DIR}/survivor/union" "survivor" "union"

process_vcf "${NA12878_DIR}/union/svmerge/merged_union.clustered.vcf" \
    "${UNION_EVAL_DIR}/svmerge/union" "svmerge" "union"

process_octopusv "${NA12878_DIR}/union/octopusv/merged_union.svcf" \
    "${UNION_EVAL_DIR}/octopusv/union" "union"

echo "All benchmark analyses completed for NA12878_ngs dataset."
