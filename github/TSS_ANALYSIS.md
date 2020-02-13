# TSS Analysis

Transcription Start Sites (TSSs) represent the first base to be transcribed by RNA Polymerase.
Most genes tend to have a heterogenous collection of TSSs as opposed to a single position.
This is interesting because choice of TSS can affect gene isoform, stability, and translational efficiency.
Furthermore, TSS choice has been implicated in develoment, homseostasis, and disease.

tsrexploreR has a series of analysis and plotting functions to allow deep exploration of TSSs.

## Preparing Data

This example will use a set of *S. cerevisiae* TSSs collected using the STRIPE-seq method.
There are many ways to import TSSs into tsrexplorer.
This example data uses a named list of GRanges as imput into the function that creates the tsrexplorer object.

```
library("tsrexplorer")

TSSs <- system.file("extdata", "S288C_TSSs.RDS", package = "tsrexplorer")
TSSs <- readRDS(TSSs)

# Keep only the 3 WT samples for now.
TSSs <- names(TSSs) %>%
	stringr::str_detect("WT") %>%
	purrr::keep(TSSs, .)

exp <- tsr_explorer(TSSs)
```

## Processing of TSSs

After the TSSs are loaded into the tsrexplorer object,
there are a few processing steps to go through to get the data ready for analysis.
These steps include converting the TSSs into a 'RangedSummarizedExperiment',
CPM normalizing the TSSs, and then marking the dominant TSS.

### TSS Data Structure

The first step is to convert the TSSs into a 'RangedSummarizedExperiment'.
This object type is a convenient container that stores range, count, and sample information.

```
exp <- format_counts(exp, data_type = "tss")
```

### CPM Normalization

The next step is to Counts Per Million (CPM) normalize the TSSs and store them as an additional assay with the original counts.
This step is optional, and if the counts you inputed were normalized already this step can safely be skipped.

```
exp <- cpm_normalize(exp, data_type = "tss")
```

### Annotating TSSs

After formatting the counts and optionally CPM normalizing them, the TSSs will be annotated relative to known features.
This function takes either the path and file name of a 'GTF' or 'GFF' file, or a 'TxDb' package from bioconductor.
The annotation information will be added onto the range of the 'RangedSummarizedExperiment'.
The example below uses a 'GTF' file from Ensembl (R64-1-1 Release 99),
and will annotate each TSS to the closest transcript.

```
annotation <- system.file("extdata", "S288C_Annotation.gtf", package = "tsrexplorer")

exp <- annotate_features(
        exp, annotation_data = annotation,
        data_type = "tss", feature_type = "transcript"
)
```

### Feature Counting

Now that the TSSs are annotated relative to known features, an RNA-seq like summary of counts per feature can be generated.
TSSs that are upstream of the defined promoter region, or downstream of the last exon are ignored.
The feature counts can also be optionally CPM normalized as well.

```
exp <- count_features(exp)
exp <- cpm_normalize(exp, data_type = "features")
```

### Annotating Dominant TSSs

For the last processing step, the TSS with the highest score is marked for each feature.
Similar to the feature counting step above, TSSs that are upstream of the defined promoter region,
or downstream of the last exon are ignored.
If there are multiple TSSs with the same max score, all of those TSSs are considered.

It is sometimes interesting to look at dominant TSSs because this subset likely represents
the subset of genomic features (such as sequence) that are most preferred when the RNA Polymerase is choosing a TSS.
It thus is sometimes easier to resolve important features when looking at only the dominant TSSs.

```
exp <- dominant_tss(exp, threshold = 3)
```

## TSS Correlation

Finding the correlation between samples can be informative of both sequencing efficacy,
and to also get a cursory understanding about the differences between different samples.

### TMM Normalization

For correlation analysis, tsrexploreR uses 'TMM' normalization from the edgeR library.
This method was designed to make comparison *between* samples more efficacious.
In the example below, TSSs are retained only if at least one sample has a count of 3 or more reads.

```
exp <- tmm_normalize(exp, data_type = "tss", threshold = 3, n_samples = 1)
```

### Correlation Matrix Plots

After 'TMM' normalizing between the samples, various correlation plots can be generated by tsrexplorer.
An example is shown here, in which half the plot is a scatter plot, and the other half a heatmap.

```
p <- plot_correlation(exp, data_type = "tss", font_size = 2, pt_size = 0.4) +
        ggplot2::theme_bw() +
        ggplot2::theme(text = element_text(size = 3), panel.grid = element_blank())

ggsave("tss_correlation.png", plot = p, device = "png", type = "cairo", height = 2, width = 2)
```
![tss_corr_plot](../inst/images/tss_correlation.png)

## TSS Genomic Distribution

