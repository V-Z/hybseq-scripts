#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Processes individual samples by HybPiper (the task is submitted by hybseq_run_2_hybpiper_1_submitter.sh).

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=48:0:0 -l select=1:ncpus="${NCPU}":mem=8gb:scratch_local=10gb -q ibot -m abe -N HybPiper."${SAMPLE}" -v HYBPIPDIR="${HYBPIPDIR}",WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",BAITFILE="${BAITFILE}",NCPU="${NCPU}",SAMPLE="${SAMPLE}" ~/hybseq/bin/hybseq_2_hybpiper_2_qsub.sh

# Clean-up of SCRATCH
trap 'clean_scratch' TERM EXIT
trap 'cp -ar $SCRATCHDIR $DATADIR/ && clean_scratch' TERM

# Checking if all required variables are provided
if [ -z "${SAMPLE}" ]; then
	echo "Error! Sample name not provided!"
	exit 1
	fi
if [ -z "${HYBPIPDIR}" ]; then
	echo "Error! Directory with HybPiper not provided!"
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
if [ -z "${BAITFILE}" ]; then
	echo "Error! Reference bait FASTA file not provided!"
	exit 1
	fi
if [ -z "${NCPU}" ]; then
	echo "Error! Number of CPU threads not provided!"
	exit 1
	fi

# Required modules
echo "Loading modules"
module add python27-modules-gcc || exit 1 # biopython
module add exonerate-2.2.0 || exit 1 # exonerate
module add blast+-2.8.0a || exit 1 # blastx, makeblastdb
module add spades-3.13.0 || exit 1 # spades.py
module add parallel-20160622 || exit 1 # parallel
module add bwa-0.7.13 || exit 1 # bwa
module add samtools-1.9 || exit 1 # samtools
echo

# Change working directory
echo "Going to working directory ${SCRATCHDIR}"
cd "${SCRATCHDIR}"/ || exit 1
echo

# Copy data
echo "Copying..."
echo "HybPiper - ${HYBPIPDIR}"
cp -a "${HYBPIPDIR}" "${SCRATCHDIR}"/ || exit 1
echo "HybSeq data - ${WORKDIR}"
cp -a "${WORKDIR}"/{bin/hybseq_2_hybpiper_3_run.sh,ref} "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}/${SAMPLE}"
cp "${DATADIR}"/"${SAMPLE}".* "${SCRATCHDIR}"/ || exit 1
echo

# Runing the task (HibPiper)
echo "Running HybPiper..."
./hybseq_2_hybpiper_3_run.sh -s "${SAMPLE}" -p "${HYBPIPDIR}" -b "${BAITFILE}" -c "${NCPU}" | tee hybseq_hybpiper."${SAMPLE}".log
echo

# Copy results back to storage
echo "Copying results back to ${DATADIR}"
cp -a "${SCRATCHDIR}"/"${SAMPLE}" "${DATADIR}"/ || export CLEAN_SCRATCH='false'
cp "${SCRATCHDIR}"/hybseq_hybpiper."${SAMPLE}".log "${DATADIR}"/"${SAMPLE}"/ || export CLEAN_SCRATCH='false'
echo

# After everything is done, it's possible to move report files into their directories by 'while read L; do mv HybPiper."$L".[eo]* "$L"/; done < samples_list.txt' in DATADIR

exit

