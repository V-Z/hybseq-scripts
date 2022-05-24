#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Concatenates exon references from assemblies in software like Geneious which are already reanamed according to HybPiper requirements.
# Outputs exon reference for usage in HybPiper.
# See https://github.com/mossmatters/HybPiper/wiki#12-target-file for details.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Input file
INPUT='input_seq_without_cpdna_1086_loci_renamed.fasta'
# Probe string - regular expression covering exactly probe names
PROBES='Assembly_[0-9]\+'
# Pattern of individual probe FASTA sequences (derived from the previous)
PATTERN='Assembly_*.fasta'
# Output file name
OUTPUT='input_seq_without_cpdna_1086_loci_renamed_concat.fasta'
# Taxa name to be inserted to the probe set
TAXA='Oxalisobtusa'

# Convert input FASTA not to be interleaved
awk 'BEGIN{RS=">"}NR>1{sub("\n","\t");gsub("\n",""); print RS$0}' "$INPUT" | sed 's/\t/\n/g' > tmp01

# Extract list of probe names
grep -o "$PROBES" tmp01 | sort -u > tmp02

# Create individual FASTA sequence for every probe/taxon
while read -r L; do
	grep -A 1 "$L" tmp01 | grep -v "^>" | tr -d "\n" > "$L".fasta
	done < tmp02

# Add probe name to every probe FASTA file
for F in $PATTERN; do
	sed -i "1 i\>$F" "$F"
	echo >> "$F"
	done

# Group all concatenated probes into single file
cat $PATTERN > "$OUTPUT"

# Remove ".fasta" from probe names
sed -i 's/\.fasta//' "$OUTPUT"

# List of names of individuals used for probes
grep -o ">.\+-" "$INPUT" | sed 's/^>//' | sed 's/-$//' | sort -u > "$OUTPUT".txt

# Insert taxa name before every probe name
sed -i "s/^>/>$TAXA-/" "$OUTPUT"

# Remove unneeded files
rm tmp0[12] $PATTERN

exit

