#!/bin/bash
#SBATCH -J drep-attempt-1
#SBATCH -A gts-ktk3-coda20
#SBATCH -n 8
#SBATCH --mem=100G
#SBATCH -t24:00:00
#SBATCH -q inferno
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=0-13%20
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/log/040926_drep1_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/log/040926_drep1_err.16

# Load conda/mamba environment
source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
cd /storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/1_rawdata/cleaned_MAG_files/
conda activate drep_env ## to be changed to whatever directory drep is in

# Set parent directory
PARENT_DIR="/storage/home/hcoda1/0/skapasi3/r-ktk3-0/HIAMI/1_rawdata/cleaned_MAG_files/"

# Get sample ID and directory for this array index from the sample file made
SAMPLE_ID=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" sample_list_updated.txt)
SAMPLE_DIR="${PARENT_DIR}/${SAMPLE_ID}"
COMPILED_BINS="${SAMPLE_DIR}/compiled_bins"
NORM_COMPILED_BINS="${SAMPLE_DIR}/norm_compiled_bins"

echo "Processing: $SAMPLE_DIR"

# First round of technical dereplication at 95% ANI for normalized and non-normalized bins

dRep dereplicate "${SAMPLE_DIR}/1_drep_output/" -g "${COMPILED_BINS}/*.fasta" --genomeInfo "${SAMPLE_DIR}/genome_info.csv" -comp 50 -con 10 -pa 0.9 -sa 0.95 -nc 0.30 -p 16

dRep dereplicate "${SAMPLE_DIR}/1_norm_drep_output/" -g "${NORM_COMPILED_BINS}/*.fasta" --genomeInfo "${SAMPLE_DIR}/norm_genome_info.csv" -comp 50 -con 10 -pa 0.9 -sa 0.95 -nc 0.30 -p 16
