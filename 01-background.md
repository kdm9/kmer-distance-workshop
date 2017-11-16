# Genetic Distances from Reads

Next-gen sequencing has revolutionised the way we investigate (phylo)genetic relationships. Using traditional techniques, much effort and many resources are required to take NGS data and estimate the relationships between samples. Recent computational advances have allowed researchers to estimate these relationships directly from NGS data.

NGS can be considered a sampling process over the underlying genomes of your samples. To the extent that this sampling process is uniform and unbiased, distances between read sets for a set of samples estimates the distances between underlying genomes.

As with all distance-based measures, these methods determine the genetic distance between samples *as they are today*. These methods do not attempt to reconstruct the evolutionary history which these samples may have taken. The fact you can create a dendrogram does not mean you're creating a phylogeny (though like other distance-based measures, for recently diverged samples the difference is normally minimal).

Importantly, the distances estimated are an average across the genome (or the assayed portion of thereof for reduced representation methods). No inference of local ancestry can be made, and even relatively major changes in restricted portions of the genome can be "averaged away" if the remainder of the genome is unchanged. Technically, distances are averaged across the *hologenome*, a fancy name for "all the DNA you stuck in the tube". Any contaminants, endophytes, sludge, goop, or human hair that made it in will be treated as though they're all part of your sample's genome.


# Tools

## kWIP

kWIP, the $k$-mer weighted inner product, uses a concise representation of kmer counts to record samples, and computes a weighted euclidean distance over these counts. Not all kmers convey the same amount of information when determining the distance between some set of samples. The weighting kWIP applies attempts to reduce the contribution of these kmers to the overall signal between samples.

## Mash

Mash uses a very smart subsampling data structure to estimate the proportion of shared kmers between samples across a random subset of all kmers. It then derives a distance between samples (pairwise mean substitutions per site) from this proportion.

# How?

## K-mers

Most tools which create distances between sets of NGS reads do so by decomposing these reads into $k$-mers. K-mers are short, overlapping sub-sequences of a sequence. Think of each k-mer as a word (k-mer) in some sentence (a sequence, perhaps a gene or an NGS read). $k$ here is a length in bases, normally in the range 19-23 for our purposes, so we're talking about overlapping sub-sequences of roughly 20 bases.

(Figure on decomposing seqs to k-mers)


## Sketching

In computer science, a sketches are a class of data structures which efficiently store a large dataset inexactly. kWIP operates on k-mer counts. It uses an efficient, constant-sized data structure[1] to record counts, with a small chance that the counts of two k-mers is combined. Mash operates on the presence or absence of k-mers. Mash uses a sketching data structure which stores a reproducible sub-set of all k-mers[2].

[1]: kWIP's data structure is called a Count-min Sketch, or a Counting Bloom Filter
[2]: Mash's data strucutre is a Min-hash, a.k.a a bottom sketch


## Distances

### kWIP

kWIP's distance is a weighted euclidean distance between k-mer counts. The weighting applied attempts to reduce the effect of k-mers whose signal to noise ratio is low, specifically those with very low or high frequency across samples. Technically, the weighting uses Shannon's informational entropy, which measures the information content of a k-mer.

![**Shannon Entropy:** Here we plot Shannon's entropy, $H(x)$, across the range of k-mer frequencies. We define k-mer frequency as the proportion of samples in which the k-mer was seen at least once.](img/shannon-entropy.png)

For several reasons, kWIP's distances are arbitrary and relative. That is to say, a distance of 1.02 between two samples does not necessarily translate to the same true genetic distance across two kWIP runs with different samples. This is for two main reasons. kWIP's weighting will change with k-mer frequencies when the set of samples being analysed changes, which alters distances. Similarly, sample distances are normalised such that all self-distances are zero, which will affect all pairwise distances.

For well designed experiments, this has little practical effect. Regardless of the technology used, a hierarchical experimental design should be used. That is to say, always include several levels of out-group and replicate beyond the level at which your true question resides. If you're interested in population-level divergence, deliberately include outlier populations and out-group (sub-)species, as well as true biological (e.g. seeds off same mother) and technical (e.g. same plant) replicates. Only using designs like this is it possible to place your samples within a range of known divergences.

### Mash

Mash's distance estimates pairwise substitutions per site from the proportion of shared k-mers between samples as a total of all k-mers. Mash uses a very nifty data structure to subset the data, on the assumption that if one grabs 10000 k-mers from each sample, the distances between samples within each sample's subset of k-mers approximates the true distance between samples with known error bounds. More information on Mash's distance can be found [on their tutorial website](https://mash.readthedocs.io/en/latest/distances.html).

![**Mash's algorithm:** (quoting Mash's paper) *Overview of the MinHash bottom sketch strategy for estimating the Jaccard index. First, the sequences of two datasets are decomposed into their constituent k-mers (top, blue and red) and each k-mer is passed through a hash function h to obtain a 32- or 64-bit hash, depending on the input k-mer size. The resulting hash sets, A and B, contain |A| and |B| distinct hashes each (small circles). The Jaccard index is simply the fraction of shared hashes (purple) out of all distinct hashes in A and B. This can be approximated by considering a much smaller random sample from the union of A and B. MinHash sketches S(A) and S(B) of size s = 5 are shown for A and B, comprising the five smallest hash values for each (filled circles). Merging S(A) and S(B) to recover the five smallest hash values overall for A∪B (crossed circles) yields S(A∪B). Because S(A∪B) is a random sample of A∪B, the fraction of elements in S(A∪B) that are shared by both S(A) and S(B) is an unbiased estimate of J(A,B)*](img/mash-fig1.gif)
