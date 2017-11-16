# Practical use of kWIP and Mash

Throughout this notebook, I'll give a command for a single sample. This is, a), to avoid overloading the server, and b), because you'll need to generalise this to all your samples however you see fit. Personally, I use and recommend [snakemake](https://snakemake.readthedocs.io/en/stable/) for such purposes. In fact, I have supplied a Snakemake workflow to complete the entire analysis.

# Preparing reads

Both kWIP and Mash operate directly on sequencing reads. Therefore, reads ought be as free from error and contamination as possible. To this end, it is worth using something like [AdapterRemoval](https://github.com/MikkelSchubert/adapterremoval) to remove adaptor sequences, trim away low quality bases and merge overlapping reads.


```bash
SAMPLE=ERR626208

AdapterRemoval                                \
    --file1 data/reads/raw/${SAMPLE}.fastq.gz \
    --output1 mydata/${SAMPLE}_qc.fastq.gz    \
    --combined-output                         \
    --interleaved-output                      \
    --trimns                                  \
    --trimqualities                           \
    --trimwindows 10                          \
    --minquality 20                           \
    --settings /dev/null                      \
    --gzip
```

# kWIP analysis

There are two steps to analysis with kWIP: count kmers in reads, then compute distances between samples. kWIP itself only performs the latter task. We use `khmer`'s `load-into-counting.py` to count kmers.


## $k$-mer counting

The following counts every 21-mer (see `--ksize`) in the sample into one per-sample sketch (the `.ct.gz` file). Our sketch will have one table (`--n_tables`) and be about 200 million bins in size (`--max-tablesize`). We disable counting very abundant kmers, as this cannot be used by kWIP and just wastes RAM (`--no-bigcount`). A bunch of summary statistics are also created (`--summary-info` enables this). 

```bash
load-into-counting.py            \
    --force                      \
    --ksize 21                   \
    --no-bigcount                \
    --n_tables 1                 \
    --max-tablesize 2e8          \
    --summary-info tsv           \
    mydata/${SAMPLE}.ct.gz       \
    mydata/${SAMPLE}_qc.fastq.gz
```

Note that, just like the above `AdapterRemoval` call, this will need to be repeated for each of your samples. If you're using the provided dataset, these have been done for you to reduce server load (see files under `data/counts`).

## kWIP distance calculation

And now, we'll use kWIP to compute its distance across our samples. This creates two matrices: the kernel and distance matrices. The kernel matrix is the raw similarities between all samples (including to themselves). The distance matrix is created from the kernel matrix by normalisation and conversion of similarities to distances.


```bash
kwip \
    -k mydata/kwip_kernel.tsv \
    -d mydata/kwip_distance.tsv \
    data/counts/*.ct.gz
```

Note that the above command uses the count sketches I have pre-prepared, not the one you made. You may add your count sketch is as well, if you wish. kWIP requires that all count sketches are of the same size, and count kmers of the same length (i.e. the `--ksize/-k`, `--n_tables/-N` and `--max-tablesize/-x` arguments to khmer must be the same for all samples).


# Mash analysis

Just like kWIP, mash has two steps: sketching and distance calculation. The `mash` command can perform both of these.

## Mash sketching

One uses the `mash sketch` sub-command to sketch many samples into a single sketch file (which contains one sketch per sample, but all concatenated into a single file). One should set a minimum abundance (`-m`) for k-mers to something around 1/10th of your anticipated coverage (luckily for us this is about 20x). The minimum distance mash can detect is $\frac{1}{\mathrm{sketchsize}}$, and the error bound is $\frac{1}{\sqrt{\mathrm{sketchsize}}}$. Therefore we ought increase the default sketch size of 1000 to some tens of thousands.

```bash
mash sketch \
    -s 20000 \
    -m 2 \
    -o mydata/mash_sketch.msh \
    data/reads/qc/*.fastq.gz
```

## Mash distances


```bash

mash dist 
    mydata/mash_sketch.msh \
    mydata/mash_sketch.msh \
    > mydata/mash_dist.tsv
```
