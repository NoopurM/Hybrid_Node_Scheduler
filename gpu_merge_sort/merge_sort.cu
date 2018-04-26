#include <iostream>
#include <cmath>
#include "merge_sort.h"
#include <vector>
#include <map>
#include <queue>
#include <functional>
#include "scheduler.h"
using namespace std;

pthread_mutex_t sync_cnt_lock;
extern vector<pthread_t> workers;

bool completed=false;
#define N 15
int arr[N];

__global__ void __gpu_merge__(int *d_arr, int *p, int *q, int *r) {
	printf("########## %d %d %d", *p, *q, *r);
    int left_n = *q-*p+1;
    int right_n = *r-*q;
	int *left = new int[left_n];
    int *right = new int[right_n];
    int i,j,k;
	for(i=0;i<*q-*p+1;i++) {
		left[i] = d_arr[i+*p];
	}
	for(i=0;i<*r-*q;i++) {
		right[i] = d_arr[i+*q+1];
	}
	for(k=*p,i=0,j=0;i<(*q-*p+1) && j<(*r-*q);) {
		if (left[i] <= right[j]) {
			d_arr[k] = left[i];
			i++;
			k++;
		} else {
			d_arr[k] = right[j];
			j++;
			k++;
		}
	}
	while(i<(*q-*p+1)) {
		d_arr[k] = left[i];
		k++;
		i++;
	}
	while(j<(*r-*q)) {
		d_arr[k] = right[j];
		k++;
		j++;
	}
    delete[] left;
    delete[] right;
}

void cpu_merge(int p, int q, int r) {
    int left[q-p+1], right[r-q];
    int i,j,k;
	for(i=0;i<q-p+1;i++) {
		left[i] = arr[i+p];
	}
	for(i=0;i<r-q;i++) {
		right[i] = arr[i+q+1];
	}
	for(k=p,i=0,j=0;i<(q-p+1) && j<(r-q);) {
		if (left[i] <= right[j]) {
			arr[k] = left[i];
			i++;
			k++;
		} else {
			arr[k] = right[j];
			j++;
			k++;
		}
	}
	while(i<(q-p+1)) {
		arr[k] = left[i];
		k++;
		i++;
	}
	while(j<(r-q)) {
		arr[k] = right[j];
		k++;
		j++;
	}
}

void gpu_merge(int p, int q, int r) {
    int *d_p, *d_r, *d_q, *d_arr;
    cout<<"Executing merge on GPU"<<endl;
    cudaMalloc((void **)&d_p, sizeof(int));
    cudaMalloc((void **)&d_q, sizeof(int));
    cudaMalloc((void **)&d_r, sizeof(int));
    cudaMalloc((void **)&d_arr, N*sizeof(int));
    cudaMemcpy( d_p, &p, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy( d_q, &q, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy( d_r, &r, sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy( d_arr, arr, N * sizeof(int), cudaMemcpyHostToDevice);
    launch_kernel(__gpu_merge__, d_arr, d_p, d_q, d_r);
    cudaMemcpy(arr, d_arr, N * sizeof(int),cudaMemcpyDeviceToHost);
    cudaFree(d_p); cudaFree(d_q);cudaFree(d_r); cudaFree(d_arr); 
}

void parallel_merge_sort(int p, int r, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
	pthread_t tid = pthread_self();
    //cout<<"parallel merge sort called :"<<p<<" "<<r<<endl;
    if (p < r) {
        int q;
		q = floor((p+r)/2);
        
		pthread_mutex_lock(&sync_cnt_lock);
        if (*rp == 0) {
            pthread_mutex_unlock(&sync_cnt_lock);
	        int *new_child_sync_cnt1 = new int(2);
            int *child_rp1 = new int(0);
            submit_task(tid, parallel_merge_sort, p, q, child_sync_cnt, new_child_sync_cnt1, child_rp1);
	        
            int *new_child_sync_cnt2 = new int(2);
            int *child_rp2 = new int(0);
            submit_task(tid, parallel_merge_sort, q+1, r, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            
            pthread_mutex_lock(&sync_cnt_lock);
            if (*(child_sync_cnt) > 0) {
                *rp = 1;
                submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
	            pthread_mutex_unlock(&sync_cnt_lock);
                return;
            }
	        pthread_mutex_unlock(&sync_cnt_lock);
        } else {
            pthread_mutex_unlock(&sync_cnt_lock);
        }
	    
        pthread_mutex_lock(&sync_cnt_lock);
        if (*rp == 1) {
            if (*(child_sync_cnt) > 0) {
                *rp = 1;
                submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
	            pthread_mutex_unlock(&sync_cnt_lock);
                return;
            }
	        pthread_mutex_unlock(&sync_cnt_lock);
        } else {
	        pthread_mutex_unlock(&sync_cnt_lock);
        }

        //gpu_merge(p, q, r);
        //cpu_merge(p, q, r);
        run_task(0, cpu_merge, gpu_merge, p, q, r);
        pthread_mutex_lock(&sync_cnt_lock);
		(*parent_sync_cnt)--;
	    //cout<<"second half completed :"<<r-p<<endl;
        pthread_mutex_unlock(&sync_cnt_lock);
        if ((r-p) == N-1) {
            completed = true;
        }
	} else {
        pthread_mutex_lock(&sync_cnt_lock);
        (*parent_sync_cnt)--;
	    pthread_mutex_unlock(&sync_cnt_lock);
    }
}
int main() {
	create_threadpool(4);
    for(int i=N-1;i>=0;i--) {
	    arr[i] = rand()%15;
    }

    for(int i=0;i<N;i++) {
        cout<<"arr :"<<arr[i]<<endl;
    }
	int *parent_sync_cnt = new int(2);
    int *rp = new int(0);
    int *child_sync_cnt = new int(2);
 
    submit_task(workers[0], parallel_merge_sort, 0, N-1, parent_sync_cnt, child_sync_cnt, rp);
    
    wait_until_done();
    
    for (int i=0;i<N;i++) {
		cout<<arr[i]<<" ";
	}
}
