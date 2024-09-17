#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Pre-processing of demultiplexed raw FASTQ files - trimming, deduplication, quality checking and reporting.
# Processes all FASTQ files named *.R[12].fq in $DATADIR. Files can be compressed by BZIP2.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

################################################################################
# Sections of the code where edits are to be expected are marked by "NOTE" in comments (see below)
################################################################################

################################################################################
# NOTE Submit the job by the command below
# On another clusters than Czech MetaCentrum edit the 'qsub' command below to fit your needs
# See https://docs.metacentrum.cz/advanced/pbs-options/
# Edit qsub parameters if you need more resources, use particular cluster, etc.
################################################################################

# qsub -l walltime=24:0:0 -l select=1:ncpus=4:mem=64gb:scratch_local=1000gb -q ibot -m abe ~/hybseq/bin/hybseq_1_prep_1_qsub.sh

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Set data directories
# HybSeq scripts and data
WORKDIR="/storage/pruhonice1-ibot/home/${LOGNAME}/hybseq"

# Data to process
# DATADIR="/storage/brno2/home/${LOGNAME}/hybseq_course_2023_zingibers/1_data/lib_01/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/brassicaceae/arabidopsis_plastome_hybrid_zone/0_data"
DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_01_sra/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_01_sra_se/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_02_tf/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_03_hieracium_rnaseq/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_04_pilosella_RNA/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/1_data/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/1_data/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/1_data/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/1_data/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/incarnata/1_data/lib_01/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_01/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_02/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_03/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_04/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_05/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_06/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/oritrophium_tf/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/outgroups/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/repetitions_merged/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/wgs/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/skimming/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_mvftools_test/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_01/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_02/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_03/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_04/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_05/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_06/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_07/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_08/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_09/0_data"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/mapping_vcf_vjt/1_data/lib_10/0_data"

################################################################################
# Loading of application modules
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'module' commands below
################################################################################

# Required modules
echo "Loading modules"
module add trimmomatic/0.39-gcc-10.2.1-uuuagj7 || exit 1
module add bbmap/39.01-gcc-10.2.1-d3jpcp7 || exit 1
module add fastqc/0.11.9-gcc-10.2.1-duxu5be || exit 1
module add parallel/20210922-gcc-10.2.1-iiyjqem || exit 1
echo

################################################################################
# Cleanup of temporal (scratch) directory where the calculation was done
# See https://docs.metacentrum.cz/advanced/job-tracking/#trap-command-usage
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'trap' commands below
################################################################################

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -a ${SCRATCHDIR} ${DATADIR}/ && clean_scratch' TERM

################################################################################
# Switching to temporal (SCRATCH) directory and copying input data there
# See https://docs.metacentrum.cz/basics/jobs/
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

# Change working directory
echo "Going to working directory ${SCRATCHDIR}"
cd "${SCRATCHDIR}"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybSeq data - ${WORKDIR}"
cp "${WORKDIR}"/{adaptors.fa,bin/hybseq_1_prep_2_run*.sh} "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}"
cp -a "${DATADIR}" "${SCRATCHDIR}"/  || exit 1
echo

################################################################################
# The calculation
################################################################################

################################################################################
# NOTE Edit parameters below to fit your data
# NOTE Edit parameters according to resources required by 'qsub' command (see above)
# NOTE Select pair-end or single-end variant of processing of input FASTQ files
################################################################################

# Running the task
echo "Preprocessing the FASTQ files..."
# Pair-end (forward and reverse) FASTQ files
./hybseq_1_prep_2_run.sh -f 0_data -c 4 -o 1_trimmed -d 2_dedup -q 3_qual_rep -a adaptors.fa -m 16 -t /cvmfs/software.metacentrum.cz/spack18/software/linux-debian11-x86_64_v2/gcc-10.2.1/trimmomatic-0.39-uuuagj7ae3wim6rdyxkncii4jiuikejy/bin/trimmomatic-0.39.jar | tee hybseq_prepare.log
# Single-end FASTQ files
# ./hybseq_1_prep_2_run_se.sh -f 0_data -c 4 -o 1_trimmed -d 2_dedup -q 3_qual_rep -a adaptors.fa -m 16 -t /cvmfs/software.metacentrum.cz/spack18/software/linux-debian11-x86_64_v2/gcc-10.2.1/trimmomatic-0.39-uuuagj7ae3wim6rdyxkncii4jiuikejy/bin/trimmomatic-0.39.jar | tee hybseq_prepare.log
echo

################################################################################
# Input files are removed from temporal working directory
# Results are copied to the output directory
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

# Remove unneeded file
echo "Removing unneeded files"
rm adaptors.fa hybseq_1_prep_2_run*.sh
echo

# Copy results back to storage
echo "Copying results back to ${DATADIR}"
cp -a "${SCRATCHDIR}" "${DATADIR}"/ || export CLEAN_SCRATCH='false'
echo

exit

