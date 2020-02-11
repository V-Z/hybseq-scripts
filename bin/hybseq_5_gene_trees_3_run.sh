#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# Processing variables

# TODO Parse initial arguments

# TODO Checking if all required parameters are provided

# Construct gene trees with IQ-TREE from *.aln.fasta alignments
echo "Constructing gene tree for $1 with IQ-TREE at $(date)"
iqtree -s "$1" -st DNA -nt 1 -m MFP+I+R+P -lmap ALL -cmax 1000 -nstop 1000 -alrt 10000 -bb 10000 -bnni || { export CLEAN_SCRATCH='false'; exit 1; }
echo

exit

