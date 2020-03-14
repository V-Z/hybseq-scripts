HybSeq scripts
========================================

**Set of scripts to process HybSeq target enrichment HTS data** on computing grids like [MetaCentrum](https://www.metacentrum.cz/).

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
* `2_seqs` --- All outputs of [HybPiper](https://github.com/mossmatters/HybPiper/wiki) --- scripts `hybseq_2_hybpiper_*` and `hybseq_3_hybpiper_postprocess_*`.
* `3_aligned` --- Sequences aligned by [MAFFT](https://mafft.cbrc.jp/alignment/software/) and alignment reports (created by `R` script using packages `ape` and `ips`) sorted by `hybseq_4_alignment_4_postprocess.sh` into directories for exons, introns and supercontigs --- scripts `hybseq_4_alignment_*`.
* `4_gene_trees` --- Gene trees reconstructed by [IQ-TREE](http://www.iqtree.org/) from all recovered contigs sorted by `hybseq_5_gene_trees_4_postprocess.sh` into directories for exons, introns and supercontigs --- scripts `hybseq_5_gene_trees_*`.
* `5_sp_trees` --- Species trees reconstructed from sets of gene trees by [ASTRAL](https://github.com/smirarab/ASTRAL) --- scripts `hybseq_6_sp_tree_*`.

# Required software

* ASTRAL <https://github.com/smirarab/ASTRAL>
* BBMap <https://sourceforge.net/projects/bbmap/>
* Biopython <https://biopython.org/>
* BLAST+ <https://blast.ncbi.nlm.nih.gov/>
* BWA <https://github.com/lh3/bwa>
* Exonerate <https://www.ebi.ac.uk/about/vertebrate-genomics/software/exonerate>
* FastQC <https://www.bioinformatics.babraham.ac.uk/projects/fastqc/>
* GNU Parallel <https://www.gnu.org/software/parallel/>
* HybPiper <https://github.com/mossmatters/HybPiper/wiki>
* IQ-TREE <http://www.iqtree.org/>
* Java <https://www.java.com/> or OpenJDK <https://openjdk.java.net/>
* MAFFT <https://mafft.cbrc.jp/alignment/software/>
* Python <https://www.python.org/>
* R <https://www.r-project.org/>
* Samtools <http://www.htslib.org/>
* SPAdes <https://github.com/ablab/spades>
* Trimmomatic <http://www.usadellab.org/cms/?page=trimmomatic>

# Description and usage of the scripts

Scripts `hybseq_1_prep_1_qsub.sh`, `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_2_hybpiper_2_qsub.sh`, `hybseq_3_hybpiper_postprocess_1_qsub.sh`, `hybseq_4_alignment_1_submitter.sh`, `hybseq_4_alignment_2_qsub.sh`, `hybseq_5_gene_trees_1_submitter.sh`, `hybseq_5_gene_trees_2_qsub.sh` and `hybseq_6_sp_tree_1_qsub.sh` (scripts named `hybseq_*_qsub.sh` and `hybseq_*_submitter.sh`) contain settings for submission of each step (see further) on clusters using `PBS Pro`. **These scripts require edits.** At least paths must be changed there. According to cluster settings, commands `module add` and `qsub` (and probably some other things) will have to be edited. So they are rather inspiration for users of another clusters than [MetaCentrum](https://www.metacentrum.cz/).

Scripts `hybseq_2_hybpiper_1_submitter.sh`, `hybseq_4_alignment_1_submitter.sh` and `hybseq_5_gene_trees_1_submitter.sh` process in given directory all files (HybPiper, alignments and reconstruction of gene trees, respectively) and prepare individual task (job) for each file to be submitted by `hybseq_2_hybpiper_2_qsub.sh`, `hybseq_4_alignment_2_qsub.sh` and `hybseq_5_gene_trees_2_qsub.sh`, respectively using `PBS Pro` (command `qsub`).

All scripts are relatively simple and can be easily edited to change parameters of various steps, or some parts (like MAFFT or IQ-TREE) can be easily replaced by another tools.

## 1. Pre-processing data --- trimming, deduplication, quality checks and statistics

Used scripts: `hybseq_1_prep_1_qsub.sh` and `hybseq_1_prep_2_run.sh`.

Script `hybseq_1_prep_1_qsub.sh` contains settings for submission of the task on cluster using `PBS Pro` and runs `hybseq_1_prep_2_run.sh` to trimm, deduplicate and quality check all FASTQ files in a given directory.

It requires [BBMap](https://sourceforge.net/projects/bbmap/), [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [GNU Parallel](https://www.gnu.org/software/parallel/) and [Trimmomatic](http://www.usadellab.org/cms/?page=trimmomatic).

Edit in `hybseq_1_prep_1_qsub.sh` variables to point to correct locations:

* `WORKDIR` --- Point to `hybseq` directory containing this script set.
* `DATADIR` --- Point to directory containing raw FASTQ files named like `sampleXY.R1.fq` and `sampleXY.R2.fq` for forward/reverse reads of each sample, i.e. with suffix `.R1.fq` and `.R2.fq`. Recommended is compression by `bzip2` (i.e. `sampleXY.R1.fq.bz2` and `sampleXY.R2.fq.bz2`), e.g. `XXX/1_data/lib_01/0_data`.

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

Each sample (i.e. pair of files `sampleXY.dedup.R1.fq.bz2` and `sampleXY.dedup.R2.fq.bz2` produced by `hybseq_1_prep_2_run.sh`) is processed as separate job. File `samples_list.txt` created by `hybseq_1_prep_2_run.sh` is used by `hybseq_2_hybpiper_1_submitter.sh` to drive the job submission.

Script `hybseq_2_hybpiper_1_submitter.sh` contains settings (paths etc.) needed for submission of the task on cluster using `PBS Pro`. It is using `qsub` to submit `hybseq_2_hybpiper_2_qsub.sh` to process all deduplicated FASTQ files (in directory like `XXX/1_data/lib_01/2_dedup`) with [HybPiper](https://github.com/mossmatters/HybPiper/wiki). For every sample listed in `samples_list.txt` (created by `hybseq_1_prep_2_run.sh`) script `hybseq_2_hybpiper_1_submitter.sh` submits individual job with `hybseq_2_hybpiper_2_qsub.sh`. Finally, `hybseq_2_hybpiper_3_run.sh` is using [HybPiper](https://github.com/mossmatters/HybPiper/wiki) to process the sample. This script can be edited to use different HybPiper settings.

It requires [Biopython](https://biopython.org/), [BLAST+](https://blast.ncbi.nlm.nih.gov/), [BWA](https://github.com/lh3/bwa), [Exonerate](https://www.ebi.ac.uk/about/vertebrate-genomics/software/exonerate), [GNU Parallel](https://www.gnu.org/software/parallel/), [HybPiper](https://github.com/mossmatters/HybPiper/wiki), [Python](https://www.python.org/), [Samtools](http://www.htslib.org/) and [SPAdes](https://github.com/ablab/spades).

Edit variables in `hybseq_2_hybpiper_1_submitter.sh`:

* `HYBPIPDIR` --- Point to directory containing [HybPiper](https://github.com/mossmatters/HybPiper/).
* `WORKDIR` --- Point to `hybseq` directory containing this script set.
* `DATADIR` --- Point to directory containing deduplicated FASTQ files named like `sampleXY.dedup.R1.fq` and `sampleXY.dedup.R2.fq` (produced by `hybseq_1_prep_2_run.sh`) for forward/reverse reads of each sample. The directory is e.g. `XXX/1_data/lib_01/2_dedup`.
* `SAMPLES` --- File name of list of samples according to [HybPiper requirements](https://github.com/mossmatters/HybPiper/wiki#running-the-pipeline) to be processed (prepared by `hybseq_1_prep_2_run.sh` as `samples_list.txt`).
* `BAITFILE` --- Reference bait FASTA file (see <https://github.com/mossmatters/HybPiper/wiki#target-file> for details) --- must be relative path within `WORKDIR`, recommended placement is `ref` directory (see `README.md` there).
* `NCPU` --- Number of CPU threads used. Default is 8.

Depending on the cluster (if using something else than [MetaCentrum](https://www.metacentrum.cz/)) script `hybseq_2_hybpiper_2_qsub.sh` will have to be edited (e.g. loading needed software modules by `module add`). As `hybseq_2_hybpiper_3_run.sh` contains settings for processing each input file by [HybPiper](https://github.com/mossmatters/HybPiper/wiki) itself, it can be edited to change HybPiper settings.

When done with edits, simply run the `hybseq_2_hybpiper_1_submitter.sh` script --- it will go to `DATADIR` and submit job for every sample listed in `samples_list.txt` (`SAMPLES`):

```shell
./hybseq_2_hybpiper_1_submitter.sh
```

Result for each library will be copied back into `DATADIR`, e.g. `XXX/1_data/lib_01/2_dedup`. It's possible to move report files into their directories by something like:

```shell
while read L; do mv HybPiper."$L".[eo]* "$L"/; done < samples_list.txt
```

All outputs can be moved from `XXX/1_data/lib_01/2_dedup` to `XXX/2_seqs` by running something like the following command in `DATADIR`:

```shell
mv *.dedup ../../../2_seqs/
```

Finally, all processed samples (directories created by HybPiper) should be in directory `XXX/2_seqs`.

### 2.2. Retrieving sequences and obtain statistics with HybPiper

Used scripts: `hybseq_3_hybpiper_postprocess_1_qsub.sh` and `hybseq_3_hybpiper_postprocess_2_run.sh`.

All processed samples (directories created by HybPiper) should be in directory `2_seqs`. If merging multiple libraries, either merge the `samples_list.txt` from each library, or run in `2_seqs` directory something like:

```shell
find . -maxdepth 1 -type d | sed 's/^\.\///' | sort | tail -n+2 > samples_list.txt
```

to create new `samples_list.txt` listing all samples.

Script `hybseq_3_hybpiper_postprocess_1_qsub.sh` contains settings for submission of the task on cluster using `PBS Pro` and runs `hybseq_3_hybpiper_postprocess_2_run.sh` to retrieve sequences from HybPiper outputs and to obtain retrieval statistics.

It requires [Biopython](https://biopython.org/), [HybPiper](https://github.com/mossmatters/HybPiper/wiki), [Python](https://www.python.org/), [R](https://www.r-project.org/) and [Samtools](http://www.htslib.org/).

Edit variables in `hybseq_3_hybpiper_postprocess_1_qsub.sh`:

* `HYBPIPDIR` --- Point to directory containing [HybPiper](https://github.com/mossmatters/HybPiper/wiki).
* `WORKDIR` --- Point to `hybseq` directory containing this script set.
* `BAITFILE` --- Reference bait FASTA file (see <https://github.com/mossmatters/HybPiper/wiki#target-file> for details) --- must be relative path within `WORKDIR`
* `DATADIR` --- Point to directory containing all outputs of HybPiper from previous step and `samples_list.txt` listing them, e.g. `XXX/2_seqs`.
* `SAMPLES` --- File name of list of samples according to [HybPiper requirements](https://github.com/mossmatters/HybPiper/wiki#running-the-pipeline) to be processed.

See `README.md` in the `rpackages` directory for information regarding installation of `R` packages needed by `hybseq_3_hybpiper_postprocess_2_run.sh`.

Results will be copied back into `DATADIR`, e.g. `XXX/2_dedup`. After adding new sequenced library, this step and all following steps must be repeated.

## 3. Alignments of all contigs

Used scripts: `hybseq_4_alignment_1_submitter.sh`, `hybseq_4_alignment_2_qsub.sh`, `hybseq_4_alignment_3_run.r` and `hybseq_4_alignment_4_postprocess.sh`.

Aligns all FASTA files in `DATADIR` named `*.FNA` or `*.fasta` (output of `hybseq_3_hybpiper_postprocess_2_run.sh`), for each of them submits job using `qsub` to process the sample with [MAFFT](https://mafft.cbrc.jp/alignment/software/) and [R](https://www.r-project.org/) (see `README.md` in `rpackages` directory for installation of needed R packages).

Script `hybseq_4_alignment_1_submitter.sh` contains settings (paths etc.) needed for submission of the task on cluster using `PBS Pro`. It is using `qsub` to submit `hybseq_4_alignment_2_qsub.sh` to align all FASTA files (named `*.FNA` or `*.fasta`) retrieved by `hybseq_3_hybpiper_postprocess_2_run.sh` (in directory like `XXX/2_dedup`) with [MAFFT](https://mafft.cbrc.jp/alignment/software/) and [R](https://www.r-project.org/). For every `*.FNA` or `*.fasta` file (created by `hybseq_3_hybpiper_postprocess_2_run.sh`) script `hybseq_4_alignment_1_submitter.sh` submits individual job with `hybseq_4_alignment_2_qsub.sh`. Finally, `hybseq_4_alignment_3_run.r` is using [MAFFT](https://mafft.cbrc.jp/alignment/software/) and [R](https://www.r-project.org/) to process the file. This script can be edited to use different alignment settings.

It requires [MAFFT](https://mafft.cbrc.jp/alignment/software/) and [R](https://www.r-project.org/). See `README.md` in `rpackages` directory for installation of needed R packages.

Edit variables in `hybseq_4_alignment_1_submitter.sh`:

* `WORKDIR` --- Point to `hybseq` directory containing this script set.
* `DATADIR` --- Point to directory containing all outputs of HybPiper from previous step, e.g. `XXX/2_seqs`.

Depending on the cluster (if using something else than [MetaCentrum](https://www.metacentrum.cz/)) script `hybseq_4_alignment_2_qsub.sh` will have to be edited (e.g. loading needed software modules by `module add`). As `hybseq_4_alignment_3_run.r` contains settings for alignment of each input file, especially filtering after alignment by [MAFFT](https://mafft.cbrc.jp/alignment/software/), it can be edited to alter produced alignments.

When done with edits, simply run the `hybseq_4_alignment_1_submitter.sh` script --- it will go to `DATADIR` and submit job for every FASTA file (all `*.FNA` and `*.fasta` files):

```shell
./hybseq_4_alignment_1_submitter.sh
```

Result will be copied into newly created directory `aligned` in `DATADIR` directory, e.g. `XXX/2_seqs/aligned`. Reports of `PBS Pro` use to be in `DATADIR` and should be also moved to the `aligned` directory. Everything should be moved from `XXX/2_seqs/aligned` to `XXX/3_aligned`.

Finally, alignments should be sorted using `hybseq_4_alignment_4_postprocess.sh`. The script requires single argument --- directory to process, so run it like:

```shell
./hybseq_4_alignment_4_postprocess.sh XXX/3_aligned | tee hybseq_align_postprocess.log
mv hybseq_align_postprocess.log XXX/3_aligned/
```

Script `hybseq_4_alignment_4_postprocess.sh` will create directories `exons`, `introns` and `supercontigs` and move there respective files. It will also create three lists of minimum evolution gene trees (`trees_exons.nwk`, `trees_introns.nwk` and `trees_supercontigs.nwk`) and files with statistics (`alignments_stats_exons.tsv`, `alignments_stats_introns.tsv` and `alignments_stats_supercontigs.tsv`). The `TSV` files show number of sequences in each alignment file, number of sites (length of the sequence) and number of sites with 1, 2, 3 or 4 observed bases (6 data columns). These statistics can help to discard too short or otherwise problematic alignments.

The tree lists contain on the beginning of each line name of respective genetic region (according to reference bait file). This is advantageous for loading the lists into `R`, but many software like [ASTRAL](https://github.com/smirarab/ASTRAL) require each line to start directly with the NEWICK record. If this is the case (e.g. if user does not plan to load the list of gene trees into `R`), remove the names by something like:

```shell
sed -i 's/^[[:graph:]]\+ //' *.nwk
```

## 4. Gene trees from all alignments

Used scripts: `hybseq_5_gene_trees_1_submitter.sh`, `hybseq_5_gene_trees_2_qsub.sh`, `hybseq_5_gene_trees_3_run.sh` and `hybseq_5_gene_trees_4_postprocess.sh`.

Computes gene trees for all aligned contigs named `*.aln.fasta` (output of `hybseq_4_alignment_3_run.r`) in `DATADIR` and all subdirectories, for each of them submits job using `qsub` to process the sample with [IQ-TREE](http://www.iqtree.org/).

Script `hybseq_5_gene_trees_1_submitter.sh` contains settings (paths etc.) needed for submission of the task on cluster using `PBS Pro`. It is using `qsub` to submit `hybseq_5_gene_trees_2_qsub.sh` to compute gene trees from all aligned contigs (output of `hybseq_4_alignment_3_run.r`) with [IQ-TREE](http://www.iqtree.org/). For every `*.aln.fasta` file (created by `hybseq_4_alignment_3_run.r`) script `hybseq_5_gene_trees_1_submitter.sh` submits individual job with `hybseq_5_gene_trees_2_qsub.sh`. Finally, `hybseq_5_gene_trees_3_run.sh` is using [IQ-TREE](http://www.iqtree.org/) to process the file. This script can be edited to use different gene tree inference settings.

It requires [IQ-TREE](http://www.iqtree.org/).

Edit variables in `hybseq_5_gene_trees_1_submitter.sh`:

* `WORKDIR` --- Point to `hybseq` directory containing this script set.
* `DATADIR` --- Point to directory containing all aligned contigs from previous step, e.g. `XXX/3_aligned`.

Depending on the cluster (if using something else than [MetaCentrum](https://www.metacentrum.cz/)) script `hybseq_5_gene_trees_2_qsub.sh` will have to be edited (e.g. loading needed software modules by `module add`). As `hybseq_5_gene_trees_3_run.sh` contains settings for gene tree inference of each input file by [IQ-TREE](http://www.iqtree.org/), it can be edited to alter produced gene trees.

When done with edits, simply run the `hybseq_5_gene_trees_1_submitter.sh` script --- it will go to `DATADIR` and submit job for every FASTA file (all `*.aln.fasta` files):

```shell
./hybseq_5_gene_trees_1_submitter.sh
```

Result will be copied into newly created directory `trees` in `DATADIR` directory, e.g. `XXX/3_aligned/trees`. Reports of `PBS Pro` use to be in `DATADIR` and should be also moved to the `trees` directory. Everything should be moved from `XXX/3_aligned/trees` to `XXX/4_gene_trees`.

Finally, gene trees should be sorted using `hybseq_5_gene_trees_4_postprocess.sh`. The script requires single argument --- directory to process, so run it like:

```shell
./hybseq_5_gene_trees_4_postprocess.sh XXX/4_gene_trees | tee hybseq_gene_trees_postprocess.log
mv hybseq_gene_trees_postprocess.log XXX/4_gene_trees/
```

Script `hybseq_5_gene_trees_4_postprocess.sh` will create directories `exons`, `introns` and `supercontigs` and move there respective files. It will also create three lists of maximum likelihood trees trees (`trees_ml_exons.nwk`, `trees_ml_introns.nwk` and `trees_ml_supercontigs.nwk`) and three lists of consensus bootstrapped trees (`trees_cons_exons.nwk`, `trees_cons_introns.nwk` and `trees_cons_supercontigs.nwk`).

The tree lists contain on the beginning of each line name of respective genetic region (according to reference bait file). This is advantageous for loading the lists into `R`, but many software like [ASTRAL](https://github.com/smirarab/ASTRAL) require each line to start directly with the NEWICK record. If this is the case (e.g. if user does not plan to load the list of gene trees into `R`), remove the names by something like:

```shell
sed -i 's/^[[:graph:]]\+ //' *.nwk
```

