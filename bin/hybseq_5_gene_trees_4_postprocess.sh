#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Provide single argument: directory with gene trees to sort.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Checking if exactly one variables is provided
if [[ "$#" -ne '1' ]]; then
	echo "Error! Exactly 1 parameter (directory with gene trees to process) is required! $# parameters received."
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

# Switching to working directory
echo "Going to $1"
cd "$1" || operationfailed
echo

# Inserting trees into tree lists
echo "Maximum-likelihood trees"
echo
echo "Creating lists of trees"
echo "List of introns"
find . -name "*.treefile" | sort | grep introns > trees_ml_list_introns.txt || operationfailed
echo "List of supercontigs"
find . -name "*.treefile" | sort | grep supercontig > trees_ml_list_supercontig.txt || operationfailed
echo "List of exons"
find . -name "*.treefile" | sort | grep -v "introns\|supercontig" > trees_ml_list_exons.txt || operationfailed
echo "Extracting trees"
echo "Extracting introns"
while read -r T; do
	cat "${T}" >> trees_ml_introns.treefile.tmp || operationfailed
	done < trees_ml_list_introns.txt
echo "Extracting supercontigs"
while read -r T; do
	cat "${T}" >> trees_ml_supercontigs.treefile.tmp || operationfailed
	done < trees_ml_list_supercontig.txt
echo "Extracting exons"
while read -r T; do
	cat "${T}" >> trees_ml_exons.treefile.tmp || operationfailed
	done < trees_ml_list_exons.txt
echo "Cleaning tree names"
sed -i 's/^\.\///;s/\.aln\.fasta//' trees_ml_*.txt || operationfailed
echo "Building tree lists"
echo "Building list of introns"
paste -d ' ' trees_ml_list_introns.txt trees_ml_introns.treefile.tmp > trees_ml_introns.nwk || operationfailed
echo "Building list of supercontigs"
paste -d ' ' trees_ml_list_supercontig.txt trees_ml_supercontigs.treefile.tmp > trees_ml_supercontigs.nwk || operationfailed
echo "Building list of exons"
paste -d ' ' trees_ml_list_exons.txt trees_ml_exons.treefile.tmp > trees_ml_exons.nwk || operationfailed
echo
echo "Consensus trees"
echo
echo "Creating lists of trees"
echo "List of introns"
find . -name "*.contree" | sort | grep introns > trees_cons_list_introns.txt || operationfailed
echo "List of supercontigs"
find . -name "*.contree" | sort | grep supercontig > trees_cons_list_supercontig.txt || operationfailed
echo "List of exons"
find . -name "*.contree" | sort | grep -v "introns\|supercontig" > trees_cons_list_exons.txt || operationfailed
echo "Extracting trees"
echo "Extracting introns"
while read -r T; do
	cat "${T}" >> trees_cons_introns.contree.tmp || operationfailed
	done < trees_cons_list_introns.txt
echo "Extracting supercontigs"
while read -r T; do
	cat "${T}" >> trees_cons_supercontigs.contree.tmp || operationfailed
	done < trees_cons_list_supercontig.txt
echo "Extracting exons"
while read -r T; do
	cat "${T}" >> trees_cons_exons.contree.tmp || operationfailed
	done < trees_cons_list_exons.txt
echo "Cleaning tree names"
sed -i 's/^\.\///;s/\.aln\.fasta//' trees_cons_*.txt || operationfailed
echo "Building tree lists"
echo "Building list of introns"
paste -d ' ' trees_cons_list_introns.txt trees_cons_introns.contree.tmp > trees_cons_introns.nwk || operationfailed
echo "Building list of supercontigs"
paste -d ' ' trees_cons_list_supercontig.txt trees_cons_supercontigs.contree.tmp > trees_cons_supercontigs.nwk || operationfailed
echo "Building list of exons"
paste -d ' ' trees_cons_list_exons.txt trees_cons_exons.contree.tmp > trees_cons_exons.nwk || operationfailed
echo
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
echo "Moving tree lists"
mv exons/*.nwk introns/*.nwk supercontigs/*.nwk . || operationfailed
echo

# Removing unneeded strings from tree lists
echo "Removing unneeded strings from tree lists"
sed -i 's/\.treefile\>//' trees_ml_*.nwk || operationfailed
sed -i 's/\.contree\>//' trees_cons_*.nwk || operationfailed
echo

exit

# # ### RAxML-NG
# ## Exons
# find . -name "*.support" > trees_list.tmp
# find . -name "*.support" | sort > trees_list.tmp
# while read -r T; do cat "${T}" >> trees_treefile.tmp; done < trees_list.tmp
# sed -i 's/^\.\///;s/\.aln\.fasta\.raxml\.support//' trees_list.tmp
# paste -d ' ' trees_list.tmp trees_treefile.tmp > ../exons_1_unfiltered/trees_ml_exons.nwk
# rm ./*.tmp
# ## Introns
# find . -name "*.support" > trees_list.tmp
# find . -name "*.support" | sort > trees_list.tmp
# while read -r T; do cat "${T}" >> trees_treefile.tmp; done < trees_list.tmp
# sed -i 's/^\.\///;s/\.aln\.fasta\.raxml\.support//' trees_list.tmp
# paste -d ' ' trees_list.tmp trees_treefile.tmp > ../introns_1_unfiltered/trees_ml_introns.nwk
# rm ./*.tmp
# ## Supercontigs
# find . -name "*.support" > trees_list.tmp
# find . -name "*.support" | sort > trees_list.tmp
# while read -r T; do cat "${T}" >> trees_treefile.tmp; done < trees_list.tmp
# sed -i 's/^\.\///;s/\.aln\.fasta\.raxml\.support//' trees_list.tmp
# paste -d ' ' trees_list.tmp trees_treefile.tmp > ../supercontigs_1_unfiltered/trees_ml_supercontigs.nwk
# rm ./*.tmp

