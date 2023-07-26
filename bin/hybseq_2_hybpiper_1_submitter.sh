#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Reads list of files in SAMPLES (must be in WORKDIR) and for each of them submits job using qsub to process the sample with HybPiper.
# SAMPLES must contain base names of the FASTQ files without suffix .R{1,2}.fq[.bz2] (as created by hybseq_1_prep_2_run.sh).
# Ensure path to script hybseq_2_hybpiper_2_qsub.sh (line starting with 'qsub') is correct.
# Results will be copied back to DATADIR - move them then to directory '2_seqs' for further processing (e.g. 'mv HybPiper.* hybseq_hybpiper.* *.dedup ../../../2_seqs/').

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Setting initial variables

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Set data directories
WORKDIR="/storage/brno2/home/${LOGNAME}/hybseq" # Data and scripts for hybseq

# Data to process
# DATADIR="/storage/brno2/home/${LOGNAME}/hybseq_course_2023_zingibers/1_data/lib_01/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/h_alpinum_ont/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_01_sra/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_02_tf/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_03_hieracium_rnaseq/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/hieracium/hyb_piper_phylogen/1_data/lib_04_pilosella_RNA/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/1_data/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/1_data/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/1_data/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/1_data/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/incarnata/1_data/lib_01/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_01/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_02/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_03/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_04/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_05/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_06/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/oritrophium_tf/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/outgroups/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/outgroups2/2_dedup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/outgroups3/2_dedup"
DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/1_data/repetitions_merged/2_dedup"

# List of samples to process
SAMPLES='samples_list.txt' # samples_list.txt is created by hybseq_1_prep_2_run.sh in the output directory for deduplicated sequences (it must be in in the directory with pre-processed input FASTQ sequences)

# Reference bait FASTA files - relative path within $WORKDIR
# BAITFILE='ref/kew_probes.fasta' # Universal Kew probes
BAITFILE='ref/asteraceae/cos_ref.fasta' # Reference for Pteronia
# BAITFILE='ref/oxalis/input_seq_without_cpdna_1086_loci_renamed_concat.fasta' # Reference for Oxalis incarnata
# BAITFILE='ref/oxalis/input_seq_without_cpdna_renamed_concat.fasta' # Reference for Oxalis
# BAITFILE='ref/oxalis/red_soa_probes_gen_comp_concat.fasta' # Reduced reference for Oxalis
# BAITFILE='ref/zingiberaceae/curcuma_hybpiper_renamed_concat.fasta'
# BAITFILE='ref/zingiberaceae/curcuma_HybSeqProbes_first958_concat.fasta'

# Number of CPU threads to use in parallel operations
NCPU='8'

# Submitting individual tasks

################################################################################
# Switching to temporal (SCRATCH) directory and copying input data there
# See https://docs.metacentrum.cz/basics/jobs/
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

# Go to working directory
echo "Switching to ${DATADIR}"
cd "${DATADIR}"/ || exit 1
echo

################################################################################
# NOTE On another clusters than Czech MetaCentrum edit the 'qsub' command below to fit your needs
# See https://docs.metacentrum.cz/advanced/pbs-options/
# Edit qsub parameters if you need more resources, use particular cluster, etc.
################################################################################

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Processing all samples
echo "Processing all samples at $(date)..."
echo
while read -r SAMPLE; do
	echo "Processing ${SAMPLE}"
	qsub -l walltime=12:0:0 -l select=1:ncpus="${NCPU}":mem=16gb:scratch_local=15gb -N HybPiper."${SAMPLE}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",BAITFILE="${BAITFILE}",NCPU="${NCPU}",SAMPLE="${SAMPLE}" -q ibot "${WORKDIR}"/bin/hybseq_2_hybpiper_2_qsub.sh || exit 1
	echo
	done < "${SAMPLES}"

echo "All jobs submitted..."
echo

exit

