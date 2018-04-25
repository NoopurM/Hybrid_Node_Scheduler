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
//int arr[15];
int *arr;

//void merge(int *arr, int p, int q, int r) {
void merge(int *arr, int *p, int *q, int *r) {
	int left_n = *q-*p+1;
    int right_n = *r-*q;
    //int left[left_n], right[right_n];
	int *left = new int[left_n];
    int *right = new int[right_n];
    int i,j,k;
	for(i=0;i<*q-*p+1;i++) {
		left[i] = arr[i+*p];
	}
	for(i=0;i<*r-*q;i++) {
		right[i] = arr[i+*q+1];
	}
	for(k=*p,i=0,j=0;i<(*q-*p+1) && j<(*r-*q);) {
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
	while(i<(*q-*p+1)) {
		arr[k] = left[i];
		k++;
		i++;
	}
	while(j<(*r-*q)) {
		arr[k] = right[j];
		k++;
		j++;
	}
    delete[] left;
    delete[] right;
}
//void parallel_merge_sort(int *arr, int p, int r, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
void parallel_merge_sort(int *p, int *r, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
	pthread_t tid = pthread_self();
    cout<<"parallel merge sort called :"<<*p<<" "<<*r<<endl;
    if (*p < *r) {
        int *q;
        cudaMallocManaged((void **)&q, sizeof(int));
		*q = floor((*p+*r)/2);
        
		//int q = floor((p+r)/2);
		pthread_mutex_lock(&sync_cnt_lock);
        if (*rp == 0) {
            pthread_mutex_unlock(&sync_cnt_lock);
            int *new_child_sync_cnt1, *child_rp1;
	        cudaMallocManaged((void **)&new_child_sync_cnt1, sizeof(int));
	        cudaMallocManaged((void **)&child_rp1, sizeof(int));
	        
            *new_child_sync_cnt1 = 2;
	        *child_rp1 = 0;
            //submit_task(tid, parallel_merge_sort, p, q, child_sync_cnt, new_child_sync_cnt1, child_rp1);
            submit_task(tid, parallel_merge_sort, p, q, child_sync_cnt, new_child_sync_cnt1, child_rp1);
            //launch_kernel(parallel_merge_sort, p, q, child_sync_cnt, new_child_sync_cnt1, child_rp1);
 
	        int *new_child_sync_cnt2, *child_rp2;
            cudaMallocManaged((void **)&new_child_sync_cnt2, sizeof(int));
            cudaMallocManaged((void **)&child_rp2, sizeof(int));
            *new_child_sync_cnt2 = 2;
            *child_rp2 = 0; 
            //submit_task(tid, parallel_merge_sort, q+1, r, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            int *q1;
            cudaMallocManaged((void **)&q1, sizeof(int));
            *q1 = *q+1;
            submit_task(tid, parallel_merge_sort, q1, r, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            //launch_kernel(parallel_merge_sort, q+1, r, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            
            pthread_mutex_lock(&sync_cnt_lock);
            if (*(child_sync_cnt) > 0) {
                *rp = 1;
                submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
                //launch_kernel(parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
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
                //launch_kernel(parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
	            pthread_mutex_unlock(&sync_cnt_lock);
                return;
            }
	        pthread_mutex_unlock(&sync_cnt_lock);
        } else {
	        pthread_mutex_unlock(&sync_cnt_lock);
        }

		launch_kernel(merge, arr, p, q, r);
        pthread_mutex_lock(&sync_cnt_lock);
		(*parent_sync_cnt)--;
	    cout<<"second half completed :"<<*r-*p<<endl;
        pthread_mutex_unlock(&sync_cnt_lock);
        if ((*r-*p) == 14) {
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
    cudaMallocManaged((void **)&arr, 25*sizeof(int));
    //cudaMalloc((void **)&d_arr, N*sizeof(int));
    for(int i=14;i>=0;i--) {
        //cudaMallocManaged(&arr[i], sizeof(int));
	    arr[i] = i+1;
    }

    for(int i=0;i<15;i++) {
        cout<<"arr :"<<arr[i]<<endl;
    }
	int *parent_sync_cnt, *child_sync_cnt, *rp;
	cudaMallocManaged((void **)&parent_sync_cnt, sizeof(int));
	cudaMallocManaged((void **)&rp, sizeof(int));
	cudaMallocManaged((void **)&child_sync_cnt, sizeof(int));
	*parent_sync_cnt = 2;	
	*rp = 0;		
	*child_sync_cnt = 2;
 
    int *p, *r;
    cudaMallocManaged((void **)&p, sizeof(int));
    cudaMallocManaged((void **)&r, sizeof(int));
    *p = 0;
    *r = 14;
    submit_task(workers[0], parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
    
    wait_until_done();
    
    for (int i=0;i<15;i++) {
		cout<<arr[i]<<" ";
	}
}
