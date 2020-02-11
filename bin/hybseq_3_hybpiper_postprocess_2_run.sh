#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Process all sample directories in the working directory by the HybPiper pipeline - extracts contigs and calculates statistics.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# TODO Parse initial arguments

# Exit on error
function operationfailed {
	echo "Error! Operation failed!"
	echo
	echo "See previous message(s) to be able to trace the problem."
	echo
	# Do not clean SCRATCHDIR, but copy content back to DATADIR
	export CLEAN_SCRATCH='false'
	exit 1
	}

# Check if all required binaries are available
function toolcheck {
	command -v "$1" >/dev/null 2>&1 || {
		echo >&2 "Error! $1 is required but not installed. Aborting. Please, install it."
		echo
		operationfailed
		}
	}

toolcheck python2
toolcheck R
toolcheck samtools

# Checking if all required variables are provided
if [ -z "$HYBPIPDIR" ]; then
	echo "Error! Directory with HybPiper not provided!"
	operationfailed
	fi
if [ -z "$BAITFILE" ]; then
	echo "Error! Reference bait FASTA file not provided!"
	operationfailed
	fi
if [ -z "$SAMPLES" ]; then
	echo "Error! List of samples to process not provided!"
	operationfailed
	fi

# Get full paths
HYBPIPER="$(realpath "$HYBPIPDIR")" || operationfailed # Full path to HybPiper directory
BAITFILEF="$(realpath "$BAITFILE")" || operationfailed # Full path to HybSeq reference

# Post-processing, summary, statistics
echo "Summary"
python2 "$HYBPIPER"/get_seq_lengths.py "$BAITFILEF" "$SAMPLES" dna > seq_lengths.txt || operationfailed
echo
echo "Statistics"
python2 "$HYBPIPER"/hybpiper_stats.py seq_lengths.txt "$SAMPLES" > stats.txt || operationfailed
echo

# Plotting gene recovery heatmaps
echo "Plotting gene recovery heatmaps"
cp "$HYBPIPER"/*.R . || operationfailed
R CMD BATCH --no-save --no-restore gene_recovery_heatmap.R gene_recovery_heatmap_gplot.rlog || operationfailed
R CMD BATCH --no-save --no-restore gene_recovery_heatmap_ggplot.R gene_recovery_heatmap_ggplot2.rlog || operationfailed
echo

# Fetch the sequences recovered from the same gene for many samples and generates an unaligned multi-FASTA file for each gene
echo "Retrieving sequences"
echo
echo "Exons"
echo
python2 "$HYBPIPER"/retrieve_sequences.py "$BAITFILEF" . dna || operationfailed
echo
echo "Introns"
echo
python2 "$HYBPIPER"/retrieve_sequences.py "$BAITFILEF" . intron || operationfailed
echo
echo "Supercontigs"
echo
python2 "$HYBPIPER"/retrieve_sequences.py "$BAITFILEF" . supercontig || operationfailed
echo

# Removing ".dedup*" from accession names
echo "Removing \".dedup*\" from accession names"
sed -i 's/\.dedup.*$//g' *.{FNA,fasta}
echo

# Removing input data
echo "Removing input directories and unneeded files"
while read -r SAMPLE; do rm -rf "$SAMPLE"*; done < "$SAMPLES"
rm -rf HybPiper HybPiper.* hybseq_hybpiper.*.dedup.log hybseq_3_hybpiper_postprocess_2_run.sh ref rpackages Rplots.pdf *.R samples_list.txt

exit

