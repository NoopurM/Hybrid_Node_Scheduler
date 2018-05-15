Noopur Maheshwari - 111464061
Rahul Rane - 111465246

--------------------------------------------------------------------------------------------------------
IMPLEMENTATION:
Merge Sort:
fork-join implementation -  gpu_merge_sort/merge_sort.cu
                            gpu_merge_sort/merge_sort.h

Matrix Multiplication:
fork-join implementation -  gpu_mm/mm_rec.cu
                            gpu_mm/mm_rec.h

Scheduler:
Work stealing implementation -  gpu_merge_sort/scheduler.cu
                                gpu_merge_sort/scheduler.h
                                gpu_mm/scheduler.cu
                                gpu_mm/scheduler.h

Threadpool:
CPU and GPU worker implementation - gpu_merge_sort/threadpool.cu
                                    gpu_mm/threadpool.cu

Naive Bayes:
Bayes algo implementation - gpu_merge_sort/bayes.cu
                            gpu_merge_sort/bayes.h
                            gpu_merge_sort/training.data
                            gpu_mm/bayes.cu
                            gpu_mm/bayes.h
                            gpu_mm/training.data

--------------------------------------------------------------------------------------------------------
COMPILATION AND RUNNING:
We have provided Makefile in both folders which creates a single binary:

For ex.,
cd gpu_merge_sort
make
./merge_sort

All parameters are configurable and defined as macro in main files.
