#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=24
#SBATCH --export=ALL
#SBATCH -t 00:5:00
#SBATCH --gres=gpu:4
#SBATCH --mail-user=rrane@cs.stonybrook.edu
#SBATCH --mail-type=begin  # email me when the job starts
#SBATCH --mail-type=end    # email me when the job finishes
./a.out
