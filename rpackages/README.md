# R packages

Required [R](https://www.r-project.org/) packages are `ape`, `ips` and `scales` and all their dependencies for R version used (e.g. R 4.5) **must** be installed here.

Within `R` command line started in `hybseq` directory use e.g. command

```R
install.packages(pkgs = c("ape", "codetools", "digest", "fastmatch", "farver",
  "generics", "glue", "igraph", "ips", "lattice", "lifecycle", "magrittr",
  "Matrix","nlme", "phangorn", "pkgconfig", "plyr", "quadprog", "R6", "Rcpp",
  "RColorBrewer", "rlang", "scales"), lib = "rpackages",
  repos = "https://cloud.r-project.org/", dependencies = "Imports")
```

to install needed packages.

The R packages are required to align (and trim, check, plot, etc.) contigs recovered by HybPiper (see script `hybseq_4_alignment_3_run.r`).

