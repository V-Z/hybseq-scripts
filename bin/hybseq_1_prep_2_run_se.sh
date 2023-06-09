#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Process all files in the working directory (named *.fq[.bz2]) to be ready for HybPiper (trimming, deduplication, statistics, quality checks).

# See './hybseq_1_prep_2_run.sh -h' for help.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

################################################################################
# Processing user input
# Do not edit this section unless you are very sure what you are doing - edits, if needed, are expected only in the last section
# Sections of the code where edits are to be expected are marked by "NOTE" in comments (see below)
################################################################################

# Initialize variables
FQDIR='' # Input directory - it MUST contain FASTQ files for samples
COUNTFASTQ='' # Test if input directory contains FASTQ files
NUMTEST='^[0-9]+$' # Testing if provided value is an integer
NCPU='' # Number of CPU threads for parallel operations
TRIMDIR='' # Output directory for trimmed sequences
DEDUPDIR='' # Output directory for deduplicated sequences
QUALDIR='' # Output directory for quality reports
ADAPTOR='' # Path to FASTA file containing adaptor(s)
JAVA='' # PATH to custom Java binary
MEM='' # Memory limit for Trimmomatic and Clumpify
TRIMMOMATIC='' # Path to Trimmomatic JAR file
FASTQF='' # Input
FASTQ='' # Base name
TRM='' # Trimmed
NODUP='' # Without duplicates
echo

