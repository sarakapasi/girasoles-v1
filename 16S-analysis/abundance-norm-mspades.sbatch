#!/bin/bash
#SBATCH -J abundance
#SBATCH -A gts-ktk3-coda20
#SBATCH -n 4
#SBATCH --mem=64GB
#SBATCH -t 24:00:00
#SBATCH -q inferno
#SBATCH --array=0-45%20
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/log/0302_abundancenorm_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/log/0302_abundancenorm_err.16

#!/bin/bash

source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
conda activate binning_env
cd /storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/1_rawdata/cleaned_MAG_files/

PARENT_DIR="/storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/1_rawdata/cleaned_MAG_files/"

# Get sample ID and directory for this array index from the sample file
SAMPLE_ID=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" sample_list_updated.txt)
SAMPLE_DIR="${PARENT_DIR}/${SAMPLE_ID}"

echo "Processing: $SAMPLE_DIR"

if [[ ! -d "$SAMPLE_DIR" ]]; then
    echo "ERROR: Sample directory not found: $SAMPLE_DIR"
    exit 1
fi

# Find the assembly output directory (I used NORMALIZED metaspades)
SPADES_DIR=$(find "$SAMPLE_DIR" -maxdepth 1 -type d -name "norm_metaspades" | head -n 1)

if [[ -z "$SPADES_DIR" ]]; then
    echo "No normalized metaspades directory found in $SAMPLE_DIR, skipping."
    exit 0
fi

# Check for contigs.fasta
CONTIGS="${SPADES_DIR}/contigs.fasta"
if [[ ! -f "$CONTIGS" ]]; then
    echo "  contigs.fasta not found in $SPADES_DIR, skipping."
    exit 0
fi

# Find paired-end reads
R1=$(find "$SAMPLE_DIR" -type f -name "R1_norm.fq.gz" | head -n 1)
R2=$(find "$SAMPLE_DIR" -type f -name "R2_norm.fq.gz" | head -n 1)

if [[ -z "$R1" || -z "$R2" ]]; then
    echo "  Missing read files in $SAMPLE_DIR, skipping."
    exit 0
fi

# Prepare analysis directory
ANALYSIS_DIR="${SAMPLE_DIR}/metaspades_norm_abundance"
mkdir -p "$ANALYSIS_DIR"
cd "$ANALYSIS_DIR" || exit 0

# Run analysis tools to make abundance files 
echo "  Building Bowtie2 index..."
bowtie2-build "$CONTIGS" bowtie_contigs.fasta

echo "  Aligning reads to contigs..."
bowtie2 -p 16 -x bowtie_contigs.fasta -1 "$R1" -2 "$R2" -S contigs_vs_reads.sam

echo "  Converting and sorting SAM/BAM..."
samtools view -S --threads 10 -b contigs_vs_reads.sam > contigs_vs_reads.bam
samtools sort contigs_vs_reads.bam -o contigs_vs_reads.sorted.bam

echo "  Generating depth file..."
jgi_summarize_bam_contig_depths --outputDepth coverage_for_metabat.txt contigs_vs_reads.sorted.bam
cut -f1,3 coverage_for_metabat.txt | sed '1d' > coverage_for_maxbin.txt

echo "Done with $SAMPLE_DIR"
