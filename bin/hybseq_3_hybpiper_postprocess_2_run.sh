#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Process all sample directories in the working directory by the HybPiper pipeline - extracts contigs and calculates statistics.

# See './hybseq_3_hybpiper_postprocess_2_run.sh -h' for help.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Parse initial arguments
while getopts "hvp:b:s:" INITARGS; do
	case "${INITARGS}" in
		h) # Help and exit
			echo "Usage options:"
			echo -e "\t-h\tPrint this help and exit."
			echo -e "\t-v\tPrint script version, author and license and exit."
			echo -e "\t-p\tDirectory with HybPiper. E.g. xxx/bin/HybPiper"
			echo -e "\t-b\tReference bait FASTA file. E.g. ref/xxx.fasta"
			echo -e "\t-s\tList of samples to process. E.g. samples_list.txt"
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
			if [[ -r "${OPTARG}" ]]; then
			SAMPLES="${OPTARG}"
			echo "List of samples to process: ${SAMPLES}"
			echo
			else
				echo "Error! You did not provide list of samples to process (-s) \"${OPTARG}\"!"
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

# Checking if all required variables are provided
if [[ -z "${BAITFILE}" ]]; then
	echo "Error! Reference bait FASTA file not provided!"
	operationfailed
	fi
if [[ -z "${SAMPLES}" ]]; then
	echo "Error! List of samples to process not provided!"
	operationfailed
	fi

run_in_os  HybPiper/HybPiper-2.1.3.sif <<END
module add mambaforge
mamba activate /conda/envs/hybpiper-2.1.3
echo "Summary statistics"
echo
hybpiper stats --targetfile_dna "${BAITFILE}" gene samples_list.txt
echo
echo "Plotting gene recovery heatmap"
echo
hybpiper recovery_heatmap seq_lengths.tsv
echo
# Fetch the sequences recovered from the same gene for many samples and generates an unaligned multi-FASTA file for each gene
echo "Retrieving sequences"
echo
echo "Exons"
echo
hybpiper retrieve_sequences --targetfile_dna "${BAITFILE}" --sample_names samples_list.txt dna
echo
echo "Introns"
echo
hybpiper retrieve_sequences --targetfile_dna "${BAITFILE}" --sample_names samples_list.txt intron
echo
echo "Supercontigs"
echo
hybpiper retrieve_sequences --targetfile_dna "${BAITFILE}" --sample_names samples_list.txt supercontig
echo
echo "Investigating paralogs"
echo
hybpiper paralog_retriever --targetfile_dna "${BAITFILE}" samples_list.txt
echo
END

# Removing ".dedup*" from accession names
echo "Removing \".dedup*\" from accession names"
sed -i 's/\.dedup.*$//g' ./*.{FNA,fasta}
echo
echo "Removing \".dedup*\" from statistics"
sed -i 's/\.dedup//g' ./*.tsv
echo

# Calculating number of occurrences of each sample in all contigs
echo "Calculating number of occurrences of each sample in all contigs..."
echo "Results will be in file 'presence_of_samples_in_contigs.tsv'."
echo -e "Total number of contigs:\t$(find . -maxdepth 1 -name "*.FNA" -o -name "*.fasta" | wc -l)" > presence_of_samples_in_contigs.tsv || operationfailed
echo >> presence_of_samples_in_contigs.tsv || operationfailed
echo -e "Sample\tNumber" >> presence_of_samples_in_contigs.tsv || operationfailed
while read -r SAMPLE; do
	echo -e "${SAMPLE}\t$(grep "^>${SAMPLE}$" ./*.fasta ./*.FNA | wc -l)" >> presence_of_samples_in_contigs.tsv || operationfailed
	done < <(sed 's/\.dedup$//' "${SAMPLES}" | sort)
echo >> presence_of_samples_in_contigs.tsv || operationfailed
echo "Note that for every probe sequence, three contigs are produced (for respective exon, intron and supercontig)."
echo "Divide 'Total number of contigs' by three to get number of probes. Similarly divide number of occurrence of each sample by three."
echo "You can calculate percentage of presence of each sample in all contigs (from total number of contigs)."
echo

echo "Transposition of sequence lengths and paralogs"
perl -F'\t' -lane 'push @rows, [@F]; END { for $row (0..$#{$rows[0]}) { print join("\t", map {$_->[$row] // ""} @rows) } }' seq_lengths.tsv > seq_lengths_transp.tsv
perl -F'\t' -lane 'push @rows, [@F]; END { for $row (0..$#{$rows[0]}) { print join("\t", map {$_->[$row] // ""} @rows) } }' paralog_report.tsv > paralog_report_transp.tsv
sed -i 's/^Species[[:blank:]]/Gene\/Species\t/' paralog_report_transp.tsv seq_lengths_transp.tsv
echo

# Removing input data
echo "Removing input directories and unneeded files"
rm -rf  hybseq_3_hybpiper_postprocess_2_run.sh ref
echo

exit