# Parse initial arguments
while getopts "hrvf:c:o:d:q:a:j:m:t:" INITARGS; do
	case "${INITARGS}" in
		h) # Help and exit
			echo "Usage options:"
			echo -e "\t-h\tPrint this help and exit."
			echo -e "\t-r\tPrint references to used software and exit."
			echo -e "\t-v\tPrint script version, author and license and exit."
			echo -e "\t-f\tInput directory with FASTQ files saved as \"*.fq.*\"."
			echo -e "\t-c\tNumber of CPU threads to use for parallel operations. If not provided, default is 4."
			echo -e "\t-o\tOutput directory for trimmed sequences. It should be empty."
			echo -e "\t-d\tOutput directory for deduplicated sequences. It should be empty."
			echo -e "\t-q\tOutput directory for quality reports. It should be empty."
			echo -e "\t-a\tFASTA file with adaptors."
			echo -e "\t-j\tOptional path to custom Java binary. If not provided, default is output of \$(command -v java)."
			echo -e "\t-m\tMaximal memory consumption allowed per CPU core. It must be in GB and it will be multiplied by number of cores. Input integer, e.g. 2. If not provided, default is 2."
			echo -e "\t-t\tTrimmomatic JAR file."
			echo
			exit
			;;
		r) # References to cite and exit
			echo "Software to cite:"
			echo "* BBmap, https://sourceforge.net/projects/bbmap/"
			echo "* FastQC, https://www.bioinformatics.babraham.ac.uk/projects/fastqc/"
			echo "* GNU Parallel, https://www.gnu.org/software/parallel/"
			echo "* Java, https://java.com/ or http://openjdk.java.net/"
			echo "* Trimmomatic, http://www.usadellab.org/cms/?page=trimmomatic"
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
		f) # Input directory with compressed FASTQ files to be processed
			if [[ -d "${OPTARG}" ]]; then
				COUNTFASTQ=$(find "${OPTARG}" -name "*.f*q*" | wc -l)
				if [[ "${COUNTFASTQ}" != 0 ]]; then
					FQDIR="${OPTARG}"
					echo "Input directory: ${FQDIR}"
					echo
					else
						echo "Error! Given input directory does not contain any FASTQ files named \"*.f*q.*\"!"
						echo
						exit 1
						fi
				else
					echo "Error! You did not provide path to input directory with FASTQ files (-f) \"${OPTARG}\"!"
					echo
					exit 1
					fi
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
		o) # Output directory for trimmed sequences
			if [[ -d "${OPTARG}" ]]; then
				TRIMDIR="${OPTARG}"
				echo "Output directory for trimmed sequences: ${TRIMDIR}"
				echo
				elif [[ -n "${OPTARG}" ]]; then
					TRIMDIR="${OPTARG}"
					echo "Output directory for trimmed sequences ${TRIMDIR} doesn't exist (-o) - creating it."
					mkdir -p "${TRIMDIR}" || { echo "Error! Can't create ${TRIMDIR}!"; echo; exit 1; }
					else
						TRIMDIR='1_trimmed'
						echo "Output directory for trimmed sequences ${TRIMDIR} doesn't exist - creating '1_trimmed'."
						mkdir "${TRIMDIR}" || { echo "Error! Can't create ${TRIMDIR}!"; echo; exit 1; }
					echo
				fi
			;;
		d) # Output directory for deduplicated sequences
			if [[ -d "${OPTARG}" ]]; then
				DEDUPDIR="${OPTARG}"
				echo "Output directory for deduplicated sequences: ${DEDUPDIR}"
				echo
				elif [[ -n "${OPTARG}" ]]; then
					DEDUPDIR="${OPTARG}"
					echo "Output directory for deduplicated sequences ${DEDUPDIR} doesn't exist (-o) - creating it."
					mkdir -p "${DEDUPDIR}" || { echo "Error! Can't create ${DEDUPDIR}!"; echo; exit 1; }
					else
						DEDUPDIR='2_dedup'
						echo "Output directory for deduplicated sequences ${DEDUPDIR} doesn't exist - creating '2_dedup'."
						mkdir "${DEDUPDIR}" || { echo "Error! Can't create ${DEDUPDIR}!"; echo; exit 1; }
					echo
				fi
			;;
		q) # Output directory for quality reports
			if [[ -d "${OPTARG}" ]]; then
				QUALDIR="${OPTARG}"
				echo "Output directory for quality reports: ${QUALDIR}"
				echo
				elif [[ -n "${OPTARG}" ]]; then
					QUALDIR="${OPTARG}"
					echo "Output directory for quality reports ${QUALDIR} doesn't exist (-o) - creating it."
					mkdir -p "${QUALDIR}" || { echo "Error! Can't create ${QUALDIR}!"; echo; exit 1; }
					else
						QUALDIR='3_qual_rep'
						echo "Output directory for quality reports ${QUALDIR} doesn't exist - creating '3_qual_rep'."
						mkdir "${QUALDIR}" || { echo "Error! Can't create ${QUALDIR}!"; echo; exit 1; }
					echo
				fi
			;;
		a) # FASTA file containing adaptor(s)
			if [[ -r "${OPTARG}" ]]; then
				ADAPTOR=$(realpath "${OPTARG}")
				echo "Adaptor(s) FASTA file: ${ADAPTOR}"
				echo
				else
					echo "Error! You did not provide path to FASTA file with adaptor(s) (-a) \"${OPTARG}\"!"
					echo
					exit 1
					fi
			;;
		j) # Path to custom Java binary
			if [[ -x "${OPTARG}" ]]; then
			JAVA="${OPTARG}"
			echo "Custom Java binary: ${JAVA}"
			echo
			else
				echo "Error! You did not provide path to custom Java binary (-j) \"${OPTARG}\"!"
				echo
				exit 1
				fi
			;;
		m) # Maximal Java memory consumption per core
			if [[ ${OPTARG} =~ ${NUMTEST} ]]; then
			MEM="${OPTARG}"
			echo "Maximal memory consumption per CPU core: ${MEM} GB"
			echo
			else
				echo "Error! You did not provide correct maximal memory consumption per CPU core in GB (-m), e.g. 8, \"${OPTARG}\"!"
				echo
				exit 1
				fi
			;;
		t) # Path to Trimmomatic JAR file
			if [[ -r "${OPTARG}" ]]; then
			TRIMMOMATIC="${OPTARG}"
			echo "Trimmomatic JAR file: ${TRIMMOMATIC}"
			echo
			else
				echo "Error! You did not provide path to Trimmomatic JAR file (-t) \"${OPTARG}\"!"
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

# Check if all required binaries are available
function toolcheck {
	command -v "$1" >/dev/null 2>&1 || {
		echo >&2 "Error! $1 is required but not installed. Aborting. Please, install it."
		echo
		exit 1
		}
	}

################################################################################
# Checking if all required parameters are provided
################################################################################

toolcheck xargs
toolcheck clumpify.sh
toolcheck fastqc
toolcheck parallel

# Checking if all required parameters are provided
if [[ -z "${FQDIR}" ]]; then
	echo "Error! Input directory with FASTQ files (-f) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [[ -z "${NCPU}" ]]; then
	echo "Number of CPU threads (-c) for parallel operations was not set. Using default value of 4."
	echo
	NCPU='4'
	fi

if [[ -z "${TRIMDIR}" ]]; then
	echo "Error! Output directory for trimmed sequences (-o) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [[ -z "${DEDUPDIR}" ]]; then
	echo "Error! Output directory for deduplicated sequences (-d) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [[ -z "${QUALDIR}" ]]; then
	echo "Error! Output directory for quality reports (-q) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [[ -z "${ADAPTOR}" ]]; then
	echo "Error! Adaptor file (-a) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [[ -z "${JAVA}" ]]; then
	toolcheck java
	echo "Path to custom Java executable (-j) was not specified. Using default $(command -v java)"
	JAVA="$(command -v java)"
	echo
	fi

