#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Provide single argument: directory with aligned contigs to sort. Alignments will be sorted into directories for exons, introns and supercontigs, statistics will be calculated and lists of NJ trees created.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Checking if exactly one variables is provided
if [ "$#" -ne '1' ]; then
	echo "Error! Exactly 1 parameter (directory with aligned sequences to process) is required! $# parameters received."
	exit 1
	fi

# Exit on error
function operationfailed {
	echo "Error! Operation failed!"
	echo
	echo "See previous message(s) to be able to trace the problem."
	echo
	exit 1
	}

# Alignment statistics
function alignstats {
	# Number of sites with 1, 2, 3 or 4 observed bases
	echo "Initializing files with statistics"
	printf "\t\t\tNumbers of sites with 1, 2, 3 or 4 observed bases\n" > "$1" || operationfailed
	printf "Alignment\tNumber of sequences\tNumber of sites\t1\t2\t3\t4\n" >> "$1" || operationfailed
	echo
	for L in *.log; do
		echo "Processing ${L%.*}"
		{ printf '%s\t' "$L" # Print sample name
			grep "Number of sequences:" "$L" | grep -o "[0-9]\+" | xargs printf '%s\t%s'
			grep "Number of sites:" "$L" | grep -o "[0-9]\+" | xargs printf '%s\t%s'
			grep -A 2 "Number of sites with 1, 2, 3 or 4 observed bases:" "$L" | tail -n 1 | sed 's/^[[:blank:]]\+//'| sed 's/[[:blank:]]\+/ /g' | cut -f 1 -d ' ' | xargs printf '%s\t%s'
			grep -A 2 "Number of sites with 1, 2, 3 or 4 observed bases:" "$L" | tail -n 1 | sed 's/^[[:blank:]]\+//'| sed 's/[[:blank:]]\+/ /g' | cut -f 2 -d ' ' | xargs printf '%s\t%s'
			grep -A 2 "Number of sites with 1, 2, 3 or 4 observed bases:" "$L" | tail -n 1 | sed 's/^[[:blank:]]\+//'| sed 's/[[:blank:]]\+/ /g' | cut -f 3 -d ' ' | xargs printf '%s\t%s'
			grep -A 2 "Number of sites with 1, 2, 3 or 4 observed bases:" "$L" | tail -n 1 | sed 's/^[[:blank:]]\+//'| sed 's/[[:blank:]]\+/ /g' | cut -f 4 -d ' ' | xargs printf '%s\t%s'
			printf '\n'
			} >> "$1" || operationfailed
		done
	}

# Switching to working directory
echo "Going to $1"
cd "$1" || operationfailed
echo

# Alignments sorted according to file size
echo "List of alignments according to their size"
find . -type f -name "*aln.fasta" -printf '%k KB %p\n' | sort -n || operationfailed
echo

# Inserting trees into tree lists
echo "Creating lists of trees"
echo "List of introns"
find . -name "*.nwk" | sort | grep introns > trees_list_introns.txt || operationfailed
echo "List of supercontigs"
find . -name "*.nwk" | sort | grep supercontig > trees_list_supercontig.txt || operationfailed
echo "List of exons"
find . -name "*.nwk" | sort | grep -v "introns\|supercontig" > trees_list_exons.txt || operationfailed
echo "Extracting trees"
echo "Extracting introns"
while read T; do
	cat "$T" >> trees_introns.nwk.tmp
	done < trees_list_introns.txt
echo "Extracting supercontigs"
while read T; do
	cat "$T" >> trees_supercontigs.nwk.tmp
	done < trees_list_supercontig.txt
echo "Extracting exons"
while read T; do
	cat "$T" >> trees_exons.nwk.tmp
	done < trees_list_exons.txt
echo "Removing \".nwk\" from tree names"
sed -i 's/^\.\///;s/\.nwk//' trees_*.txt || operationfailed
echo "Building tree lists"
echo "Building list of introns"
paste -d ' ' trees_list_introns.txt trees_introns.nwk.tmp > trees_introns.nwk || operationfailed
echo "Building list of supercontigs"
paste -d ' ' trees_list_supercontig.txt trees_supercontigs.nwk.tmp > trees_supercontigs.nwk || operationfailed
echo "Building list of exons"
paste -d ' ' trees_list_exons.txt trees_exons.nwk.tmp > trees_exons.nwk || operationfailed
echo "Removing temporal files"
rm ./*.tmp ./*.txt || operationfailed
echo

# Sorting into subdirectories
echo "Sorting into subdirectories"
echo "Making directories"
mkdir exons introns supercontigs || operationfailed
echo "Moving introns"
find . -maxdepth 1 -type f -name "*introns*" -exec mv '{}' introns/ \; || operationfailed
echo "Moving supercontigs"
find . -maxdepth 1 -type f -name "*supercontig*" -exec mv '{}' supercontigs/ \; || operationfailed
echo "Moving exons"
find . -maxdepth 1 -type f -exec mv '{}' exons/ \; || operationfailed
echo
echo "Moving lists of NJ trees"
echo "Exons"
mv exons/trees_exons.nwk . || operationfailed
echo "Introns"
mv introns/trees_introns.nwk . || operationfailed
echo "Supercontig"
mv supercontigs/trees_supercontigs.nwk . || operationfailed
echo

# Statistics
echo "Extracting alignment statistics"
echo "Statistics of exons"
cd exons/ || operationfailed
alignstats alignments_stats_exons.tsv || operationfailed
echo
echo "Statistics of introns"
cd ../introns/ || operationfailed
alignstats alignments_stats_introns.tsv || operationfailed
echo
echo "Statistics of supercontigs"
cd ../supercontigs/ || operationfailed
alignstats alignments_stats_supercontigs.tsv || operationfailed
echo
cd .. || operationfailed
echo
echo "Moving statistics files"
mv exons/alignments_stats_exons.tsv introns/alignments_stats_introns.tsv supercontigs/alignments_stats_supercontigs.tsv . || operationfailed
echo
echo "Removing unneeded strings from statistics"
sed -i 's/\.log\>//' alignments_stats_*.tsv || operationfailed
echo

exit

