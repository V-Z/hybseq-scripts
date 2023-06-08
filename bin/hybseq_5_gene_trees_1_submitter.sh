#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Computes gene trees for all aligned contigs named *.aln.fasta (output of hybseq_4_alignment_1_submitter.sh and following scripts) in DATADIR and all subdirectories, for each of them submits job using qsub to process the sample with IQ-TREE.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Setting initial variables

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Set data directories
WORKDIR="/storage/pruhonice1-ibot/home/${LOGNAME}/hybseq"

# Data to process
DATADIR="/storage/brno2/home/${LOGNAME}/hybseq_course_2023_zingibers/3_aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/3_aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/3_aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/3_aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/3_aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/incarnata/3_aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/3_aligned/all_samples"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/3_aligned/diploids"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/3_aligned/ingroup"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/3_aligned/ingroup_filt025"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/3_aligned/ingroup_filt035"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/3_aligned/placement"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/alignments/aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments/aligned_by_Vojta"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments/aligned_by_Vojta/diploids"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments/aligned_by_Vojta/red_samples/aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments_july_2022/final_alns_for_sptree"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments_july_2022/final_alns_for_sptree/diploids"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_mvftools_test/5_aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Zingiberaceae_HybSeq_flowering_genes/HybPiper/DNA_alignments/aligned"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Zingiberaceae_HybSeq_flowering_genes/run_1/alignments/aligned"

# Submitting individual tasks

# Go to working directory
echo "Switching to ${DATADIR}"
cd "${DATADIR}"/ || exit 1
echo

# Make output directory
echo "Making output directory"
mkdir trees
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
for ALN in $(find . -name "*.aln.fasta" | sed 's/^\.\///' | sort); do
	ALNB="$(basename "${ALN}")"
	echo "Processing ${ALNB}"
	qsub -l walltime=48:0:0 -l select=1:ncpus=1:mem=16gb:scratch_local=1gb -N HybSeq.genetree."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALN}" "${WORKDIR}"/bin/hybseq_5_gene_trees_2_qsub.sh || { echo "Error! Submission of \"${ALNB}\" failed. Aborting."; echo; exit 1; }
	echo
	done

echo "All jobs submitted..."
echo

exit

