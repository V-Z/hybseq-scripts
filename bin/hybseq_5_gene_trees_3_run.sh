#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# See './hybseq_5_gene_trees_3_run.sh -h' for help.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Processing variables

################################################################################
# Processing user input
# Do not edit this section unless you are very sure what you are doing - edits, if needed, are expected only in the last section
# Sections of the code where edits are to be expected are marked by "NOTE" in comments (see below)
################################################################################

# Parse initial arguments
while getopts "hva:" INITARGS; do
	case "${INITARGS}" in
		h) # Help and exit
			echo "Usage options:"
			echo -e "\t-h\tPrint this help and exit."
			echo -e "\t-v\tPrint script version, author and license and exit."
			echo -e "\t-a\tInput alignment in FASTA format to use for gene tree construction."
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
		a) # Alignment FASTA input
			if [[ -r "${OPTARG}" ]]; then
				ALN="$(realpath "${OPTARG}")"
				echo "Input alignment in FASTA format to use for gene tree construction: ${ALN}"
				echo
				else
					echo "Error! You did not provide input alignment in FASTA format to use for gene tree construction (-a) \"${OPTARG}\"!"
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

# Check if all required binaries are available
function toolcheck {
	command -v "$1" >/dev/null 2>&1 || {
		echo >&2 "Error! $1 is required but not installed. Aborting. Please, install it."
		echo
		operationfailed
		}
	}

################################################################################
# Checking if all required parameters are provided
################################################################################

toolcheck iqtree2
# toolcheck raxml-ng

# Checking if all required variables are provided
if [[ -z "${ALN}" ]]; then
	echo "Error! Input alignment in FASTA format to use for gene tree construction not provided!"
	operationfailed
	fi

################################################################################
# End of processing of user input and checking if all required parameters are provided
################################################################################

################################################################################
# NOTE Edit variables below to fit your data
################################################################################

# Construct gene trees with IQ-TREE from *.aln.fasta alignments
echo "Constructing gene tree for ${ALN} with IQ-TREE at $(date)"
iqtree2 -s "${ALN}" -st DNA -nt 1 --runs 5 -m MFP+MERGE+I+R+P -cmax 100 -nstop 1000 -alrt 10000 -bb 10000 -bnni || { export CLEAN_SCRATCH='false'; operationfailed; }
# echo "Constructing gene tree for ${ALN} with RAxML-NG at $(date)"
# raxml-ng --all --msa "${ALN}" --msa-format FASTA --data-type DNA --threads 1 --opt-model on --opt-branches on --model GTR+G+FO --bs-trees 1000 || { export CLEAN_SCRATCH='false'; operationfailed; }
echo

exit

