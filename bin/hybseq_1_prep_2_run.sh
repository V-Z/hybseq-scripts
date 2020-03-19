#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Process all files in the working directory (named *.R[12].fq[.bz2]) to be ready for HybPiper (trimming, deduplication, statistics, quality checks).

# See './hybseq_1_prep_2_run.sh -h' for help.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Initialize variables
FQDIR='' # Input directory - it MUST contain directories named according to individuals and containing F and R FASTQ1 files for respective individual
COUNTFASTQ='' # Test if input directory contains FASTQ1 files
NUMTEST='^[0-9]+$' # Testing if provided value is an integer
NCPU='' # Number of CPU threads for parallel operations
TRIMDIR='' # Output directory for trimmed sequences
DEDUPDIR='' # Output directory for deduplicated sequences
QUALDIR='' # Output directory for quality reports
ADAPTOR='' # Path to FASTA file containing adaptor(s)
JAVA='' # PATH to custom Java binary
MEM='' # Memory limit for Trimmomatic and Clumpify
TRIMMOMATIC='' # Path to Trimmomatic JAR file
FASTQ1='' # Input, forward
FASTQ2='' # Input, reverse (forward is in ${FASTQ1})
FASTQ='' # Base name
TRM1='' # Trimmed, forward
TRM2='' # Trimmed, reverse
UNP1='' # Unpaired, forward
UNP2='' # Unpaired, reverse
NODUP1='' # Without duplicates, forward
NODUP2='' # Without duplicates, reverse
echo

# Parse initial arguments
while getopts "hrvf:c:o:d:q:a:j:m:t:" INITARGS; do
	case "${INITARGS}" in
		h) # Help and exit
			echo "Usage options:"
			echo -e "\t-h\tPrint this help and exit."
			echo -e "\t-r\tPrint references to used software and exit."
			echo -e "\t-v\tPrint script version, author and license and exit."
			echo -e "\t-f\tInput directory with FASTQ files saved as \"*.R[12].fq.*\"."
			echo -e "\t-c\tNumber of CPU threads to use for parallel operations. If not provided, default is 4."
			echo -e "\t-o\tOutput directory for trimmed sequences. It should be empty."
			echo -e "\t-o\tOutput directory for deduplicated sequences. It should be empty."
			echo -e "\t-o\tOutput directory for quality reports. It should be empty."
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
			if [ -d "${OPTARG}" ]; then
				COUNTFASTQ=$(find "${OPTARG}" -name "*.R[12].f*q*" | wc -l)
				if [ "${COUNTFASTQ}" != 0 ]; then
					FQDIR="${OPTARG}"
					echo "Input directory: ${FQDIR}"
					echo
					else
						echo "Error! Given input directory does not contain any FASTQ files named \"*.R[12].f*q.*\"!"
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
			if [ -d "${OPTARG}" ]; then
				TRIMDIR="${OPTARG}"
				echo "Output directory for trimmed sequences: ${TRIMDIR}"
				echo
				else
					echo "Output directory for trimmed sequences ${TRIMDIR} doesn't exist - creating 'trimmed'."
					TRIMDIR='trimmed'
					mkdir "${TRIMDIR}" || { echo "Error! Can't create ${TRIMDIR}!"; echo; exit 1; }
					echo
					fi
			;;
		d) # Output directory for deduplicated sequences
			if [ -d "${OPTARG}" ]; then
				DEDUPDIR="${OPTARG}"
				echo "Output directory for deduplicated sequences: ${DEDUPDIR}"
				echo
				else
					echo "Output directory for deduplicated sequences ${DEDUPDIR} doesn't exist - creating 'dedup'."
					DEDUPDIR='dedup'
					mkdir "${DEDUPDIR}" || { echo "Error! Can't create ${DEDUPDIR}!"; echo; exit 1; }
					echo
					fi
			;;
		q) # Output directory for quality reports
			if [ -d "${OPTARG}" ]; then
				QUALDIR="${OPTARG}"
				echo "Output directory for quality reports: ${QUALDIR}"
				echo
				else
					echo "Output directory for quality reports ${QUALDIR} doesn't exist - creating 'qual_rep'."
					QUALDIR='qual_rep'
					mkdir "${QUALDIR}" || { echo "Error! Can't create ${QUALDIR}!"; echo; exit 1; }
					echo
					fi
			;;
		a) # FASTA file containing adaptor(s)
			if [ -r "${OPTARG}" ]; then
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
			if [ -x "${OPTARG}" ]; then
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
			if [ -r "${OPTARG}" ]; then
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

toolcheck xargs
toolcheck clumpify.sh
toolcheck fastqc
toolcheck parallel

# Checking if all required parameters are provided
if [ -z "${FQDIR}" ]; then
	echo "Error! Input directory with FASTQ1 files (-f) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [ -z "${NCPU}" ]; then
	echo "Number of CPU threads (-c) for parallel operations was not set. Using default value of 4."
	echo
	NCPU='4'
	fi

if [ -z "${TRIMDIR}" ]; then
	echo "Error! Output directory for trimmed sequences (-o) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [ -z "${DEDUPDIR}" ]; then
	echo "Error! Output directory for deduplicated sequences (-d) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [ -z "${QUALDIR}" ]; then
	echo "Error! Output directory for quality reports (-q) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [ -z "${ADAPTOR}" ]; then
	echo "Error! Adaptor file (-a) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

if [ -z "${JAVA}" ]; then
	toolcheck java
	echo "Path to custom Java executable (-j) was not specified. Using default $(command -v java)"
	JAVA="$(command -v java)"
	echo
	fi

