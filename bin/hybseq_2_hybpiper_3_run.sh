#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Process individual files provided by hybseq_2_hybpiper_2_qsub.sh (named *.R[12].fq[.bz2]) by the HybPiper pipeline.

# See './hybseq_2_hybpiper_3_run.sh -h' for help.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

################################################################################
# Processing user input
# Do not edit this section unless you are very sure what you are doing - edits, if needed, are expected only in the last section
# Sections of the code where edits are to be expected are marked by "NOTE" in comments (see below)
################################################################################

# Initialize variables
NUMTEST='^[0-9]+$' # Testing if provided value is an integer
NCPU='' # Number of CPU threads for parallel operations
echo

# Parse initial arguments
while getopts "hvb:s:c:" INITARGS; do
	case "${INITARGS}" in
		h) # Help and exit
			echo "Usage options:"
			echo -e "\t-h\tPrint this help and exit."
			echo -e "\t-v\tPrint script version, author and license and exit."
			echo -e "\t-b\tReference bait FASTA file. E.g. ref/xxx.fasta"
			echo -e "\t-s\tBase name of sample to process. E.g. sample_x.dedup for pair of files sample_x.dedup.R1.fq.bz2 and sample_x.dedup.R2.fq.bz2."
			echo -e "\t-c\tNumber of CPU threads to use for parallel operations. If not provided, default is 8."
			echo
			exit
			;;
		v) # Print script version and exit
			echo "Version: 2.0"
			echo "Author: Vojtěch Zeisek, https://trapa.cz/en"
			echo "License: GNU GPLv3, https://www.gnu.org/licenses/gpl-3.0.html"
			echo
			exit
			;;
		b) # Reference bait FASTA file
			if [[ -r "${OPTARG}" ]]; then
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
				if [[ ! -r "${F}" ]]; then
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

################################################################################
# Checking if all required parameters are provided
################################################################################

# Checking if all required parameters are provided
if [[ -z "${BAITFILE}" ]]; then
	echo "Error! Reference bait FASTA file not provided!"
	operationfailed
	fi
if [[ -z "${SAMPLES}" ]]; then
	echo "Error! List of samples to process not provided!"
	operationfailed
	fi
if [[ -z "${NCPU}" ]]; then
	echo "Number of CPU threads (-c) for parallel operations was not set. Using default value of 8."
	echo
	NCPU='8'
	fi

################################################################################
# End of processing of user input and checking if all required parameters are provided
################################################################################

################################################################################
# The calculation
################################################################################

# Decompressing FASTQ sequences
echo "Decompressing FASTQ sequences at $(date)"
parallel -X bunzip2 -v ::: *.bz2
echo

# Processing the sample by HybPiper
echo "Processing ${SAMPLES} at $(date)"
echo

################################################################################
# NOTE On Czech MetaCentrum, HybPiper is installed as Apptainer (Singularity) container, see https://docs.metacentrum.cz/software/containers/
# Container starts its own shell, so that it is loaded right before usage of HybPiper - see code below
# run_in_os loads HybPiper/HybPiper-2.1.5.sif container and '<<END' marks "here document" containing block of HybPiper (within container) commands (ends with 'END')
# If HybPiper is installed differently on your cluster, edit code below or section loading modules in hybseq_2_hybpiper_2_qsub.sh
# NOTE Possible edit HybPiper parameters here, see https://github.com/mossmatters/HybPiper/wiki/Full-pipeline-parameters
# NOTE Use variant of "hybpiper assemble" appropriate for pair-end (forward and reverse)/single-end FASTQ files
################################################################################

run_in_os  HybPiper/HybPiper-2.1.5.sif <<END
module add mambaforge
mamba activate /conda/envs/hybpiper-2.1.5
# Pair-end (forward and reverse) FASTQ files
hybpiper assemble --readfiles "${SAMPLES}".R{1,2}.fq --targetfile_dna "${BAITFILE}" --bwa --cpu "${NCPU}" --prefix "${SAMPLES}" --run_intronerate
# Single-end FASTQ files
# hybpiper assemble --readfiles "${SAMPLES}".fq --targetfile_dna "${BAITFILE}" --bwa --cpu "${NCPU}" --prefix "${SAMPLES}" --run_intronerate
END
echo

exit

