# R packages

Required [R](https://www.r-project.org/) packages are `ape`, `ips` and `scales` and their dependencies for R version used (e.g. R 4.2) **must** be installed here.

Within `R` command line started in `hybseq` directory use e.g. command

```R
install.packages(pkgs=c("ape", "codetools", "cpp11", "farver", "ips", "RcppArmadillo",
"scales"), lib="rpackages", repos="https://mirrors.nic.cz/R/", dependencies="Imports")
```

to install needed packages.

The R packages are required to align (and trim, check, plot, etc.) contigs recovered by HybPiper (see script `hybseq_4_alignment_3_run.r`).

