#!/bin/bash

# --------------------------------------
# This script runs Truvari benchmarking for the NA12878_pacbio dataset.
#
# Key Points:
# - Use /home/qgn1237/2_software/mambaforge/condabin/mamba run -n ENV_NAME COMMAND
#   to run commands directly in the specified environment (no activate/deactivate).
# - Environments:
#   - mamba666: for running VCF_savior.py (Python3.6+ required).
#   - truvari: for running truvari bench.
#   - octopusv: for converting .svcf to .vcf (octopusv svcf2vcf).
#
# Tools:
# - For VCF files (from jasmine, survivor, svmerge, combisv, etc.): run VCF_savior.py then truvari.
# - For Octopusv SVCF files: first convert to VCF, then run VCF_savior.py and truvari.
#
# Data structure:
# NA12878_pacbio
# ├── intersection
# │   ├── jasmine/merged_intersection.vcf
# │   ├── survivor/merged_intersection.vcf
# │   └── octopusv/merged_intersection.svcf
# ├── support_threshold
# │   ├── jasmine/merged_min2.vcf, merged_min3.vcf, merged_min4.vcf, merged_min5.vcf
# │   ├── survivor/merged_min2.vcf, merged_min3.vcf, merged_min4.vcf, merged_min5.vcf
# │   └── octopusv/merged_min2.svcf, merged_min3.svcf, merged_min4.svcf, merged_min5.svcf
# └── union
#     ├── combisv_4callers/*.vcf (multiple vcf)
#     ├── jasmine/merged_union.vcf
#     ├── jasmine_4callers/merged_union.vcf
#     ├── survivor/merged_union.vcf
#     ├── survivor_4callers/merged_union.vcf
#     ├── svmerge/merged_union.clustered.vcf
#     ├── svmerge_4callers/merged_union.clustered.vcf
#     ├── octopusv/merged_union.svcf
#     ├── octopusv_4callers/merged_union.svcf
#
# The truth set and reference:
# -b /projects/b1171/qgn1237/6_SV_VCF_merger/20241113_octopusv_final_benchmarking/NA12878_truth_data/na12878_truth_formatted_sorted.vcf.gz
# -f /projects/b1171/qgn1237/1_my_database/GRCh37_hs37d5/hs37d5.fa
#
# The logic is the same as the previous script for NA12878_ngs.
# --------------------------------------

MAMBA_PATH="/home/qgn1237/2_software/mambaforge/condabin/mamba"
BASE_DIR="/projects/b1171/qgn1237/6_SV_VCF_merger/20241202_octopusv_merge_benchmark"
NA12878_DIR="${BASE_DIR}/NA12878_pacbio"
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

    # Convert SVCF to VCF using octopusv
    "${MAMBA_PATH}" run -n "${OCTOPUSV_ENV}" octopusv svcf2vcf -i "${input_svcf}" -o "${output_dir}/${base_name}.vcf"

    # Then process the resulting VCF
    process_vcf "${output_dir}/${base_name}.vcf" "${output_dir}" "octopusv" "${analysis_type}"

    rm -f "${output_dir}/${base_name}.vcf"
}

echo "Processing intersection results..."
INTERSECTION_EVAL_DIR="${NA12878_DIR}/evaluation"

# Intersection: jasmine, survivor (VCF), octopusv (SVCF)
process_vcf "${NA12878_DIR}/intersection/jasmine/merged_intersection.vcf" \
    "${INTERSECTION_EVAL_DIR}/jasmine/intersection" "jasmine" "intersection"

process_vcf "${NA12878_DIR}/intersection/survivor/merged_intersection.vcf" \
    "${INTERSECTION_EVAL_DIR}/survivor/intersection" "survivor" "intersection"

process_octopusv "${NA12878_DIR}/intersection/octopusv/merged_intersection.svcf" \
    "${INTERSECTION_EVAL_DIR}/octopusv/intersection" "intersection"


echo "Processing support threshold results..."
SUPPORT_EVAL_DIR="${NA12878_DIR}/evaluation"

# Support thresholds: min2,3,4,5 for jasmine, survivor (VCF), octopusv (SVCF)
for min in 2 3 4 5; do
    # jasmine
    process_vcf "${NA12878_DIR}/support_threshold/jasmine/merged_min${min}.vcf" \
        "${SUPPORT_EVAL_DIR}/jasmine/support_threshold/min${min}" "jasmine" "support_threshold_${min}"

    # survivor
    process_vcf "${NA12878_DIR}/support_threshold/survivor/merged_min${min}.vcf" \
        "${SUPPORT_EVAL_DIR}/survivor/support_threshold/min${min}" "survivor" "support_threshold_${min}"

    # octopusv
    process_octopusv "${NA12878_DIR}/support_threshold/octopusv/merged_min${min}.svcf" \
        "${SUPPORT_EVAL_DIR}/octopusv/support_threshold/min${min}" "support_threshold_${min}"
done


echo "Processing union results..."
UNION_EVAL_DIR="${NA12878_DIR}/evaluation"

# union/jasmine
process_vcf "${NA12878_DIR}/union/jasmine/merged_union.vcf" \
    "${UNION_EVAL_DIR}/jasmine/union" "jasmine" "union"

# union/survivor
process_vcf "${NA12878_DIR}/union/survivor/merged_union.vcf" \
    "${UNION_EVAL_DIR}/survivor/union" "survivor" "union"

# union/svmerge
process_vcf "${NA12878_DIR}/union/svmerge/merged_union.clustered.vcf" \
    "${UNION_EVAL_DIR}/svmerge/union" "svmerge" "union"

# union/octopusv
process_octopusv "${NA12878_DIR}/union/octopusv/merged_union.svcf" \
    "${UNION_EVAL_DIR}/octopusv/union" "union"


# Now handle the 4callers directories
# union/combisv_4callers: multiple vcf files
COMBISV_DIR="${NA12878_DIR}/union/combisv_4callers"
for vcf_file in "${COMBISV_DIR}"/*.vcf; do
    tool_name="combisv_4callers"
    analysis_type="union"
    output_dir="${UNION_EVAL_DIR}/${tool_name}"
    process_vcf "${vcf_file}" "${output_dir}" "${tool_name}" "${analysis_type}"
done

# union/jasmine_4callers
process_vcf "${NA12878_DIR}/union/jasmine_4callers/merged_union.vcf" \
    "${UNION_EVAL_DIR}/jasmine_4callers/union" "jasmine_4callers" "union"

# union/survivor_4callers
process_vcf "${NA12878_DIR}/union/survivor_4callers/merged_union.vcf" \
    "${UNION_EVAL_DIR}/survivor_4callers/union" "survivor_4callers" "union"

# union/svmerge_4callers
process_vcf "${NA12878_DIR}/union/svmerge_4callers/merged_union.clustered.vcf" \
    "${UNION_EVAL_DIR}/svmerge_4callers/union" "svmerge_4callers" "union"

# union/octopusv_4callers (SVCF)
process_octopusv "${NA12878_DIR}/union/octopusv_4callers/merged_union.svcf" \
    "${UNION_EVAL_DIR}/octopusv_4callers/union" "union"


echo "All benchmark analyses completed for NA12878_pacbio dataset."
