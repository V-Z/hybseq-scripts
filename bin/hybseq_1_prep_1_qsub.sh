#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Pre-processing of demultiplexed raw FASTQ files - trimming, deduplication, quality checking and reporting.
# Processes all FASTQ files named *.R[12].fq in $DATADIR. Files can be compressed by BZIP2.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=24:0:0 -l select=1:ncpus=4:mem=16gb:scratch_local=100gb -q ibot -m abe ~/hybseq/bin/hybseq_run_1_prep.sh # HybSeq
# qsub -l walltime=48:0:0 -l select=1:ncpus=8:mem=256gb:scratch_local=1000gb -q ibot -m abe ~/hybseq/bin/hybseq_run_1_prep.sh # WGS

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -a $SCRATCHDIR $DATADIR/ && clean_scratch' TERM

# Set data directories
# HybSeq scripts and data
WORKDIR="/auto/pruhonice1-ibot/home/$LOGNAME/hybseq"

# Data to process
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/1_data/0_data"
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/1_data/0_data"
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/1_data/0_data"
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/1_data/0_data"
DATADIR="/auto/pruhonice1-ibot/shared/oxalis/incarnata/1_data/lib_01/0_data"
# DATADIR="/auto/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_01/0_data"
# DATADIR="/auto/pruhonice1-ibot/shared/pteronia/hybseq/1_data/lib_02/0_data"
# DATADIR="/auto/pruhonice1-ibot/shared/pteronia/hybseq/1_data/oritrophium_tf/0_data"
# DATADIR="/auto/pruhonice1-ibot/shared/pteronia/hybseq/wgs/0_data"

# Required modules
echo "Loading modules"
module add trimmomatic-0.36 || exit 1
module add bbmap-38.42 || exit 1
module add fastQC-0.11.5 || exit 1
module add parallel-20160622 || exit 1
echo

# Change working directory
echo "Going to working directory $SCRATCHDIR"
cd "$SCRATCHDIR"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybSeq data - $WORKDIR"
cp "$WORKDIR"/{adaptors.fa,bin/hybseq_1_prep_2_run.sh} "$SCRATCHDIR"/ || exit 1
echo "Data to process - $DATADIR"
cp -a "$DATADIR" "$SCRATCHDIR"/  || exit 1
echo

# Running the task
echo "Preprocessing the FASTQ files..."
./hybseq_1_prep_2_run.sh -f 0_data -c 4 -o trimmed -d dedup -q qual_rep -a adaptors.fa -m 4 -t "$TRIMMOMATIC_BIN" | tee hybseq_prepare.log # HybSeq
# ./hybseq_1_prep_2_run.sh -f 0_data -c 8 -o trimmed -d dedup -q qual_rep -a adaptors.fa -m 32 -t "$TRIMMOMATIC_BIN" | tee wgs_prepare.log # WGS
echo

# Remove unneeded file
echo "Removing unneeded files"
rm adaptors.fa hybseq_1_prep_2_run.sh
echo

# Copy results back to storage
echo "Copying results back to $DATADIR"
cp -a "$SCRATCHDIR" "$DATADIR"/ || export CLEAN_SCRATCH='false'
echo

exit

