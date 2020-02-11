# R packages

Required [R](https://www.r-project.org/) packages are `ape`, `ggplot2`, `gplots`, `heatmap.plus`, `ips` and `reshape2` and their dependencies for R version used (e.g. R 3.6) **must** be installed here.

Within `R` command line started in `hybseq` directory use e.g. command

	install.packages(pkgs=c("ape", "ggplot", "gplots", "heatmap.plus", "ips", "reshape"), lib="rpackages", repos="https://mirrors.nic.cz/R/", dependencies="Imports")

to install needed packages.

The R packages are required to plot heatmaps from [HybPiper](https://github.com/mossmatters/HybPiper/wiki) outputs and to align (and trim, check, plot, etc.) contigs recovered by HybPiper (script `hybseq_4_alignment_3_run.r`).