As part of the TSS processing steps, TSSs were annotated relative to known features.
This information can be used to explore the distribution of TSS throughout the genome,
as well as information on detected features.

### Genomic Distribution Plot

A stacked bar plot can be generated to showcase the fractional distribution of TSSs relative to features.

```
tss_distribution <- genomic_distribution(exp, data_type = "tss", threshold = 3)

p <- plot_genomic_distribution(tss_distribution) +
        ggplot2::theme(text = element_text(size = 4), legend.key.size = unit(0.3, "cm"))

ggsave("tss_genomic_distribution.png", plot = p, device = "png", type = "cairo", height = 1, width = 2.5)
```
![tss_genomic_distribution](../inst/images/tss_genomic_distribution.png)

### Feature Detection Plot

The number of genes, and fraction of genes with a promoter proximal TSSs can be made into a stacked bar plot.

```
features <- detect_features(exp, data_type = "tss", threshold = 3)

p <- plot_detected_features(features) +
	ggplot2::theme(text = element_text(size = 3), legend.key.size = unit(0.3, "cm"))

ggsave("tss_feature_plot.png", plot = p, device = "png", type = "cairo", height = 1, width = 1.75)
```

![tss_feature_plot](../inst/images/tss_feature_plot.png)

### Average Plots

Another useful plot type for TSSs are average plots centered around annotated TSSs.
The current yeast genome annotation does not contain any information on 5' or 3' UTRs,
thus the average plot is centered on annotated start codons.
Because of this one would expect the average plot to be slightly upstream of the start codon center point.
Most other organisms have UTRs in their genome annotation,
with the UTR length being the furthest TSS detected from the start codon.
This would then result in average plots that are expected to be centered and slightly downstream from the annotated TSS center.

```
p <- plot_average(exp, data_type = "tss", threshold = 3, ncol = 3) +
        ggplot2::theme(text = element_text(size = 4))

ggsave("tss_average_plot.png", plot = p, device = "png", type = "cairo", height = 1, width = 2)
```

![tss_average_plot](../inst/images/tss_average_plot.png)

### Heatmaps

While an average plot may give a general overview of TSSs relative to annotated start codons or TSSs,
it may sometimes be appropriate to generate a heatmap with TSS positions for all features displayed.
Due to TSSs being single points and sometimes sparsely distributed, it may be hard to them on a heatmap.
This option is provided regardless.

```
count_matrix <- tss_heatmap_matrix(exp, threshold = 3, upstream = 250, downstream = 250)

p <- plot_heatmap(count_matrix, ncol = 3, background_color = "white") +
	ggplot2::theme(text = element_text(size = 4), legend.key.size = unit(0.3, "cm"))

ggsave("tss_heatmap.png", plot = p, device = "png", type = "cairo", height = 2, width = 4)
```

![tss_heatmap](../inst/images/tss_heatmap.png)

## Sequence Analysis

TSSs tend to occur in certain sequence contexts, and this context can vary between species.
Knowing this bias can give mechanistic and biologically relevant information on promoter structure.

### TSS Sequence Logo

Generating sequence logos around TSSs is a good preliminary step to better understand the sequence context of TSSs.
For example, in *S. cerevisiae* it has been previously published that there is a pyrimidine-purine bias in the -1 and +1 positions respectively.
Furthermore, stronger TSSs tend to have a well position adenine in the -8 position, the loss of which diminishes promoter strength.

First, the sequences centered around TSSs will be retrieved using a 'FASTA' genome assembly or'BSgenome' object.
This example uses he Ensembl R64-1-1 Release 99 assembly FASTA.

```
assembly <- system.file("extdata", "S288C_Assembly.fasta", package = "tsrexplorer")

seqs <- tss_sequences(exp, genome_assembly = assembly, threshold = 3)
```

After the sequences are retrieved, the sequence logos can be generated.

```
p <- plot_sequence_logo(seqs, ncol = 3)

png("tss_seq_logo.png", units = "in", res = 300, height = 1, width = 6, type = "cairo")
p
dev.off()
```

![tss_sequence_logo](../inst/images/tss_seq_logo.png)

## Sequence Color Map

A sequence logo "averages" the bases when displaying data, but it can be useful for a more raw visualization.
Sequence color maps will assign a color to each base, and then display the corresponding colors centered around TSSs.
The prevalence of colors in certain positions can give further evidence towards putative sequence contexts.
The same genome assembly and retrieved sequences that were used to make the sequence logos above will be used here.

```
p <- plot_sequence_colormap(seqs, ncol = 3) +
	ggplot2::theme(text = element_text(size = 4), legend.key.size = unit(0.3, "cm"))

ggsave("tss_seq_colormap.png", plot = p, device = "png", type = "cairo", height = 2, width = 4)
```

![tss_sequence_colormap](../inst/images/tss_seq_colormap.png)