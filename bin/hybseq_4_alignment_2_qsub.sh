#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=4:0:0 -l select=1:ncpus=1:mem=6gb:scratch_local=1gb -m abe -N HybSeq.alignment."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALNB}" ~/hybseq/bin/hybseq_4_alignment_2_qsub.sh

################################################################################
# Cleanup of temporal (scratch) directory where the calculation was done
# See https://docs.metacentrum.cz/advanced/job-tracking/#trap-command-usage
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'trap' commands below
################################################################################

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -ar ${SCRATCHDIR} ${DATADIR}/; clean_scratch' TERM

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
# Loading of application modules
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'module' commands below
################################################################################

# Required modules
echo "Loading modules"
module add mafft/7.520-gcc-10.2.1-hvrjqrq || exit 1 # mafft
module add r/4.1.3-gcc-10.2.1-6xt26dl || exit 1 # R (ape, ips, scales)
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
cp -a "${WORKDIR}"/{bin/hybseq_4_alignment_3_run.r,rpackages} "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}/${ALNF}"
cp "${DATADIR}"/"${ALNF}" "${SCRATCHDIR}"/ || exit 1
echo

################################################################################
# The calculation
################################################################################

# Runing the task (alignments of individual loci)
echo "Aligning contig ${ALNF}..." # [1] file.fasta/file.FNA, [2] file.aln.fasta, [3] file.aln.png, [4] file.aln.check.png, [5] file.nwk, [6] file.tree.png, [7] file.saturation.png
R CMD BATCH --no-save --no-restore "--args ${ALNF} ${ALNF%.*}.aln.fasta ${ALNF%.*}.aln.png ${ALNF%.*}.aln.check.png ${ALNF%.*}.nwk ${ALNF%.*}.tree.png ${ALNF%.*}.saturation.png" hybseq_4_alignment_3_run.r "${ALNF%.*}".log || { export CLEAN_SCRATCH='false'; exit 1; }

################################################################################
# Input files are removed from temporal working directory
# Results are copied to the output directory
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

rm "${ALNF}" hybseq_4_alignment_3_run.r || { export CLEAN_SCRATCH='false'; exit 1; }
echo

# Copy results back to storage
echo "Copying results back to ${DATADIR}"
cp -a "${SCRATCHDIR}"/"${ALNF%.*}".* "${DATADIR}"/aligned/ || export CLEAN_SCRATCH='false'
echo

exit

