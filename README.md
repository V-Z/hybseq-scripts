HybSeq scripts
==============

**Set of scripts to process HybSeq target enrichment HTS data** on computing grids like [MetaCentrum](https://www.metacentrum.cz/en/).

Version: 1.0

# Author

Vojtěch Zeisek, <https://trapa.cz/>.

# Homepage and reporting issues


# License

GNU General Public License 3.0, see `LICENSE.md` and <https://www.gnu.org/licenses/gpl-3.0.html>.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# HybSeq data and their processing


## Data structure

For usage of presented scripts, data are recommended to be stored in following structure:

* `1_data` --- Data directory containing directories for all individual sequencing libraries.
	* `lib_01` --- Data from the first sequencing library. Same directory structure should be kept in all library directories.
		* `0_data` --- Raw FASTQ files. **Must** be named like `sampleXY.R1.fq` and `sampleXY.R2.fq` for forward/reverse reads of each sample, i.e. with suffix `.R1.fq` and `.R2.fq`. Recommended is compression by `bzip2` (i.e. `sampleXY.R1.fq.bz2` and `sampleXY.R2.fq.bz2`).
		* `1_trimmed` --- Outputs of `hybseq_1_prep_2_run.sh` --- trimmed raw FASTQ files (using [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic)), and trimming statistics (`report_trimming.tsv`).
		* `2_dedup` --- Outputs of `hybseq_1_prep_2_run.sh` --- deduplicated FASTQ files (using `clumpify.sh` from [BBMap](https://sourceforge.net/projects/bbmap/)), and deduplication statistics (`report_filtering.tsv`) and list of samples needed for [HybPiper](https://github.com/mossmatters/HybPiper/wiki) (`samples_list.txt`).
		* `3_qual_rep` --- Outputs of `hybseq_1_prep_2_run.sh` --- quality check reports of FASTQ files (using [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)).
	* `lib_02` --- Data from the second sequencing library. More libraries can follow...
	* `lib_##` --- ...up to data from the *N*-th (last) sequencing library.
* `2_seqs` --- 
* `3_aligned` --- 
* `4_gene_trees` --- 
* `5_sp_trees` --- 

# Required software

* BBMap <https://sourceforge.net/projects/bbmap/>
* FastQC <https://www.bioinformatics.babraham.ac.uk/projects/fastqc/>
* GNU Parallel <https://www.gnu.org/software/parallel/>
* HybPiper <https://github.com/mossmatters/HybPiper/wiki>
* Trimmomatic <http://www.usadellab.org/cms/?page=trimmomatic>

# Description and usage of the scripts

Scripts `hybseq_1_prep_1_qsub.sh`, `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_2_hybpiper_2_qsub.sh`, `hybseq_3_hybpiper_postprocess_1_qsub.sh`, `hybseq_4_alignment_1_submitter.sh`, `hybseq_4_alignment_2_qsub.sh`, `hybseq_5_gene_trees_1_submitter.sh`, `hybseq_5_gene_trees_2_qsub.sh` and `hybseq_6_sp_tree_1_qsub.sh` (scripts named `hybseq_*_qsub.sh` and `hybseq_*_submitter.sh`) contain settings for submission of each step (see further) on clusters using `PBS Pro`. **These scripts require edits.** At least paths must be changed there. According to cluster settings, commands `module add` and `qsub` (and probably some other things) will have to be edited. So they are rather inspiration for users of another clusters than [MetaCentrum](https://www.metacentrum.cz/en/).

Scripts `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_4_alignment_1_submitter.sh` and `hybseq_5_gene_trees_1_submitter.sh` process in given directory all files (HybPiper, alignments and reconstruction of gene trees, respectively) and prepare individual task (job) for each file to be submitted by `hybseq_2_hybpiper_2_qsub.sh`, `hybseq_4_alignment_2_qsub.sh` and `hybseq_5_gene_trees_2_qsub.sh`, respectively.

## 1. Pre-processing data --- trimming, deduplication, quality checks and statistics

Used scripts: `hybseq_1_prep_1_qsub.sh` and `hybseq_1_prep_2_run.sh`.

Script `hybseq_1_prep_1_qsub.sh` contains settings for submission of the task on cluster using `PBS Pro` and runs `hybseq_1_prep_2_run.sh` to trimm, deduplicate and quality check all FASTQ files in a given directory. It requires [BBMap](https://sourceforge.net/projects/bbmap/), [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [GNU Parallel](https://www.gnu.org/software/parallel/) and [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic).

Edit in `hybseq_1_prep_1_qsub.sh` variables to point correct locations:

* `WORKDIR` --- Must point to `hybseq` directory containing this script set.
* `DATADIR` --- Must point to directory containing raw FASTQ files named like `sampleXY.R1.fq` and `sampleXY.R2.fq` for forward/reverse reads of each sample, i.e. with suffix `.R1.fq` and `.R2.fq`. Recommended is compression by `bzip2` (i.e. `sampleXY.R1.fq.bz2` and `sampleXY.R2.fq.bz2`), e.g. `.../1_data/lib_01/0_data`.

and submit the job by something like:

```shell
qsub -l walltime=24:0:0 -l select=1:ncpus=4:mem=16gb:scratch_local=100gb -q ibot -m abe \
~/hybseq/bin/hybseq_1_prep_1_qsub.sh
```

Results will be copied back to `DATADIR`.

## 2. Running HybPiper

Used scripts: `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_2_hybpiper_2_qsub.sh` and `hybseq_2_hybpiper_3_run.sh` to run [HybPiper](https://github.com/mossmatters/HybPiper/wiki) for each input sample, and `hybseq_3_hybpiper_postprocess_1_qsub.sh` and `hybseq_3_hybpiper_postprocess_2_run.sh` to retrieve contig sequences and obtain statistics.

