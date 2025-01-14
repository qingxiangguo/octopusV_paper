#!/bin/bash

# --------------------------------------
# This script runs Truvari benchmarking for the visor_ont dataset.
#
# Requirements:
# - Use the following truth set and reference:
#   Truth VCF: /projects/b1171/qgn1237/6_SV_VCF_merger/20241113_octopusv_final_benchmarking/Simulation_data/downloaded_SV_data_and_simulated_genome/truth_set_preparation/visor_truth_fixed_truvari_fixed.vcf.gz
#   Reference: /projects/b1171/qgn1237/1_my_database/GRCh38_p13/GRCh38.p13.genome.fa
#
# - For VCF_savior.py, use "-g 38" due to GRCh38 reference.
#
# - Use mamba run to execute commands in specific environments:
#   - mamba666 (with Python3.6+) for VCF_savior.py
#   - truvari for truvari bench
#   - octopusv for converting .svcf to .vcf (octopusv svcf2vcf)
#
# Similar directory structure to previous datasets, including:
# intersection/jasmine|survivor|octopusv
# support_threshold/jasmine|survivor|octopusv with min2,3,4,5
# union/jasmine|survivor|svmerge|octopusv
# and 4callers directories (combisv_4callers, jasmine_4callers, survivor_4callers, svmerge_4callers, octopusv_4callers).
# --------------------------------------

MAMBA_PATH="/home/qgn1237/2_software/mambaforge/condabin/mamba"
BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"
VISOR_DIR="${BASE_DIR}/visor_ont"

TRUTH_VCF="/projects/b1171/qgn1237/6_SV_VCF_merger/20241113_octopusv_final_benchmarking/Simulation_data/downloaded_SV_data_and_simulated_genome/truth_set_preparation/visor_truth_fixed_truvari_fixed.vcf.gz"
REF_GENOME="/projects/b1171/qgn1237/1_my_database/GRCh38_p13/GRCh38.p13.genome.fa"

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

    # Run VCF_savior.py in mamba666 environment with -g 38
    "${MAMBA_PATH}" run -n "${MAMBA666_ENV}" python "${BASE_DIR}/VCF_savior.py" -i "${input_vcf}" -o "${output_dir}/${base_name}_fixed.vcf" -g 38

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

    # Convert SVCF to VCF using octopusv
    "${MAMBA_PATH}" run -n "${OCTOPUSV_ENV}" octopusv svcf2vcf -i "${input_svcf}" -o "${output_dir}/${base_name}.vcf"

    # Then process the resulting VCF
    process_vcf "${output_dir}/${base_name}.vcf" "${output_dir}" "octopusv" "${analysis_type}"

    rm -f "${output_dir}/${base_name}.vcf"
}


echo "Processing intersection results..."
INTERSECTION_EVAL_DIR="${VISOR_DIR}/evaluation"

process_vcf "${VISOR_DIR}/intersection/jasmine/merged_intersection.vcf" \
    "${INTERSECTION_EVAL_DIR}/jasmine/intersection" "jasmine" "intersection"

process_vcf "${VISOR_DIR}/intersection/survivor/merged_intersection.vcf" \
    "${INTERSECTION_EVAL_DIR}/survivor/intersection" "survivor" "intersection"

process_octopusv "${VISOR_DIR}/intersection/octopusv/merged_intersection.svcf" \
    "${INTERSECTION_EVAL_DIR}/octopusv/intersection" "intersection"


echo "Processing support threshold results..."
SUPPORT_EVAL_DIR="${VISOR_DIR}/evaluation"
for min in 2 3 4 5; do
    process_vcf "${VISOR_DIR}/support_threshold/jasmine/merged_min${min}.vcf" \
        "${SUPPORT_EVAL_DIR}/jasmine/support_threshold/min${min}" "jasmine" "support_threshold_${min}"

    process_vcf "${VISOR_DIR}/support_threshold/survivor/merged_min${min}.vcf" \
        "${SUPPORT_EVAL_DIR}/survivor/support_threshold/min${min}" "survivor" "support_threshold_${min}"

    process_octopusv "${VISOR_DIR}/support_threshold/octopusv/merged_min${min}.svcf" \
        "${SUPPORT_EVAL_DIR}/octopusv/support_threshold/min${min}" "support_threshold_${min}"
done


echo "Processing union results..."
UNION_EVAL_DIR="${VISOR_DIR}/evaluation"

process_vcf "${VISOR_DIR}/union/jasmine/merged_union.vcf" \
    "${UNION_EVAL_DIR}/jasmine/union" "jasmine" "union"

process_vcf "${VISOR_DIR}/union/survivor/merged_union.vcf" \
    "${UNION_EVAL_DIR}/survivor/union" "survivor" "union"

process_vcf "${VISOR_DIR}/union/svmerge/merged_union.clustered.vcf" \
    "${UNION_EVAL_DIR}/svmerge/union" "svmerge" "union"

process_octopusv "${VISOR_DIR}/union/octopusv/merged_union.svcf" \
    "${UNION_EVAL_DIR}/octopusv/union" "union"


# 4callers sets
COMBISV_DIR="${VISOR_DIR}/union/combisv_4callers"
for vcf_file in "${COMBISV_DIR}"/*.vcf; do
    tool_name="combisv_4callers"
    analysis_type="union"
    output_dir="${UNION_EVAL_DIR}/${tool_name}"
    process_vcf "${vcf_file}" "${output_dir}" "${tool_name}" "${analysis_type}"
done

process_vcf "${VISOR_DIR}/union/jasmine_4callers/merged_union.vcf" \
    "${UNION_EVAL_DIR}/jasmine_4callers/union" "jasmine_4callers" "union"

process_vcf "${VISOR_DIR}/union/survivor_4callers/merged_union.vcf" \
    "${UNION_EVAL_DIR}/survivor_4callers/union" "survivor_4callers" "union"

process_vcf "${VISOR_DIR}/union/svmerge_4callers/merged_union.clustered.vcf" \
    "${UNION_EVAL_DIR}/svmerge_4callers/union" "svmerge_4callers" "union"

process_octopusv "${VISOR_DIR}/union/octopusv_4callers/merged_union.svcf" \
    "${UNION_EVAL_DIR}/octopusv_4callers/union" "union"


echo "All benchmark analyses completed for visor_ont dataset."