if [[ -z "${MEM}" ]]; then
	echo "Memory consumption per core (-m) was not set. Using default value of 2 GB per core."
	MEM='2'
	echo
	fi

if [[ -z "${TRIMMOMATIC}" ]]; then
	echo "Error! Path to Trimmomatic JAR file (-t) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

################################################################################
# End of processing of user input and checking if all required parameters are provided
################################################################################

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
# The calculation
################################################################################

# Initialize file with statistics
echo "Initializing files with statistics"
printf "Individual\tinput\ttrimmed\n" > "${TRIMDIR}"/report_trimming.tsv || operationfailed
printf "Individual\tinput\ttrimmed\tfiltered\n" > "${DEDUPDIR}"/report_filtering.tsv || operationfailed
echo

# Decompress FASTQ files
echo "Decompressing FASTQ files at $(date)"
if [[ -n "$(find "${FQDIR}" -name '*.gz')" ]]; then
	echo "Files are compressed by gzip"
	parallel -j "${NCPU}" -X gunzip -v ::: "${FQDIR}"/*.gz
	elif [[ -n "$(find "${FQDIR}" -name '*.bz2')" ]]; then
		echo "Files are compressed by bzip2"
		parallel -j "${NCPU}" -X bunzip2 -v ::: "${FQDIR}"/*.bz2
	fi
echo

# Process all files
for FASTQF in "${FQDIR}"/*.f*q*; do
	# Names - variables
	FASTQ="${FASTQF%.f*q*}" # Base name
	TRM="$(basename "${FASTQ}.trm.fq")" # Trimmed
	NODUP="$(basename "${FASTQ}.dedup.fq")" # Without duplicates
	echo "Processing ${FASTQ} at $(date)"
	echo

	# Pre-processing of the reads
	echo "Trimming"
	# Trimming and adaptor removal with Trimmomatic
	${JAVA} -Xmx"$((MEM*NCPU))"g -jar "${TRIMMOMATIC}" SE -threads "$((NCPU-1))" -phred33 "${FASTQF}" "${TRIMDIR}"/"${TRM}" ILLUMINACLIP:"${ADAPTOR}":2:30:10 SLIDINGWINDOW:5:20 LEADING:20 TRAILING:20 MINLEN:50 || operationfailed
	echo

	# Trimming statistics
	echo "Trimming statistics"
	{ printf '%s\t' "${FASTQ}" # Print sample name
		echo "$(($(wc -l "${FASTQF}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of input reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${TRM}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of trimmed reads (N of lines /4)
		printf '\n'
		} >> "${TRIMDIR}"/report_trimming.tsv || operationfailed
	echo

	# Filtering of identical reads with BBmap
	echo "Filtering identical reads"
	clumpify.sh in="${TRIMDIR}"/"${TRM}" out="${DEDUPDIR}"/"${NODUP}" dedupe optical spany adjacent -Xmx"$((MEM*NCPU))"g || operationfailed
	echo

	# Filtering statistics
	echo "Filtering statistics"
	{ printf '%s\t' "${FASTQ}" # Print sample name
		echo "$(($(wc -l "${FASTQF}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of input reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${TRM}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of trimmed reads (N of lines /4)
		echo "$(($(wc -l "${DEDUPDIR}"/"${NODUP}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of deduplicated reads (N of lines /4)
		printf '\n'
		} >> "${DEDUPDIR}"/report_filtering.tsv || operationfailed
	echo

	# Quality reports
	echo "Quality reports"
	fastqc -o "${QUALDIR}" -t "${NCPU}" "${FASTQF}" "${TRIMDIR}"/"${TRM}" "${DEDUPDIR}"/"${NODUP}" || operationfailed
	echo
	done

# Creating list of samples for HybPiper
echo "Creating list of samples"
find "${DEDUPDIR}"/ -name "*.R1.*" -printf "%f\n" | sed 's/\.R1.fq$//' | sort > "${DEDUPDIR}"/samples_list.txt || operationfailed
echo

# Final messages
echo "Trimmed sequences are in directory ${TRIMDIR} and trimming statistics in file ${TRIMDIR}/report_trimming.tsv"
echo "Deduplicated sequences are in directory ${DEDUPDIR} and deduplication statistics in file ${DEDUPDIR}/report_filtering.tsv"
echo "FastQC statistics are in directory ${QUALDIR} - open respective *.html files."
echo "List of samples for HybPiper is in file ${DEDUPDIR}/samples_list.txt"
echo

# Compress FASTQ files
echo "Compressing FASTQ files at $(date)"
find . -name "*.f*q" -print | parallel -j "${NCPU}" bzip2 -v9 '{}' || operationfailed
echo

exit

