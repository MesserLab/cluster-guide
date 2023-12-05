#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --mem=1000
#SBATCH --partition=short
#SBATCH --job-name=TADS-JOB
#SBATCH --output=TADS-JOB-OUTPUT.txt
#SBATCH --array=1-30%10

# Create and move to a temporary working directory for this job
WORKDIR=/workdir/$USER/$SLURM_JOB_ID
mkdir -p $WORKDIR
cd $WORKDIR

# Copy all files the job needs to this working directory
BASE_DIR=/home/ikk23/slim-p-increase
cp $BASE_DIR/slim-files/distant_site_pan_TA.slim .
cp $BASE_DIR/python-files/slimutil.py .
cp $BASE_DIR/python-files/python-driver.py .
cp $BASE_DIR/text-files/params.txt .

# Add SLiM4 to your path
export PATH=/programs/SLiM-4.0.1/bin:$PATH

# This sed command grabs line SLURM_ARRAY_TASK_ID of the text file
prog=`sed -n "${SLURM_ARRAY_TASK_ID}p" params.txt` 

# Run this command and pipe to a output file
$prog > ${SLURM_ARRAY_TASK_ID}.csv 

# Move your output back to your home directory
cp ${SLURM_ARRAY_TASK_ID}.csv $BASE_DIR/raw-output/ 

# Clean up the working directory - remove everything
rm -r $WORKDIR