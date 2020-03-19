#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=4:0:0 -l select=1:ncpus=1:mem=6gb:scratch_local=1gb -q ibot -m abe -N HybSeq.alignment."${ALNB%.*}" -v WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",ALNF="${ALNB}" ~/hybseq/bin/hybseq_4_alignment_2_qsub.sh

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -ar $SCRATCHDIR $DATADIR/; clean_scratch' TERM

# Checking if all required variables are provided
if [ -z "${ALNF}" ]; then
	echo "Error! Sample name not provided!"
	exit 1
	fi
if [ -z "${WORKDIR}" ]; then
	echo "Error! Data and scripts for HybSeq not provided!"
	exit 1
	fi
if [ -z "${DATADIR}" ]; then
	echo "Error! Directory with data to process not provided!"
	exit 1
	fi

# Required modules
echo "Loading modules"
module add mafft-7.453 || exit 1 # mafft
module add R-3.6.2-gcc || exit 1 # R (ape, ips; dependencies colorspace, XML)
echo

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

# Runing the task (alignments of individual loci)
echo "Aligning contig ${ALNF}..."
R CMD BATCH --no-save --no-restore "--args ${ALNF} ${ALNF%.*}.aln.fasta ${ALNF%.*}.aln.png ${ALNF%.*}.aln.check.png ${ALNF%.*}.nwk ${ALNF%.*}.tree.png" hybseq_4_alignment_3_run.r "${ALNF%.*}".log || { export CLEAN_SCRATCH='false'; exit 1; }
rm "${ALNF}" || { export CLEAN_SCRATCH='false'; exit 1; }
echo

# Copy results back to storage
echo "Copying results back to ${DATADIR}"
cp -a "${SCRATCHDIR}"/"${ALNF%.*}".* "${DATADIR}"/aligned/ || export CLEAN_SCRATCH='false'
echo

exit

