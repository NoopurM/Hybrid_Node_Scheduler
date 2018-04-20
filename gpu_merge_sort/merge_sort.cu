#include <iostream>
#include <cmath>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>
#include "merge_sort.h"
#include <vector>
#include <map>
#include <queue>
#include <functional>
using namespace std;

extern map<pthread_t, deque<function<void()>>> que_map;
pthread_mutex_t sync_cnt_lock;
extern vector<pthread_t> workers;

bool completed=false;
//int arr[10] = {23,12,11,33,2,1,4,22,12,10};
int arr[15] = {15,14,13,12,11,10,9,8,7,6,5,4,3,2,1};

template < typename PTHREADID, typename CALLABLE, typename... ARGS >
void submit_task(PTHREADID tid, CALLABLE fn, ARGS&&... args ) { 
    //cout<<"Submitting task to "<<tid<<" queue"<<endl; 
    que_map[tid].push_back( bind( fn, args... ) ) ; 
}

//void merge(int *arr, int p, int q, int r) {
void merge(int p, int q, int r) {
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
//void parallel_merge_sort(int *arr, int p, int r, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
void parallel_merge_sort(int p, int r, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
	pthread_t tid = pthread_self();
    cout<<"parallel merge sort called :"<<p<<" "<<r<<endl;
    if (p < r) {
		int q = floor((p+r)/2);
		pthread_mutex_lock(&sync_cnt_lock);
        if (*rp == 0) {
            pthread_mutex_unlock(&sync_cnt_lock);
            //int *new_child_sync_cnt1 = new int(2);
            int *new_child_sync_cnt1;
	    cudaMallocManaged(&new_child_sync_cnt1, sizeof(int));
	    *new_child_sync_cnt1 = 2;

            //int *child_rp1 = new int(0);
	    int *child_rp1;
	    cudaMallocManaged(&child_rp1, sizeof(int));
	    *child_rp1 = 0;
            //submit_task(tid, parallel_merge_sort, arr, p, q, child_sync_cnt, new_child_sync_cnt1, child_rp1);
            submit_task(tid, parallel_merge_sort, p, q, child_sync_cnt, new_child_sync_cnt1, child_rp1);
            //cilk_spawn parallel_merge_sort(arr, p, q);
		    
            //int *new_child_sync_cnt2 = new int(2);
	    int *new_child_sync_cnt2;
            cudaMallocManaged(&new_child_sync_cnt2, sizeof(int));
            *new_child_sync_cnt2 = 2;

            //int *child_rp2 = new int(0);
	    int *child_rp2;
            cudaMallocManaged(&child_rp2, sizeof(int));
            *child_rp2 = 0; 

            //submit_task(tid, parallel_merge_sort, arr, q+1, r, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            submit_task(tid, parallel_merge_sort, q+1, r, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            //parallel_merge_sort(arr, q+1, r);
		    //cilk_sync;
            
            pthread_mutex_lock(&sync_cnt_lock);
            if (*(child_sync_cnt) > 0) {
                *rp = 1;
                //submit_task(tid, parallel_merge_sort, arr, p, r, parent_sync_cnt, child_sync_cnt, rp);
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
                //submit_task(tid, parallel_merge_sort, arr, p, r, parent_sync_cnt, child_sync_cnt, rp);
                submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
	            pthread_mutex_unlock(&sync_cnt_lock);
                return;
            }
	        pthread_mutex_unlock(&sync_cnt_lock);
        } else {
	        pthread_mutex_unlock(&sync_cnt_lock);
        }

		//merge(arr, p, q, r);
		merge(p, q, r);
        pthread_mutex_lock(&sync_cnt_lock);
		(*parent_sync_cnt)--;
	    cout<<"second half completed :"<<r-p<<endl;
        pthread_mutex_unlock(&sync_cnt_lock);
        if ((r-p) == 14) {
            completed = true;
        }
	} else {
        pthread_mutex_lock(&sync_cnt_lock);
        (*parent_sync_cnt)--;
	    pthread_mutex_unlock(&sync_cnt_lock);
    }
}
int main() {
	//int arr[10] = {23,12,11,33,2,1,4,22,12,10};
	//parallel_merge_sort(arr, 0, 9);
	create_threadpool(4);
	//int *parent_sync_cnt = new int(2);
	int *parent_sync_cnt;
	cudaMallocManaged(&parent_sync_cnt, sizeof(int));
	*parent_sync_cnt = 2;	

    	//int *rp = new int(0);
	int *rp;
	cudaMallocManaged(&rp, sizeof(int));
	*rp = 0;		

    	//int *child_sync_cnt = new int(2);
	int *child_sync_cnt;
	cudaMallocManaged(&child_sync_cnt, sizeof(int));
	*child_sync_cnt = 2;
 
    //submit_task(workers[0], parallel_merge_sort, arr, 0, 9, parent_sync_cnt, child_sync_cnt, rp);
    submit_task(workers[0], parallel_merge_sort, 0, 14, parent_sync_cnt, child_sync_cnt, rp);
    
    wait_until_done();
    
    for (int i=0;i<15;i++) {
		cout<<arr[i]<<" ";
	}
}
