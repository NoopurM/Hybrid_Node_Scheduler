/*
 * Noopur Maheshwari : 111464061
 * Rahul Rane : 111465246
 */
#include <chrono>
#include "merge_sort.h"

pthread_mutex_t lock;
extern vector<pthread_t> cpu_workers;
extern vector<pthread_t> gpu_workers;

bool completed=false;
/*
 * For tasks to be running on CPU - 0
 * for tasks to be running on GPU - 1
 * for tasks to be running on CPU/GPU - 2
 */
#define RUN_FLAG 0
#define N 16

int arr[N];

__global__ void __gpu_merge__(int *d_arr, int *p, int *q, int *r) {
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

void cpu_merge(int p, int q, int r, int *sync_cnt) {
    cout<<"Executing merge on CPU"<<endl;
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
    dec_shared_var_value(sync_cnt);
}

void gpu_merge(int p, int q, int r, int *sync_cnt) {
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
    dec_shared_var_value(sync_cnt);
}

void parallel_merge_sort(int p, int r, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
	pthread_t tid = pthread_self();
    int local_sync_cnt, local_rp;
    if (p < r) {
        int q;
		q = floor((p+r)/2);
        
        local_rp = get_shared_var_value(rp);
        if (local_rp == 0) {
	        int *new_child_sync_cnt1 = new int(2);
            int *child_rp1 = new int(0);
            submit_task(tid, parallel_merge_sort, p, q, child_sync_cnt, new_child_sync_cnt1, child_rp1);
	        
            int *new_child_sync_cnt2 = new int(2);
            int *child_rp2 = new int(0);
            submit_task(tid, parallel_merge_sort, q+1, r, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            
            set_shared_var_value(rp, 1);
            submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
            return;
        }
	    
        local_rp = get_shared_var_value(rp);
        if (local_rp == 1) {
            local_sync_cnt = get_shared_var_value(child_sync_cnt);
            if (local_sync_cnt > 0) {
                set_shared_var_value(rp, 1);
                submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
                return;
            }
            set_shared_var_value(rp, 2);
        }

        local_rp = get_shared_var_value(rp);
        if (local_rp == 2) {
            set_shared_var_value(child_sync_cnt, 1);
            run_task(RUN_FLAG, cpu_merge, gpu_merge, p, q, r, child_sync_cnt);
            set_shared_var_value(rp, 3);
            submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
            return;
        }
        
        local_rp = get_shared_var_value(rp);
        if (local_rp == 3) {
            local_sync_cnt = get_shared_var_value(child_sync_cnt);
            if (local_sync_cnt > 0) {
                submit_task(tid, parallel_merge_sort, p, r, parent_sync_cnt, child_sync_cnt, rp);
                return;
            } 
	    }

        dec_shared_var_value(parent_sync_cnt);
        if ((r-p) == N-1) {
            completed = true;
        }
	} else {
        dec_shared_var_value(parent_sync_cnt);
        if ((r-p) == N-1) {
            completed = true;
        }
    }
}
int main() {
    create_threadpool(4);
    init_bayes();
    for(int i=N-1;i>=0;i--) {
	    arr[i] = rand()%N;
    }

    cout<<"Input array :"<<endl;
    for(int i=0;i<N;i++) {
        cout<<arr[i]<<" ";
    }
    cout<<endl;
	int *parent_sync_cnt = new int(2);
    int *rp = new int(0);
    int *child_sync_cnt = new int(2);
    
    chrono::time_point<std::chrono::system_clock> start, end;
    start = chrono::system_clock::now();
 
    submit_task(cpu_workers[0], parallel_merge_sort, 0, N-1, parent_sync_cnt, child_sync_cnt, rp);
    
    wait_until_done();
    
    end = chrono::system_clock::now();
    chrono::duration<double> elapsed_seconds = end - start;
    cout<<"Sorted array :"<<endl; 
    for (int i=0;i<N;i++) {
		cout<<arr[i]<<" ";
	}
    cout<<endl;
    cout<<"Run flag :"<<RUN_FLAG<<endl;
    cout<<"N :"<<N<<endl;
    cout<<"Job time = "<<elapsed_seconds.count()<<"seconds"<<endl;
}
