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
* TreeShrink <https://github.com/uym2/TreeShrink>
* Trimmomatic <http://www.usadellab.org/cms/?page=trimmomatic>

## R packages used

* ade4 <https://cran.r-project.org/package=ade4>
* adegenet <https://cran.r-project.org/package=adegenet>
* ape <https://cran.r-project.org/package=ape>
* corrplot <https://cran.r-project.org/package=corrplot>
* distory <https://cran.r-project.org/package=distory>
* ggplot2 <https://cran.r-project.org/package=ggplot2>
* gplots <https://cran.r-project.org/package=gplots>
* heatmap.plus <https://cran.r-project.org/package=heatmap.plus>
* ips <https://cran.r-project.org/package=ips>
* kdetrees <https://cran.r-project.org/package=kdetrees>
* pegas <https://cran.r-project.org/package=pegas>
* phangorn <https://cran.r-project.org/package=phangorn>
* phytools <https://cran.r-project.org/package=phytools>
* reshape2 <https://cran.r-project.org/package=reshape2>

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
* `SAMPLES` --- File name of list of samples according to [HybPiper requirements](https://github.com/mossmatters/HybPiper/wiki#20-running-the-pipeline) to be processed (prepared by `hybseq_1_prep_2_run.sh` as `samples_list.txt`).
* `BAITFILE` --- Reference bait FASTA file (see <https://github.com/mossmatters/HybPiper/wiki#12-target-file> for details) --- must be relative path within `WORKDIR`, recommended placement is `ref` directory (see `README.md` there).
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

HybPiper statistics are in files `seq_lengths.txt` (table of length of each retrieved seqeunce in every sample) and `stats.txt` (sequence statistics, see [manual](https://github.com/mossmatters/HybPiper/wiki/Tutorial#summary-statistics)).

Statistics of how many was each sample retrieved from the sequences are in file `presence_of_samples_in_contigs.tsv`. Note that for every probe sequence, three contigs are produced (for respective exon, intron and supercontig). Divide 'Total number of contigs' by three to get number of probes. Similarly divide number of occurrence of each sample by three. You can calculate percentage of presence of each sample in all contigs (from total number of contigs). If some sample is recovered in less than ca. 50% of contigs, consider its removal.

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

Note that the script should be runned when all alignments are in final destination, i.e. `XXX/3_aligned`.

Script `hybseq_4_alignment_4_postprocess.sh` will create directories `exons`, `introns` and `supercontigs` and move there respective files. It will also create three lists of minimum evolution gene trees (`trees_exons.nwk`, `trees_introns.nwk` and `trees_supercontigs.nwk`) and files with statistics (`alignments_stats_exons.tsv`, `alignments_stats_introns.tsv` and `alignments_stats_supercontigs.tsv`). The `TSV` files show number of sequences in each alignment file, number of sites (length of the sequence) and number of sites with 1, 2, 3 or 4 observed bases (6 data columns). These statistics can help to discard too short or otherwise problematic alignments.

The tree lists contain on the beginning of each line name of respective genetic region (according to reference bait file). This is advantageous for loading the lists into `R`, but many software like [ASTRAL](https://github.com/smirarab/ASTRAL) require each line to start directly with the NEWICK record. If this is the case (e.g. if user does not plan to load the list of gene trees into `R`), remove the names by something like:

```shell
sed -i 's/^[[:graph:]]\+ //' *.nwk
```

Final output are simple statistics of presence of samples in all alignments (how many times is each sample presented in trimmed alignments), created for exons (`presence_of_samples_in_exons.tsv`), introns (`presence_of_samples_in_introns.tsv`) as well as supercontigs (`presence_of_samples_in_supercontigs.tsv`).

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

## 5. Species trees from sets of gene trees

The final step is to create species tree out of set of gene trees from previous steps. Lists of gene trees can be compared and outliers (trees with significant different topology than majority) can be detected, explored and possibly removed. Following code and `hybseq_6_sp_tree_*` scripts serve rather like inspiration than fixed workflow.

### 5.1. Exploration of differences among gene trees, filtration of gene trees

Comparison of gene trees start with identifying trees with significantly different topology. There are several distance matrices allowing compare topological differences among trees (and subsequently plot heatmap, PCoA, etc.) - to compare topology of trees, we need some apropriate distance matrix, but there is no general agreement which is the best, all have issues. In any case, the resulting distance must be [Euclidean](https://en.wikipedia.org/wiki/Euclidean_distance_matrix).

Common distance comparing multiple phylogenetic trees is Robinsons-Foulds distance (`phytools::multiRF` in `R`). The index adds 1 for each difference between pair of trees. Well defined only for fully bifurcating trees --- if not fulfilled, some results might be misleading. Allow comparison of trees created by different methods. If the difference is very close to root, RF value can be large, even there are not much differences in the tree at all --- e.g. geodesic distance (`dist.multiPhylo` in `R`) can be an alternative, although its interpretation is sometimes not so straightforward as simple logic of RF. There are more options in `R`. Methods implemented in `ape::dist.topo` allow comparison of trees with polytomies (`method="PH85"`) or use of squared lengths of internal branches (`method="score"`).

if the final distance matrix is not [Euclidean](https://en.wikipedia.org/wiki/Euclidean_distance_matrix) (test in `R` with `ade4::is.euclid`), it can be scaled by `ade4::quasieuclid` or `ade4::cailliez`, but it can damage meaning of the data.

Software and tasks:

* Identification, inspection and possible removal of gene trees with significantly different topology, e.g. by [R](https://www.r-project.org/) and packages [ape](https://cran.r-project.org/package=ape) and [kdetrees](https://cran.r-project.org/package=kdetrees), or by [TreeShrink](https://github.com/uym2/TreeShrink).
* Comparison of gene trees, e.g. heatmaps and PCoA by [R](https://www.r-project.org/) and packages [ade4](https://cran.r-project.org/package=ade4), [ape](https://cran.r-project.org/package=ape), [distory](https://cran.r-project.org/package=distory), [phytools](https://cran.r-project.org/package=phytools).
* Comparison of (several) (species) trees, e.g.by [R](https://www.r-project.org/) and packages [ape](https://cran.r-project.org/package=ape) or [phytools](https://cran.r-project.org/package=phytools).

We will get matrix of pairwise differences among trees (from multiple genes), we need display and analyze it:

```R
# Load libraries
library(ape)
library(ade4)
library(distory)
library(gplots)
library(ggplot2)
library(kdetrees)
library(phangorn)
# Load the list of trees
trees <- read.tree(file="trees_ml_exons.nwk")
trees # See it
# Root all trees
trees <- root.multiPhylo(phy=trees, outgroup="o_purpurascens_S482", resolve.root=TRUE)
print(trees, details=TRUE)
# Compute distance of topological similarities
trees.d <- dist.topo(x=trees, method="score") # Of course, another method can be selected
# Plot the heatmap e.g. using gplots::heatmap
png(filename="trees_dist.png", width=10000, height=10000)
  heatmap.2(x=as.matrix(trees.d), Rowv=FALSE, Colv="Rowv", dendrogram="none", symm=TRUE, scale="none",
    na.rm=TRUE, revC=FALSE, col=rainbow(15), cellnote=as.matrix(trees.d), notecex=1, notecol="white",
    trace="none", labRow=rownames(as.matrix(trees.d)), labCol=colnames (as.matrix(trees.d)), key=FALSE,
    main="Correlation matrix of topographical distances")
  dev.off() # Saves the image
# Test if the distance matrix is Euclidean
is.euclid(distmat=as.dist(trees.d), plot=TRUE, tol=1e-05)
```

Now it is possible to get PCoA of differences among the trees. If some gene tree is identified as an outlier, it should be explored. It can be paralog, but it can be also result of some technical problem, low quality DNA, etc. Such trees can be removed from the list.

```R
# PCoA
trees.pcoa <- dudi.pco(d=trees.d, scannf=FALSE, nf=5)
trees.pcoa
# Plot PCoA - this is only basic display
s.label(dfxy=trees.pcoa$li)
s.kde2d(dfxy=trees.pcoa$li, cpoint=0, add.plot=TRUE)
add.scatter.eig(trees.pcoa[["eig"]], 3,1,2, posi="bottomleft")
title("PCoA of matrix of pairwise trees distances")
```

[Kdetrees](https://cran.r-project.org/package=kdetrees) finds discordant phylogenetic trees. It produces relative scores (and list of passing/discarded trees and graphical outputs) --- high are relatively similar to each other, low dissimilar (discordant with the others). In `kdetrees::kdetrees()`, value of `k` (see code below) is responsible for threshold for removal of outliers --- play with it.

```R
# Run kdetrees to detect outliers - play with k
trees.kde <- kdetrees(trees=trees, k=0.5, distance="dissimilarity", topo.only=FALSE, greedy=TRUE) # Play with k!
# See text results with list of outlying trees
trees.kde
# See graphical results
plot(x=trees.kde)
hist(x=trees.kde)
# See removed trees
plot.multiPhylo(trees.kde[["outliers"]])
# Save removed trees
write.tree(phy=trees.kde[["outliers"]], file="trees_outliers.nwk")
# Save kdetrees report
write.table(x=as.data.frame(x=trees.kde), file="trees_scores.tsv", quote=FALSE, sep="\t")
# Extract passing trees
trees.good <- trees[names(trees) %in% names(trees.kde[["outliers"]]) == FALSE]
trees.good
# Save passing trees
write.tree(phy=trees.good, file="trees_good.nwk")
```

[TreeShrink](https://github.com/uym2/TreeShrink) implements an [algorithm](https://bmcgenomics.biomedcentral.com/articles/10.1186/s12864-018-4620-2) for detecting abnormally long branches in one or more phylogenetic trees. It requires [R](https://www.r-project.org/) to be installed. Output (2 files) is saved into directory (in our case) `trees_good_treeshrink` (see code below). File `*.nwk` contains new list of phylogenetic trees in `NEWICK` which can be then used as an input for any species tree reconstruction software (e.g. ASTRAL below). File `*_RS_*.txt` is bit hard to read, it has one line for every tree in the input list and every line contains list of removed tips. If there is an empty line, no tip was removed from that particular tree. Trees are not named, only in same order as in the original input file.

```shell
# Clone Git repository and install TreeShrink
# Go to ~/bin directory
cd ~/bin/ || { mkdir ~/bin && cd ~/bin/; }
# Download TreeShrink
git clone https://github.com/uym2/TreeShrink.git
cd TreeShrink/
# Install it
python3 setup.py install --user # Or if using conda
# Go to directory with input file trees_good.nwk and run TreeShrink
python3 ~/bin/TreeShrink/run_treeshrink.py -r ~/bin/TreeShrink/ -t trees_good.nwk
# Find out how many times particular sample was removed from the list of the trees
grep -o "\<[[:graph:]]\+\>" trees_good_RS_0.05.txt | sort | uniq -c | sort -r
```

### 5.2. Species trees

Used scripts: `hybseq_6_sp_tree_1_qsub.sh` and `hybseq_6_sp_tree_2_run.sh`.

Creates species trees from all sets of gene trees named `*.nwk` (output of `hybseq_5_gene_trees_4_postprocess.sh`, possibly after manual filtration above) in `DATADIR` on cluster using `PBS Pro` (using `qsub`).

It requires [ASTRAL](https://github.com/smirarab/ASTRAL).

The tree lists created by `hybseq_5_gene_trees_4_postprocess.sh` contain on the beginning of each line name of respective genetic region (according to reference bait file). This is advantageous for loading the lists into `R`, but [ASTRAL](https://github.com/smirarab/ASTRAL) requires each line to start directly with the NEWICK record. Remove the names by something like:

```shell
sed -i 's/^[[:graph:]]\+ //' *.nwk
```

Before running `hybseq_6_sp_tree_1_qsub.sh`. Tree lists exported from `R` or another software like TreeShrink above can be directly used for this script --- in such case **do not run the above command!**

When ready, submit the job by something like:

```shell
qsub -l walltime=1:0:0 -l select=1:ncpus=1:mem=4gb:scratch_local=1gb -q ibot -m abe \
~/hybseq/bin/hybseq_6_sp_tree_1_qsub.sh
```

Output files with species trees are prefixed by `sp_` and `*.log` files contain complete record of running ASTRAL.

There are plenty of options for species tree reconstruction. E.g. `R` has parsimony implemented in `phangorn::superTree` or `phytools::mrp.supertree`. Distance-based tree reconstruction is in `ape::speciesTree` and coalescence model handling multiple individuals per species is in `phangorn::coalSpeciesTree`. Examples below are very basic.

```R
# Compute parsimony super tree
tree.sp <- superTree(tree=trees.good, method="NNI", rooted=TRUE, trace=2, start=NULL, multicore=TRUE)
# Rooting the species tree
tree.sp <- root(phy=tree.sp, outgroup="o_purpurascens_S482", resolve.root=TRUE)
tree.sp # See details
# Save parsimony super tree
write.tree(phy=tree.sp, file="parsimony_sp_tree.nwk")
# Plot parsimony super tree
plot.phylo(x=tree.sp, type="phylogram", edge.width=2, label.offset=0.01, cex=1.2)
add.scale.bar()
# For ape::speciesTree all trees must be ultrametric - chronos scale them
trees.ultra <- lapply(X=trees, FUN=chronos, model="correlated")
class(trees.ultra) <- "multiPhylo"
# Calculate the species tree with different methods
tree.sp.mean <- speciesTree(x=trees.ultra, FUN=mean)
tree.sp2 <- mrp.supertree(tree=trees, method="optim.parsimony", rooted=TRUE)
```

# Next steps

This section is rather exemplary, showing possible analysis.

## 1. Consensus network

Available in `R` in `phangorn::consensusNet`. Requires same set of tips in all trees.

```R
# Compute consensus network
tree.net <- consensusNet(obj=trees, prob=0.25)
# Plot the network in 2D or 3D
plot(x=oxalis.tree.net, planar=FALSE, type="2D", use.edge.length=TRUE, show.tip.label=TRUE, show.edge.label=TRUE,
  show.node.label=TRUE, show.nodes=TRUE, edge.color="black", tip.color="blue") # 2D
plot(x=oxalis.tree.net, planar=FALSE, type="3D", use.edge.length=TRUE, show.tip.label=TRUE, show.edge.label=TRUE,
  show.node.label=TRUE, show.nodes=TRUE, edge.color="black", tip.color="blue") # 3D
```

## 2. Phylogenetic network

[PhyloNet](https://bioinfocs.rice.edu/PhyloNet) requires as input NEXUS file with settings describing [PhyloNet commands](https://wiki.rice.edu/confluence/display/PHYLONET/List+of+PhyloNet+Commands) (see example below):

```
#NEXUS
BEGIN TREES;
... list of trees from trees_good.nwk newick file ...
# Ever tree starts with:
Tree TreeID = (tree in NWK)
... # All other trees ...
END;
BEGIN PHYLONET;
InferNetwork_MP (all) 1 -b 50 -x 5 -pl 2 -di;
END;
```

The `PHYLONET` section of the above input NEXUS contains settings according to [list of commands](https://wiki.rice.edu/confluence/display/PHYLONET/List+of+PhyloNet+Commands). TreeID can be completely random, or simple consecutive sequence like GT0001--GT####. PhyloNet can be computationally very demanding, calculating more than 1--3 reticulations can be unrealistic in terms of time needed...

When the input file is ready (see also [tutorial and help](https://wiki.rice.edu/confluence/pages/viewpage.action?pageId=39500205)), running PhyloNet is simple, but can take very long time and require a lot of resources:

```shell
# Download binary JAR file (ready to run)
wget https://bioinfocs.rice.edu/sites/g/files/bxs266/f/kcfinder/files/PhyloNet_3.8.2.jar
# Running PhyloNet
java -Xmx8g -jar PhyloNet_3.8.0.jar file.nex | tee file.log
```

It does not save output file, the network in special NWK format for [Dendroscope](https://www.wsi.uni-tuebingen.de/lehrstuehle/algorithms-in-bioinformatics/software/dendroscope/) is on the end --- copy it from terminal (after `Visualize in Dendroscope :`) or log file and save as tiny TXT, which can be opened in [Dendroscope](https://www.wsi.uni-tuebingen.de/lehrstuehle/algorithms-in-bioinformatics/software/dendroscope/).

## 3. Comparing species tree and gene trees

Comparison of species tree and gene trees by [phyparts](https://bitbucket.org/blackrim/phyparts) and visualization with [MJPythonNotebooks](https://github.com/mossmatters/MJPythonNotebooks). It requires `maven` and several Python packages (see below).

```shell
# Go to ~/bin directory
cd ~/bin/ || { mkdir ~/bin && cd ~/bin/; }
# Install Phyparts
git clone https://bitbucket.org/blackrim/phyparts.git
cd phyparts/
# Install dependencies
./mvn_cmdline.sh
# Install PhyParts_PieCharts
git clone https://github.com/mossmatters/MJPythonNotebooks.git
# Split list of trees into individual files
mkdir trees_good
split -a 4 -d -l 1 trees_good.nwk trees_good/trees_good_
ls trees_good/
# Remove IQTREE ultrafast bootstrap values from gene trees
sed -i 's/\/[0-9]\{1,3\}//g' trees_good/trees_*
# Analysis with phyparts
java -jar ~/bin/phyparts/target/phyparts-0.0.1-SNAPSHOT-jar-with-dependencies.jar -a 1 -d trees_good -m parsimony_sp_tree.nwk -o trees_good_res -s 0.5 -v
# Copy phypartspiecharts.py to directory with trees
cp ~/bin/phyparts/MJPythonNotebooks/phypartspiecharts.py .
# Run phypartspiecharts.py to get the graphical output
python phypartspiecharts.py --svg_name trees_good_res.svg parsimony_sp_tree.nwk trees_good_res 144
# Pie chart: concordance (blue) top conflict (green), other conflict (red), no signal (gray)
```

## 4. Comparing two or more trees

Comparing two trees — cophyloplots Slightly different implementation in R packages ape ( cophyloplot ) and phytools ( cophylo ) See help pages and play with graphical parameters

```R
# We need 2 column matrix with tip labels
tips.labels <- matrix(data=c(sort(tree.sp[["tip.label"]]), sort(tree.sp2[["tip.label"]])),
  nrow=length(tree.sp[["tip.label"]]), ncol=2)
# Draw the tree, play with graphical parameters
# Click to nodes to rotate them to get better display
cophyloplot(x=tree.sp, y=tree.sp2, assoc=tips.labels, use.edge.length=FALSE, space=60,
  length.line=1, gap=2, type="phylogram", rotate=TRUE, col="red", lwd=1.5, lty=2)
# Slihtly better display in phytools::cophylo
trees.cophylo <- cophylo(tr1=tree.sp, tr2=tree.sp2, assoc=tips.labels, rotate=TRUE)
plot.cophylo(x=trees.cophylo, lwd=2, link.type="curved")
```

Density tree The trees should be (otherwise plotting works, but may be more ugly) rooted, ultrametric and binary bifurcating implementations are in phangorn ( densiTree ) and phytools ( densityTree )

```R
is.rooted.multiPhylo(trees.ultra) # rooted
is.ultrametric.multiPhylo(trees.ultra) # ultrametric
is.binary.multiPhylo(trees.ultra) # binary bifurcating
# See help page
?phangorn::densiTree
# Plotting density trees
densiTree(x=trees.ultra[1:10], direction="downwards", scaleX=TRUE, col=rainbow(3), width=5, cex=1.5)
densiTree(x=trees.ultra, direction="upwards", scaleX=TRUE, width=5)
densiTree(x=trees.ultra, scaleX=TRUE, width=5, cex=1.5)
```

Different display for multiple trees phytools::densiTree requires same number of tips in all trees Note various ways how to select trees to display Nodes of the trees are not rotated (the display might be suboptimal)

```R
# Plotting density trees
densityTree(trees=c(tree.sp, tree.sp2), fix.depth=TRUE, use.gradient=TRUE, alpha=0.5, lwd=4)
densityTree(trees=trees.ultra, fix.depth=TRUE, use.gradient=TRUE, alpha=0.5, lwd=4)
densityTree(trees=trees.ultra[1:3], fix.depth=TRUE, use.gradient=TRUE, alpha=0.5, lwd=4)
densityTree(trees=trees.ultra[c(2,4,6,7)], fix.depth=TRUE, use.gradient=TRUE, alpha=0.5, lwd=4)
```

