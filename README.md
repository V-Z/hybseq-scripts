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
* `2_seqs` --- All outputs of HybPiper.
* `3_aligned` --- 
* `4_gene_trees` --- 
* `5_sp_trees` --- 

# Required software

* BBMap <https://sourceforge.net/projects/bbmap/>
* Biopython <https://biopython.org/>
* BLAST+ <https://blast.ncbi.nlm.nih.gov/Blast.cgi>
* BWA <https://github.com/lh3/bwa>
* Exonerate <https://www.ebi.ac.uk/about/vertebrate-genomics/software/exonerate>
* FastQC <https://www.bioinformatics.babraham.ac.uk/projects/fastqc/>
* GNU Parallel <https://www.gnu.org/software/parallel/>
* HybPiper <https://github.com/mossmatters/HybPiper/wiki>
* Python <https://www.python.org/>
* Samtools <http://www.htslib.org/>
* SPAdes <https://github.com/ablab/spades>
* Trimmomatic <http://www.usadellab.org/cms/?page=trimmomatic>

# Description and usage of the scripts

Scripts `hybseq_1_prep_1_qsub.sh`, `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_2_hybpiper_2_qsub.sh`, `hybseq_3_hybpiper_postprocess_1_qsub.sh`, `hybseq_4_alignment_1_submitter.sh`, `hybseq_4_alignment_2_qsub.sh`, `hybseq_5_gene_trees_1_submitter.sh`, `hybseq_5_gene_trees_2_qsub.sh` and `hybseq_6_sp_tree_1_qsub.sh` (scripts named `hybseq_*_qsub.sh` and `hybseq_*_submitter.sh`) contain settings for submission of each step (see further) on clusters using `PBS Pro`. **These scripts require edits.** At least paths must be changed there. According to cluster settings, commands `module add` and `qsub` (and probably some other things) will have to be edited. So they are rather inspiration for users of another clusters than [MetaCentrum](https://www.metacentrum.cz/en/).

Scripts `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_4_alignment_1_submitter.sh` and `hybseq_5_gene_trees_1_submitter.sh` process in given directory all files (HybPiper, alignments and reconstruction of gene trees, respectively) and prepare individual task (job) for each file to be submitted by `hybseq_2_hybpiper_2_qsub.sh`, `hybseq_4_alignment_2_qsub.sh` and `hybseq_5_gene_trees_2_qsub.sh`, respectively.

## 1. Pre-processing data --- trimming, deduplication, quality checks and statistics

Used scripts: `hybseq_1_prep_1_qsub.sh` and `hybseq_1_prep_2_run.sh`.

Script `hybseq_1_prep_1_qsub.sh` contains settings for submission of the task on cluster using `PBS Pro` and runs `hybseq_1_prep_2_run.sh` to trimm, deduplicate and quality check all FASTQ files in a given directory. It requires [BBMap](https://sourceforge.net/projects/bbmap/), [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [GNU Parallel](https://www.gnu.org/software/parallel/) and [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic).

Edit in `hybseq_1_prep_1_qsub.sh` variables to point correct locations:

* `WORKDIR` --- Point to `hybseq` directory containing this script set.
* `DATADIR` --- Point to directory containing raw FASTQ files named like `sampleXY.R1.fq` and `sampleXY.R2.fq` for forward/reverse reads of each sample, i.e. with suffix `.R1.fq` and `.R2.fq`. Recommended is compression by `bzip2` (i.e. `sampleXY.R1.fq.bz2` and `sampleXY.R2.fq.bz2`), e.g. `.../1_data/lib_01/0_data`.

and submit the job by something like:

```shell
qsub -l walltime=24:0:0 -l select=1:ncpus=4:mem=16gb:scratch_local=100gb -q ibot -m abe \
~/hybseq/bin/hybseq_1_prep_1_qsub.sh
# And see progress by something like
qstat -w -n -1 -u $LOGNAME -x
```

Results will be copied back to `DATADIR`.

## 2. Running HybPiper

Used scripts: `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_2_hybpiper_2_qsub.sh` and `hybseq_2_hybpiper_3_run.sh` to run [HybPiper](https://github.com/mossmatters/HybPiper/wiki) for each input sample, and `hybseq_3_hybpiper_postprocess_1_qsub.sh` and `hybseq_3_hybpiper_postprocess_2_run.sh` to retrieve contig sequences and obtain statistics.

### 2.1. Running HybPiper for each sample

Used scripts: `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_2_hybpiper_2_qsub.sh` and `hybseq_2_hybpiper_3_run.sh`.

Each sample (i.e. pair of files `sampleXY.dedup.R1.fq.bz2` and `sampleXY.dedup.R2.fq.bz2` produced by `hybseq_1_prep_2_run.sh`) is processed as separate job. File `samples_list.txt` created by `hybseq_1_prep_2_run.sh` is used by `hybseq_2_hybpiper_1_submitter.sh` to drive the submission.

Script `hybseq_2_hybpiper_1_submitter.sh` contains settings (paths etc.) needed for submission of the task on cluster using `PBS Pro`. It is using `qsub` to submit `hybseq_2_hybpiper_2_qsub.sh` to process all deduplicated FASTQ files (in directory like `1_data/lib_01/2_dedup`) with [HybPiper](https://github.com/mossmatters/HybPiper/wiki). For every sample listed in `samples_list.txt` (created by `hybseq_1_prep_2_run.sh`) script `hybseq_2_hybpiper_1_submitter.sh` submits individual job with `hybseq_2_hybpiper_2_qsub.sh`. Finally, `hybseq_2_hybpiper_3_run.sh` is using [HybPiper](https://github.com/mossmatters/HybPiper/wiki) to process the sample. This script can be edited to use different HybPiper settings.

It requires [Biopython](https://biopython.org/), [BLAST+](https://blast.ncbi.nlm.nih.gov/Blast.cgi), [BWA](https://github.com/lh3/bwa), [Exonerate](https://www.ebi.ac.uk/about/vertebrate-genomics/software/exonerate), [GNU Parallel](https://www.gnu.org/software/parallel/), [HybPiper](https://github.com/mossmatters/HybPiper/wiki), [Python](https://www.python.org/), [Samtools](http://www.htslib.org/) and [SPAdes](https://github.com/ablab/spades).

Edit variables in `hybseq_2_hybpiper_1_submitter.sh`:

* `HYBPIPDIR` --- Point to directory containing [HybPiper](https://github.com/mossmatters/HybPiper/wiki).
* `WORKDIR` --- Point to `hybseq` directory containing this script set.
* `DATADIR` --- Point to directory containing deduplicated FASTQ files named like `sampleXY.dedup.R1.fq` and `sampleXY.dedup.R2.fq` (produced by `hybseq_1_prep_2_run.sh`) for forward/reverse reads of each sample. The directory is e.g. `XXX/1_data/lib_01/2_dedup`.
* `SAMPLES` --- File name of list of samples according to [HybPiper requirements](https://github.com/mossmatters/HybPiper/wiki#running-the-pipeline) to be processed (prepared by `hybseq_1_prep_2_run.sh` as `samples_list.txt`).
* `BAITFILE` --- Reference bait FASTA file (see <https://github.com/mossmatters/HybPiper/wiki#target-file> for details) --- must be relative path within `WORKDIR`
* `NCPU` --- Number of CPU threads used. Default is 8.

Depending on the cluster (if using something else than [MetaCentrum](https://www.metacentrum.cz/en/)) script `hybseq_2_hybpiper_2_qsub.sh` will have to be edited (e.g. loading needed software modules by `module add`). As `hybseq_2_hybpiper_3_run.sh` contains procesing by [HybPiper](https://github.com/mossmatters/HybPiper/wiki) itself, it can be edited.

When done with edits, simply run the `hybseq_2_hybpiper_1_submitter.sh` script --- it will go to `DATADIR` and submit job for every sample listed in `samples_list.txt` (`SAMPLES`):

```shell
./hybseq_2_hybpiper_1_submitter.sh
```

Result for each library will be in `DATADIR`, e.g. `XXX/1_data/lib_01/2_dedup`. It's possible to move report files into their directories by something like:

```shell
while read L; do mv HybPiper."$L".[eo]* "$L"/; done < samples_list.txt
```

All outputs can be moved from `XXX/1_data/lib_01/2_dedup` to `XXX/2_seqs` by running something like the following command in `DATADIR`:

```shell
mv *.dedup ../../../2_seqs/
```

