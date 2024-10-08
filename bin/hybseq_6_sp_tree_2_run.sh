#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Computes species trees with ASTRAL from all sets of gene trees in the current directory. The input file(s) must be named "*.nwk".

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Processing variables

# TODO Parse initial arguments

# TODO Checking if all required parameters are provided

################################################################################
# NOTE Edit variables below to fit your data
# Select either ASTRAL or ASTRAL-Pro, edit path accordingly
# Comment/uncomment command for selected species tree builder below
################################################################################

ASTRAL="/storage/pruhonice1-ibot/home/${LOGNAME}/bin/Astral/astral.5.7.8.jar" # ASTRAL
# ASTRALP="/storage/pruhonice1-ibot/home/${LOGNAME}/bin/astral-pro" # ASTRAL-Pro

# Species trees
echo "Reconstructing species trees with ASTRAL"
echo
for GT in *.nwk; do
	echo "Processing gene tree file ${GT} at $(date)"
	echo
	echo "Removing tree names from gene tree list"
	sed -i 's/^.\+ //' "${GT}"
	echo
	echo "Running ASTRAL"

################################################################################
# NOTE Comment/uncomment command for selected species tree builder and possibly edit parameters
# Edit appropriate variable above
################################################################################

	java -jar "${ASTRAL}" -i "${GT}" -o sp_"${GT}" -t 3 -g -r 10000 2>&1 | tee sp_"${GT%.nwk}".log # --outgroup Kalimeris_indica_SAMN11585377
# 	"${ASTRALP}" -o sp_"${GT}" -r 25 -s 25 -t 4 -u 1 "${GT}" 2>&1 | tee sp_"${GT%.nwk}".log # --root Kalimeris_indica_SAMN11585377
	echo
	echo "Removing input file"
	rm "${GT}"
	echo
	done

echo

exit

