#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=12:0:0 -l select=1:ncpus=1:mem=16gb:scratch_local=1gb -q ibot -m abe -N HybSeq.genetree."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALN}" ~/hybseq/bin/hybseq_5_gene_trees_2_qsub.sh

################################################################################
# Cleanup of temporal (scratch) directory where the calculation was done
# See https://docs.metacentrum.cz/advanced/job-tracking/#trap-command-usage
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'trap' commands below
################################################################################

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -ar ${SCRATCHDIR} ${DATADIR}/ && clean_scratch' TERM

################################################################################
# Checking if all required parameters are provided
################################################################################

# Checking if all required variables are provided
if [[ -z "${ALNF}" ]]; then
	echo "Error! Sample name not provided!"
	exit 1
	fi
if [[ -z "${WORKDIR}" ]]; then
	echo "Error! Data and scripts for HybSeq not provided!"
	exit 1
	fi
if [[ -z "${DATADIR}" ]]; then
	echo "Error! Directory with data to process not provided!"
	exit 1
	fi

################################################################################
# End of processing of user input and checking if all required parameters are provided
################################################################################

################################################################################
# Loading of application module
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'module' command below
################################################################################

# Required modules
echo "Loading modules"
module add iqtree/2.2.0 || exit 1 # IQ-TREE 2
# module add raxml-ng/1.1.0 || exit 1 # RAxML-NG
echo

################################################################################
# Switching to temporal (SCRATCH) directory and copying input data there
# See https://docs.metacentrum.cz/basics/jobs/
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

# Change working directory
echo "Going to working directory ${SCRATCHDIR}"
cd "${SCRATCHDIR}"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybSeq data - ${WORKDIR}"
cp "${WORKDIR}"/bin/hybseq_5_gene_trees_3_run.sh "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}/${ALNF}"
cp "${DATADIR}"/"${ALNF}" "${SCRATCHDIR}"/ || exit 1
echo

# Basename of the input contig
echo "Obtaining basename of input file ${ALNF}"
ALNA="$(basename "${ALNF}")" || exit 1
echo

################################################################################
# The calculation
################################################################################

# Runing the task (trees from individual alignments)
echo "Computing gene tree from ${ALNA}..."
./hybseq_5_gene_trees_3_run.sh -a "${ALNA}" | tee hybseq_gene_tree."${ALNA%.*}".log

################################################################################
# Input files are removed from temporal working directory
# Results are copied to the output directory
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

rm "${ALNA}" hybseq_5_gene_trees_3_run.sh || { export CLEAN_SCRATCH='false'; exit 1; }
echo

# Copy results back to storage
cp -a "${SCRATCHDIR}"/* "${DATADIR}"/trees/ || export CLEAN_SCRATCH='false'

exit