if [ -z "${MEM}" ]; then
	echo "Memory consumption per core (-m) was not set. Using default value of 2 GB per core."
	MEM='2'
	echo
	fi

if [ -z "${TRIMMOMATIC}" ]; then
	echo "Error! Path to Trimmomatic JAR file (-t) was not specified!"
	echo "See usage options: \"$0 -h\""
	echo
	exit 1
	fi

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

# Initialize file with statistics
echo "Initializing files with statistics"
printf "Individual\tR1_input\tR2_input\tR1_paired_reads\tR2_paired_reads\tR1_unpaired_reads\tR2_unpaired_reads\n" > "${TRIMDIR}"/report_trimming.tsv || operationfailed
printf "Individual\tR1_input\tR2_input\tR1_paired_reads\tR2_paired_reads\tR1_filtered_reads\tR2_filtered_reads\n" > "${DEDUPDIR}"/report_filtering.tsv || operationfailed
echo

# Decompress FASTQ files
echo "Decompressing FASTQ files at $(date)"
parallel -j "${NCPU}" -X bunzip2 -v ::: "${FQDIR}"/*.bz2
echo

# Process all files
for FASTQ1 in "${FQDIR}"/*.R1.f*q*; do
	# Names - variables
	FASTQ2="${FASTQ1//\.R1\./.R2.}" # Input, reverse (forward is in ${FASTQ1})
	FASTQ="${FASTQ1%.R1.f*q*}" # Base name
	TRM1="$(basename "${FASTQ}.trm.R1.fq")" # Trimmed, forward
	TRM2="$(basename "${FASTQ}.trm.R2.fq")" # Trimmed, reverse
	UNP1="$(basename "${FASTQ}.unp.R1.fq")" # Unpaired, forward
	UNP2="$(basename "${FASTQ}.unp.R2.fq")" # Unpaired, reverse
	NODUP1="$(basename "${FASTQ}.dedup.R1.fq")" # Without duplicates, forward
	NODUP2="$(basename "${FASTQ}.dedup.R2.fq")" # Without duplicates, reverse

	echo "Processing ${FASTQ} at $(date)"
	echo

	# Pre-processing of the reads
	echo "Trimming"
	# Trimming and adaptor removal with Trimmomatic
	${JAVA} -Xmx"$((MEM*NCPU))"g -jar "${TRIMMOMATIC}" PE -threads "$((NCPU-1))" -phred33 "${FASTQ1}" "${FASTQ2}" "${TRIMDIR}"/"${TRM1}" "${TRIMDIR}"/"${UNP1}" "${TRIMDIR}"/"${TRM2}" "${TRIMDIR}"/"${UNP2}" ILLUMINACLIP:"${ADAPTOR}":2:30:10 SLIDINGWINDOW:5:20 LEADING:20 TRAILING:20 MINLEN:50 || operationfailed
	echo

	# Trimming statistics
	echo "Trimming statistics"
	{ printf '%s\t' "${FASTQ}" # Print sample name
		echo "$(($(wc -l "${FASTQ1}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of input R1 reads (N of lines /4)
		echo "$(($(wc -l "${FASTQ2}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of input R2 reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${TRM1}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of trimmed R1 reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${TRM2}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of trimmed R2 reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${UNP1}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of unpaired R1 reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${UNP2}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of unpaired R2 reads (N of lines /4)
		printf '\n'
		} >> "${TRIMDIR}"/report_trimming.tsv || operationfailed
	echo

	# Filtering of identical reads with BBmap
	echo "Filtering identical reads"
	clumpify.sh in="${TRIMDIR}"/"${TRM1}" in2="${TRIMDIR}"/"${TRM2}" out="${DEDUPDIR}"/"${NODUP1}" out2="${DEDUPDIR}"/"${NODUP2}" dedupe optical spany adjacent -Xmx"$((MEM*NCPU))"g || operationfailed
	echo

	# Filtering statistics
	echo "Filtering statistics"
	{ printf '%s\t' "${FASTQ}" # Print sample name
		echo "$(($(wc -l "${FASTQ1}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of input R1 reads (N of lines /4)
		echo "$(($(wc -l "${FASTQ2}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of input R2 reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${TRM1}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of trimmed R1 reads (N of lines /4)
		echo "$(($(wc -l "${TRIMDIR}"/"${TRM2}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of trimmed R2 reads (N of lines /4)
		echo "$(($(wc -l "${DEDUPDIR}"/"${NODUP1}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of deduplicated R1 reads (N of lines /4)
		echo "$(($(wc -l "${DEDUPDIR}"/"${NODUP2}" | cut -f 1 -d ' ')/4))" | xargs printf '%s\t%s' # No of deduplicated R2 reads (N of lines /4)
		printf '\n'
		} >> "${DEDUPDIR}"/report_filtering.tsv || operationfailed
	echo

	# Quality reports
	echo "Quality reports"
	fastqc -o "${QUALDIR}" -t "${NCPU}" "${FASTQ1}" "${FASTQ2}" "${TRIMDIR}"/"${TRM1}" "${TRIMDIR}"/"${TRM2}" "${DEDUPDIR}"/"${NODUP1}" "${DEDUPDIR}"/"${NODUP2}" || operationfailed
	echo
	done

# Creating list of samples for HybPiper
echo "Creating list of samples"
find "${DEDUPDIR}"/ -name "*.R1.*" -printf "%f\n" | sed 's/\.R1.fq$//' > "${DEDUPDIR}"/samples_list.txt || operationfailed
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

