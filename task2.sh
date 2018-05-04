#!/bin/sh
#SBATCH --mail-user=rrane@cs.stonybrook.edu
#SBATCH --mail-type=begin  # email me when the job starts
#SBATCH --mail-type=end    # email me when the job finishes
#SBATCH --partition=gpu # Partition to submit to
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=24
#SBATCH --export=ALL
#SBATCH -t 00:03:00
./steal_cuda
