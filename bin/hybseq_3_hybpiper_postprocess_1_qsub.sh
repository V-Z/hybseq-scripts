#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Reads list of samples (output directories of hybseq_2_hybpiper_3_run.sh) in SAMPLES (must be in DATADIR) and extracts contigs of exons, introns and supercontigs, and computes basic statistics.
# All results are copied back to DATADIR. Resulting contigs can be used for alignments.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=12:0:0 -l select=1:ncpus=1:mem=8gb:scratch_local=100gb -m abe ~/hybseq/bin/hybseq_3_hybpiper_postprocess_1_qsub.sh # NOTE HybSeq course with zingiberaceae test data
# qsub -l walltime=24:0:0 -l select=1:ncpus=1:mem=8gb:scratch_local=500gb -q ibot -m abe ~/hybseq/bin/hybseq_3_hybpiper_postprocess_1_qsub.sh

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -ar ${SCRATCHDIR} ${DATADIR}/ && clean_scratch' TERM

# Set data directories
# HybPiper
HYBPIPDIR="/storage/pruhonice1-ibot/home/${LOGNAME}/bin/HybPiper"
# HybSeq scripts and data
WORKDIR="/storage/pruhonice1-ibot/home/${LOGNAME}/hybseq"

# Reference bait FASTA files - relative path within WORKDIR
BAITFILE='ref/kew_probes.fasta' # Universal Kew probes
# BAITFILE='ref/asteraceae/cos_ref.fasta' # Reference for Pteronia
# BAITFILE='ref/oxalis/input_seq_without_cpdna_1086_loci_renamed_concat.fasta' # Reference for Oxalis incarnata
# BAITFILE='ref/oxalis/input_seq_without_cpdna_renamed_concat.fasta' # Reference for Oxalis
# BAITFILE='ref/oxalis/red_soa_probes_gen_comp_concat.fasta' # Reduced reference for Oxalis
# BAITFILE='ref/zingiberaceae/curcuma_hybpiper_renamed_concat.fasta'

# Data to process
# DATADIR="/storage/pruhonice1-ibot/home/${LOGNAME}/zingiberace_hybseq_course/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/2_seqs/cos"
DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/2_seqs/kew"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/incarnata/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/2_seqs/all_samples_hybpiper"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/2_seqs/diploids_hybpiper"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/2_seqs/ingroup_hybpiper"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/2_seqs/placement_hybpiper"

# samples_list.txt is created by hybseq_1_prep.sh in the output directory for deduplicated sequences (it must be in in the directory with pre-processed input FASTQ sequences)
# If merging multiple libraries, either merge the samples_list.txt from each library, or run something like:
# find . -maxdepth 1 -type d | sed 's/^\.\///' | sort | tail -n+2 > samples_list.txt
SAMPLES='samples_list.txt'

# Required modules
echo "Loading modules"
module add python36-modules/gcc || exit 1 # biopython
module add samtools/1.14-gcc-10.2.1-oyuzddu || exit 1 # samtools
module add r/4.1.3-gcc-10.2.1-6xt26dl || exit 1 # R (ggplot2, gplots, heatmap.plus, reshape2)
echo

# Change working directory
# echo "Going to working directory ${SCRATCHDIR}"
echo "Going to working directory ${DATADIR}"
# cd "${SCRATCHDIR}"/ || exit 1
cd "${DATADIR}"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybPiper - ${HYBPIPDIR}"
# cp -a "${HYBPIPDIR}" "${SCRATCHDIR}"/ || exit 1
cp -a "${HYBPIPDIR}" . || exit 1
echo "HybSeq data - ${WORKDIR}"
# cp -a "${WORKDIR}"/{bin/hybseq_3_hybpiper_postprocess_2_run.sh,ref,rpackages} "${SCRATCHDIR}"/ || exit 1
cp -a "${WORKDIR}"/{bin/hybseq_3_hybpiper_postprocess_2_run.sh,ref,rpackages} . || exit 1
# echo "Data to process - ${DATADIR}"
# cp -a "${DATADIR}"/* "${SCRATCHDIR}"/ || exit 1
echo

# Runing the task (HibPiper postprocessing)
echo "Running HybPiper postprocessing..."
./hybseq_3_hybpiper_postprocess_2_run.sh -p "${HYBPIPDIR}" -b "${BAITFILE}" -s "${SAMPLES}" | tee hybseq_hybpiper_postprocess.log
echo

# # Copy results back to storage
# echo "Copying results back to ${DATADIR}"
# cp -a "${SCRATCHDIR}" "${DATADIR}"/ || export CLEAN_SCRATCH='false'
# echo

exit

