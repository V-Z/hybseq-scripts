#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Aligns all FASTA files in DATADIR named *.FNA or *.fasta (output of hybseq_3_hybpiper_postprocess_2_run.sh), for each of them submits job using qsub to process the sample with MAFFT and R.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Setting initial variables

# Set data directories
# HybSeq scripts and data
WORKDIR="/storage/pruhonice1-ibot/home/${LOGNAME}/hybseq"

# Data to process
# DATADIR="/storage/pruhonice1-ibot/home/${LOGNAME}/zingiberace_hybseq_course/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/oxalis/incarnata/2_seqs"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/2_seqs/all_samples_contigs"
# DATADIR="/storage/pruhonice1-ibot/shared/pteronia/hybseq/2_seqs/diploids_contigs"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/alignments"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_HybSeq_for_anther_paper/Curcuma_HybPiper_after_ParalogWizard/data/__alignments/aligned_by_Vojta/red_samples"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Curcuma_mvftools_test/4_geneious_mapping/4_to_align"
DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Zingiberaceae_HybSeq_flowering_genes/HybPiper/DNA_alignments"
# DATADIR="/storage/pruhonice1-ibot/shared/zingiberaceae/Zingiberaceae_HybSeq_flowering_genes/run_1/alignments"

# Submitting individual tasks

# Go to working directory
echo "Switching to ${DATADIR}"
cd "${DATADIR}"/ || exit 1
echo

# Removing zero size files
echo "There are $(find . -maxdepth 1 -type f -size 0 | grep -c "\.fasta$\|\.FNA$") alignments with zero size - removing them"
find . -maxdepth 1 -type f -size 0 -exec echo "Removing '{}'" \; -exec rm '{}' \;
echo

# Make output directory
echo "Making output directory"
mkdir aligned
echo

# Processing all samples
echo "Processing all samples at $(date)..."
echo
for ALN in $(find . -maxdepth 1 -name "*.FNA" -o -name "*.fasta" | sort); do
	ALNB="$(basename "${ALN}")"
	echo "Processing ${ALNB}"
	qsub -l walltime=4:0:0 -l select=1:ncpus=1:mem=8gb:scratch_local=1gb -q ibot -N HybSeq.alignment."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALNB}" ~/hybseq/bin/hybseq_4_alignment_2_qsub.sh || exit 1
	echo
	done

echo "All jobs submitted..."
echo

exit

