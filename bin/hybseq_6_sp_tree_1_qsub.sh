#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Computes species trees with ASTRAL from all sets of gene trees in the current directory. The input file(s) must be named "*.nwk".
# The tree lists created by hybseq_5_gene_trees_4_postprocess.sh contain on the beginning of each line name of respective genetic region (according to reference bait file). This is advantageous for loading the lists into R, but ASTRAL requires each line to start directly with the NEWICK record. Remove the names by something like:
# sed -i 's/^[[:graph:]]\+ //' *.nwk

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

################################################################################
# NOTE Submit the job by the command below
# On another clusters than Czech MetaCentrum edit the 'qsub' command below to fit your needs
# See https://docs.metacentrum.cz/advanced/pbs-options/
# Edit qsub parameters if you need more resources, use particular cluster, etc.
################################################################################

# qsub -l walltime=4:0:0 -l select=1:ncpus=1:mem=4gb:scratch_local=1gb -q ibot -m abe ~/hybseq/bin/hybseq_6_sp_tree_1_qsub.sh
# qsub -l walltime=4:0:0 -l select=1:ncpus=1:mem=4gb:scratch_local=1gb -m abe ~/hybseq/bin/hybseq_6_sp_tree_1_qsub.sh # NOTE HybSeq course with zingiberaceae test data

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Set data directories
# HybSeq scripts and data
WORKDIR="/storage/pruhonice1-ibot/home/${LOGNAME}/hybseq"

# Data to process
DATADIR="/storage/brno2/home/${LOGNAME}/hybseq_course_2023_zingibers/5_sp_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/4_gene_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/4_gene_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/4_gene_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/4_gene_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/incarnata/4_gene_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/4_gene_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/5_sp_trees/all_samples"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/5_sp_trees/diploids"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/5_sp_trees/ingroup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/5_sp_trees/ingroup_filt_025"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/5_sp_trees/ingroup_filt_035"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/5_sp_trees/placement"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments/aligned_by_Vojta/diploids/trees"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments_july_2022/final_alns_for_sptree/diploids/trees/4_astral_sp_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments_july_2022/final_alns_for_sptree/trees/4_astral_sp_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_mvftools_test/6_gene_trees"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Zingiberaceae_HybSeq_flowering_genes/HybPiper/DNA_alignments/aligned/trees/4_sp_trees"

################################################################################
# Loading of application module
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'module' command below
################################################################################

# Required modules
echo "Loading modules"
module add openjdk/17.0.0_35-gcc-8.3.0-rfe265h || exit 1
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
cp "${WORKDIR}"/bin/hybseq_6_sp_tree_2_run.sh "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}"
cp "${DATADIR}"/trees*.nwk "${SCRATCHDIR}"/  || exit 1
echo

################################################################################
# The calculation
################################################################################

# Running the task
echo "Preprocessing the gene trees files files..."
./hybseq_6_sp_tree_2_run.sh | tee hybseq_sp_tree.log
echo

################################################################################
# Input files are removed from temporal working directory
# Results are copied to the output directory
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

# Remove unneeded file
echo "Removing unneeded files"
rm hybseq_6_sp_tree_2_run.sh
echo

# Copy results back to storage
echo "Copying results back to ${DATADIR}"
cp -a "${SCRATCHDIR}" "${DATADIR}"/ || export CLEAN_SCRATCH='false'
echo

exit

