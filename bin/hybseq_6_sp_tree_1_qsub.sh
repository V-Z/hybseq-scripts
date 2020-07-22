#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Computes species trees with ASTRAL from all sets of gene trees in the current directory. The input file(s) must be named "*.nwk".
# The tree lists created by hybseq_5_gene_trees_4_postprocess.sh contain on the beginning of each line name of respective genetic region (according to reference bait file). This is advantageous for loading the lists into R, but ASTRAL requires each line to start directly with the NEWICK record. Remove the names by something like:
# sed -i 's/^[[:graph:]]\+ //' *.nwk

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=1:0:0 -l select=1:ncpus=1:mem=4gb:scratch_local=1gb -q ibot -m abe ~/hybseq/bin/hybseq_6_sp_tree_1_qsub.sh

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -a $SCRATCHDIR $DATADIR/ && clean_scratch' TERM

# Set data directories
# HybSeq scripts and data
WORKDIR="/auto/pruhonice1-ibot/home/${LOGNAME}/hybseq"

# Data to process
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/4_gene_trees"
DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/4_gene_trees"
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/4_gene_trees"
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/4_gene_trees"
# DATADIR="/auto/pruhonice1-ibot/shared/oxalis/incarnata/4_gene_trees"
# DATADIR="/auto/pruhonice1-ibot/shared/pteronia/hybseq/4_gene_trees"

# Required modules
echo "Loading modules"
module add openjdk-10 || exit 1
echo

# Change working directory
echo "Going to working directory ${SCRATCHDIR}"
cd "${SCRATCHDIR}"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybSeq data - ${WORKDIR}"
cp "${WORKDIR}"/bin/hybseq_6_sp_tree_2_run.sh "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}"
cp "${DATADIR}"/trees_*.nwk "${SCRATCHDIR}"/  || exit 1
echo

# Running the task
echo "Preprocessing the gene trees files files..."
./hybseq_6_sp_tree_2_run.sh | tee hybseq_sp_tree.log
echo

# Remove unneeded file
echo "Removing unneeded files"
rm hybseq_6_sp_tree_2_run.sh
echo

# Copy results back to storage
echo "Copying results back to ${DATADIR}"
cp -a "${SCRATCHDIR}" "${DATADIR}"/ || export CLEAN_SCRATCH='false'
echo

exit

