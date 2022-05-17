# Author: Vojtěch Zeisek, https://trapa.cz/
# License: GNU General Public License 3.0, https://www.gnu.org/licenses/gpl-3.0.html

# R script taking as arguments name of input file and names of all outputs.
# Load FASTA sequence, alignes them with MAFFT, cleanes the alignment, exports it, creates minimum evolution tree and saves it and saves alignment checks.

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## Do not exit on error
options(error=expression(NULL))

## Packages
# Install
# install.packages(pkgs=c("ape", "ips"), lib="rpackages", repos="https://mirrors.nic.cz/R/", dependencies="Imports")
# Load
library(package=ape, lib.loc="rpackages")
library(package=ips, lib.loc="rpackages")
library(package=scales, lib.loc="rpackages")

## File names
fnames <- commandArgs(TRUE) # [1] file.fasta/file.FNA, [2] file.aln.fasta, [3] file.aln.png, [4] file.aln.check.png, [5] file.nwk, [6] file.tree.png, [7] file.saturation.png
fnames

## Load FASTA sequence
seqf <- read.FASTA(file=fnames[1], type="DNA")
seqf

## Alignment with MAFFT
aln <- mafft(x=seqf, method="auto", maxiterate=1000, options="--adjustdirectionaccurately", thread=1, exec="/software/mafft/7.487/bin/mafft")
aln
# Remove "_R_" marking reversed sequences (introduced by MAFFT's "--adjustdirectionaccurately")
rownames(aln) <- gsub("^_R_", "", rownames(aln))

## Cleaning the alignment
# Delete empy columns/rows
aln.ng <- deleteEmptyCells(DNAbin=aln)
# Delete columns and rows with too many gaps
# Add/replace by ips::gblocks and/or ips::aliscore ?
aln.ng <- deleteGaps(x=aln.ng, gap.max=round(nrow(aln)/2))
aln.ng <- del.rowgapsonly(x=aln.ng, threshold=0.2, freq.only=FALSE)
aln.ng <- del.colgapsonly(x=aln.ng, threshold=0.2, freq.only=FALSE)
aln.ng

## Exporting alignment
write.FASTA(x=aln.ng, file=fnames[2])

## Number of potentially-informative sites
pis(x=aln.ng, what="fraction")

## Displaying alignment
# Alignment
png(filename=fnames[3], width=2000, height=1000, units="px", bg="white")
	image.DNAbin(x=(x=as.matrix.DNAbin(x=aln.ng)))
	dev.off()
# Checks
png(filename=fnames[4], width=2000, height=1000, units="px", bg="white")
	checkAlignment(x=as.matrix.DNAbin(x=aln.ng), check.gaps=TRUE, plot=TRUE, what=1:4)
	dev.off()

## FastME minimum evolution tree
# DNA distance
gdist <- dist.dna(x=aln.ng, model="TN93")
# NJ tree
njtr <- fastme.bal(X=gdist, nni=TRUE, spr=TRUE, tbr=TRUE)
# Bootstrap
njtr[["node.labels"]] <- boot.phylo(phy=njtr, x=aln.ng, FUN=function(FMT) fastme.bal(X=dist.dna(x=FMT, model="TN93"), nni=TRUE, spr=TRUE, tbr=TRUE), B=1000, quiet=TRUE, mc.cores=1)
# Export
write.tree(phy=njtr, file=fnames[5])
# Plot the tree
png(filename=fnames[6], width=1200, height=1200, units="px", bg="white")
	plot.phylo(x=njtr, type="unrooted", edge.width=2, cex=1.1, lab4ut="axial", tip.color="blue")
	title("FastME minimum evolution tree and bootstrap values (1000 replicates, TN93 distance)")
	add.scale.bar()
	nodelabels(text=round(njtr[["node.labels"]]/10), frame="none", col="red")
	dev.off()

## Saturation plot
# Raw DNA distance
gdist.r <- dist.dna(x=aln.ng, model="raw")
# Linear morel of distances
dlm <- lm(formula=gdist.r~gdist)
# Plot saturation
png(filename=fnames[7], width=900, height=900, units="px", bg="white")
	plot(gdist.r~gdist, xlab="TrN (TN93) model distance", ylab="Uncorrected distance", main="Saturation plot", col=alpha(colour="red", alpha=0.2), pch=20, cex=3)
	abline(a=0, b=1, lty=4, lwd=2, col="blue")
	abline(dlm, lty=5, lwd=3, col="green")
	legend("topleft", legend=bquote(y==.(coef(object=dlm)[2])*x), cex=1.25, inset=0.02)
	legend("bottomright", legend="Linear model of distances", cex=1.25, title="Dashed green line", inset=0.02)
	dev.off()

