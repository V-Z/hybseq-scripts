#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Computes gene trees for all aligned contigs named *.aln.fasta (output of hybseq_4_alignment_1_submitter.sh and following scripts) in DATADIR and all subdirectories, for each of them submits job using qsub to process the sample with IQ-TREE.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Setting initial variables

# Set data directories
export WORKDIR="/auto/pruhonice1-ibot/home/$LOGNAME/hybseq"

# Data to process
# export DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_kew_probes/3_aligned/"
# export DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_red_soa_probes/3_aligned"
# export DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/40_samples_soa_probes/3_aligned"
# export DATADIR="/auto/pruhonice1-ibot/shared/oxalis/genus_phylogeny_probes/90_samples_kew_probes/3_aligned"
export DATADIR="/auto/pruhonice1-ibot/shared/oxalis/incarnata/3_aligned"
# export DATADIR="/auto/pruhonice1-ibot/shared/pteronia/hybseq/3_aligned"

# Submitting individual tasks

# Go to working directory
echo "Switching to $DATADIR"
cd "$DATADIR"/ || exit 1
echo

# Make output directory
echo "Making output directory"
mkdir trees
echo

# Processing all samples
echo "Processing all samples at $(date)..."
echo
for ALN in $(find . -name "*.aln.fasta" | sed 's/^\.\///' | sort); do
	ALNB="$(basename "$ALN")"
	echo "Processing $ALNB"
	export ALNF="$ALN" || exit 1
	qsub -l walltime=12:0:0 -l select=1:ncpus=1:mem=8gb:scratch_local=1gb -q ibot -m abe -N HybSeq.genetree."${ALNB%.*}" -V ~/hybseq/bin/hybseq_5_gene_trees_2_qsub.sh || exit 1
	echo
	done

echo "All jobs submitted..."
echo

exit

