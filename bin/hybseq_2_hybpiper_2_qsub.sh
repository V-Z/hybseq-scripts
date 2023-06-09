#!/bin/bash

# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# Processes individual samples by HybPiper (the task is submitted by hybseq_run_2_hybpiper_1_submitter.sh).

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# qsub -l walltime=48:0:0 -l select=1:ncpus="${NCPU}":mem=16gb:scratch_local=15gb -q ibot -m abe -N HybPiper."${SAMPLE}" -v HYBPIPDIR="${HYBPIPDIR}",WORKDIR="${WORKDIR}",DATADIR="${DATADIR}",BAITFILE="${BAITFILE}",NCPU="${NCPU}",SAMPLE="${SAMPLE}" ~/hybseq/bin/hybseq_2_hybpiper_2_qsub.sh

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
if [[ -z "${SAMPLE}" ]]; then
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
if [[ -z "${BAITFILE}" ]]; then
	echo "Error! Reference bait FASTA file not provided!"
	exit 1
	fi
if [[ -z "${NCPU}" ]]; then
	echo "Error! Number of CPU threads not provided!"
	exit 1
	fi

################################################################################
# End of processing of user input and checking if all required parameters are provided
################################################################################

################################################################################
# Loading of application module
# NOTE On another clusters than Czech MetaCentrum edit or remove the 'module' command below
# On Czech MetaCentrum, HybPiper is installed as Apptainer (Singularity) container, see https://docs.metacentrum.cz/software/containers/
# Container starts its own shell, so that it is loaded right before usage of HybPiper (see script hybseq_2_hybpiper_3_run.sh)
# If HybPiper is installed differently on your cluster, edit code below or in hybseq_2_hybpiper_3_run.sh accordingly
################################################################################

# Required modules
echo "Loading modules"
module add parallel/20200322 || exit 1
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
cp -a "${WORKDIR}"/{bin/hybseq_2_hybpiper_3_run.sh,ref} "${SCRATCHDIR}"/ || exit 1
echo "Data to process - ${DATADIR}/${SAMPLE}"
cp "${DATADIR}"/"${SAMPLE}".* "${SCRATCHDIR}"/ || exit 1
echo

################################################################################
# The calculation
################################################################################

# Runing the task (HibPiper)
echo "Running HybPiper..."
./hybseq_2_hybpiper_3_run.sh -s "${SAMPLE}" -b "${BAITFILE}" -c "${NCPU}" | tee hybseq_hybpiper."${SAMPLE}".log
echo

################################################################################
# Results are copied to the output directory
# NOTE On another clusters than Czech MetaCentrum ensure that SCRATCH is the variable for temporal directory - if not, edit following code accordingly
################################################################################

# Copy results back to storage
echo "Copying results back to ${DATADIR}"
cp -a "${SCRATCHDIR}"/"${SAMPLE}" "${DATADIR}"/ || export CLEAN_SCRATCH='false'
cp "${SCRATCHDIR}"/hybseq_hybpiper."${SAMPLE}".log "${DATADIR}"/"${SAMPLE}"/ || export CLEAN_SCRATCH='false'
echo

# After everything is done, it's possible to move report files into their directories by 'while read L; do mv HybPiper."$L".[eo]* "$L"/; done < samples_list.txt' in DATADIR

exit

