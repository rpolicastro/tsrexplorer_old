% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/genomic_distribution.R
\name{plot_genomic_distribution}
\alias{plot_genomic_distribution}
\title{Plot Genomic Distribution}
\usage{
plot_genomic_distribution(genomic_distribution, sample_order = NULL)
}
\arguments{
\item{genomic_distribution}{tibble of TSS or TSR genomic distributions from tsr_genomic_distribution}

\item{sample_order}{Optional vector specifying order of samples to plot by sample name}
}
\value{
ggplot2 object with TSS or TSR genomic distribution plot
}
\description{
Plot genomic distribution of TSSs or TSRs
}
