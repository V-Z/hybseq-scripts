#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Process individual files provided by hybseq_2_hybpiper_2_qsub.sh (named *.R[12].fq[.bz2]) by the HybPiper pipeline.
# 4 positional arguments: (1) base name of the input files name; (2) path to HybPiper directory; (3) bait file (HybSeq reference); (4) number of CPU threads.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Processing variables
# Get full paths
HYBPIP="$(realpath "$2")" # Full path to HybPiper directory
BAITF="$(realpath "$3")" # Full path to HybSeq reference

# TODO Parse initial arguments

# Testing dependencies
echo "Checking if all required software is available"
python2 "${HYBPIP}"/reads_first.py --check-depend || exit 1
echo

# Check if all required binaries are available
function toolcheck {
	command -v "$1" >/dev/null 2>&1 || {
		echo >&2 "Error! $1 is required but not installed. Aborting. Please, install it."
		echo
		exit 1
		}
	}

toolcheck python2
toolcheck parallel
toolcheck bunzip2
toolcheck exonerate
toolcheck blastx
toolcheck makeblastdb
toolcheck spades.py
toolcheck bwa
toolcheck samtools

# TODO Checking if all required variables are provided
if [ "$#" -ne '4' ]; then
	echo "Error! Exactly 4 parameters are required! $# received."
	exit 1
	fi

# Decompressing FASTQ sequences
echo "Decompressing FASTQ sequences at $(date)"
parallel -X bunzip2 -v ::: *.bz2
echo

# Processing the sample by HybPiper
echo "Processing $1 at $(date)"
echo
echo "Main processing"
echo
python2 "${HYBPIP}"/reads_first.py --bwa -r "$1".R{1,2}.fq -b "${BAITF}" --cpu "$4" --prefix "$1" || { export CLEAN_SCRATCH='false'; exit 1; }
echo
echo "Paralogs"
echo
python2 "${HYBPIP}"/paralog_investigator.py "$1" || { export CLEAN_SCRATCH='false'; exit 1; }
echo
echo "Introns"
echo
python2 "${HYBPIP}"/intronerate.py --prefix "$1" --addN || { export CLEAN_SCRATCH='false'; exit 1; }
echo
echo "Depth"
echo
python2 "${HYBPIP}"/depth_calculator.py --targets "${BAITF}" -r "$1".R{1,2}.fq --prefix "$1" || { export CLEAN_SCRATCH='false'; exit 1; }
echo
echo "Cleanup"
echo
python2 "${HYBPIP}"/cleanup.py "$1" || { export CLEAN_SCRATCH='false'; exit 1; }
echo

exit

