#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Process individual files provided by hybseq_2_hybpiper_2_qsub.sh (named *.R[12].fq[.bz2]) by the HybPiper pipeline.

# See './hybseq_2_hybpiper_3_run.sh -h' for help.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Initialize variables
NUMTEST='^[0-9]+$' # Testing if provided value is an integer
NCPU='' # Number of CPU threads for parallel operations
echo

# Parse initial arguments
while getopts "hvp:b:s:c:" INITARGS; do
	case "${INITARGS}" in
		h) # Help and exit
			echo "Usage options:"
			echo -e "\t-h\tPrint this help and exit."
			echo -e "\t-v\tPrint script version, author and license and exit."
			echo -e "\t-p\tDirectory with HybPiper. E.g. xxx/bin/HybPiper"
			echo -e "\t-b\tReference bait FASTA file. E.g. ref/xxx.fasta"
			echo -e "\t-s\tBase name of sample to process. E.g. sample_x.dedup for pair of files sample_x.dedup.R1.fq.bz2 and sample_x.dedup.R2.fq.bz2."
			echo -e "\t-c\tNumber of CPU threads to use for parallel operations. If not provided, default is 8."
			echo
			exit
			;;
		v) # Print script version and exit
			echo "Version: 1.0"
			echo "Author: Vojtěch Zeisek, https://trapa.cz/en"
			echo "License: GNU GPLv3, https://www.gnu.org/licenses/gpl-3.0.html"
			echo
			exit
			;;
		p) # Directory with HybPiper
			if [ -d "${OPTARG}" ]; then
			HYBPIPER="$(realpath "${OPTARG}")"
			echo "Path to HybPiper directory: ${HYBPIPER}"
			echo
			else
				echo "Error! You did not provide path to HybPiper directory (-p) \"${OPTARG}\"!"
				echo
				exit 1
				fi
			;;
		b) # Reference bait FASTA file
			if [ -r "${OPTARG}" ]; then
				BAITFILE="$(realpath "${OPTARG}")"
				echo "Reference bait FASTA file: ${BAITFILE}"
				echo
				else
					echo "Error! You did not provide path to reference bait FASTA file (-b) \"${OPTARG}\"!"
					echo
					exit 1
					fi
			;;
		s) # List of samples to process
			for F in "${OPTARG}".*; do
				if [ ! -r "${F}" ]; then
					echo "Error! You did not provide sample to process (-s) \"${OPTARG}\"!"
					echo
					exit 1
					fi
				done
				SAMPLES="${OPTARG}"
				echo "Sample to process: ${SAMPLES}"
				echo
			;;
		c) # Number of CPU threads for parallel processing
			if [[ ${OPTARG} =~ ${NUMTEST} ]]; then
				NCPU="${OPTARG}"
				echo "Number of CPU threads: ${NCPU}"
				echo
				else
					echo "Error! As number of CPU threads (-c) \"${OPTARG}\" you did not provide a number!"
					echo
					exit 1
					fi
			;;
		*)
			echo "Error! Unknown option!"
			echo "See usage options: \"$0 -h\""
			echo
			exit 1
			;;
		esac
	done

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

# Testing dependencies
echo "Checking if all required software is available"
python2 "${HYBPIPER}"/reads_first.py --check-depend || operationfailed
echo

# Check if all required binaries are available
function toolcheck {
	command -v "${1}" >/dev/null 2>&1 || {
		echo >&2 "Error! ${1} is required but not installed. Aborting. Please, install it."
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

# Checking if all required parameters are provided
if [ -z "${HYBPIPER}" ]; then
	echo "Error! Directory with HybPiper not provided!"
	operationfailed
	fi
if [ -z "${BAITFILE}" ]; then
	echo "Error! Reference bait FASTA file not provided!"
	operationfailed
	fi
if [ -z "${SAMPLES}" ]; then
	echo "Error! List of samples to process not provided!"
	operationfailed
	fi
if [ -z "${NCPU}" ]; then
	echo "Number of CPU threads (-c) for parallel operations was not set. Using default value of 8."
	echo
	NCPU='8'
	fi

# Decompressing FASTQ sequences
echo "Decompressing FASTQ sequences at $(date)"
parallel -X bunzip2 -v ::: *.bz2
echo

# Processing the sample by HybPiper
echo "Processing ${SAMPLES} at $(date)"
echo
echo "Main processing"
echo
python2 "${HYBPIPER}"/reads_first.py --bwa -r "${SAMPLES}".R{1,2}.fq -b "${BAITFILE}" --cpu "${NCPU}" --prefix "${SAMPLES}" || operationfailed
echo
echo "Paralogs"
echo
python2 "${HYBPIPER}"/paralog_investigator.py "${SAMPLES}" || operationfailed
echo
echo "Introns"
echo
python2 "${HYBPIPER}"/intronerate.py --prefix "${SAMPLES}" --addN || operationfailed
echo
echo "Depth"
echo
python2 "${HYBPIPER}"/depth_calculator.py --targets "${BAITFILE}" -r "${SAMPLES}".R{1,2}.fq --prefix "${SAMPLES}" || operationfailed
echo
echo "Cleanup"
echo
python2 "${HYBPIPER}"/cleanup.py "${SAMPLES}" || operationfailed
echo

exit

