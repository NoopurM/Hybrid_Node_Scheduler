/*
 * Noopur Maheshwari : 111464061
 * Rahul Rane : 111465246
 */
#include <chrono>
#include "mm_rec.h"
pthread_mutex_t lock;
extern vector<pthread_t> cpu_workers;
extern vector<pthread_t> gpu_workers;

/*
 * For tasks to be running on CPU - 0
 * for tasks to be running on GPU - 1
 * for tasks to be running on CPU/GPU - 2
 */
#define RUN_FLAG 0
int m=8;

int x[N][N];
int y[N][N];
int z[N][N];

bool completed=false;

void populate_matrix(int a[N][N]) {
    for(int i=0;i<N;i++) {
        for(int j=0; j<N;j++) {
            a[i][j] = 3;
        }
    }
}

void print_matrix(int a[N][N]) {
    cout<<"Matrix :"<<endl;
    for(int i=0;i<N;i++) {
        for(int j=0; j<N;j++) {
            cout<<a[i][j]<<" ";
        }
        cout<<"\n";
    }
}

void cpu_serial_mm(int r_z, int c_z, int x[N][N], int r_x, int c_x, int y[N][N],
int r_y, int c_y, int z1[N][N], int m, int *sync_cnt) {
    cout<<"Executing mm on CPU"<<endl;
    for(int i=r_x, u=r_z; i<r_x+m; i++,u++) {
        for(int k=c_x; k<c_x+m; k++) {
            for(int j=c_y,v=c_z ; j<c_y+m; j++,v++) {
                z[u][v] = z[u][v] + x[i][k] * y[k][j];           
            }
        }
    }
    dec_shared_var_value(sync_cnt);
}

CUDA_KERNEL void __gpu_serial_mm__(int *r_z, int *c_z, int *x, int *r_x, int *c_x, int *y, int *r_y, int *c_y, int *dev_z, int *m) {

    for(int i=*r_x, u=*r_z; i<(*r_x+*m); i++,u++) {
        for(int k=*c_x; k<(*c_x+*m); k++) {
            for(int j=*c_y,v=*c_z ; j<(*c_y+*m); j++,v++) {	
                 dev_z[u * N + v] = dev_z[u * N + v] + x[i * N + k] * y[k * N + j]; 
            }
        }
    }
}

void input(int a[N][N], int *h_a) {
	for(int i=0; i<N; i++) {
		for(int j=0; j<N; j++) {
			h_a[i * N + j] = a[i][j];			
		}
	}
}

void output(int *h_a) {
        for(int i=0; i<N; i++) {
                for(int j=0; j<N; j++) {
                        z[i][j] = h_a[i * N + j];
                }
        }
}

void gpu_serial_mm(int r_z, int c_z, int x[N][N], int r_x, int c_x, int y[N][N],
int r_y, int c_y, int z[N][N], int m, int *sync_cnt) {
    cout<<"Executing mm on GPU"<<endl;
    int *dev_r_z, *dev_c_z, *dev_r_x, *dev_c_x, *dev_r_y, *dev_c_y, *dev_m;
	int *dev_x, *dev_y, *dev_z;
	int *h_x, *h_y, *h_z;

	cudaMallocHost((void **) &h_x, N*N*sizeof(int));
	cudaMallocHost((void **) &h_y, N*N*sizeof(int));
	cudaMallocHost((void **) &h_z, N*N*sizeof(int));
	input(x, h_x);
	input(y, h_y);
	input(z, h_z);

	cudaMalloc( (void**)&dev_r_z, sizeof(int) );
	cudaMalloc( (void**)&dev_c_z, sizeof(int) );
	cudaMalloc( (void**)&dev_r_x, sizeof(int) );
	cudaMalloc( (void**)&dev_c_x, sizeof(int) );
	cudaMalloc( (void**)&dev_r_y, sizeof(int) );
	cudaMalloc( (void**)&dev_c_y, sizeof(int) );
	cudaMalloc( (void **)&dev_x, N*N*sizeof(int));
	cudaMalloc( (void **)&dev_y, N*N*sizeof(int));
	cudaMalloc( (void **)&dev_z, N*N*sizeof(int));
	cudaMalloc( (void**)&dev_m, sizeof(int) );

	cudaMemcpy( dev_r_z, &r_z,sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_c_z, &c_z,sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_r_x, &r_x,sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_c_x, &c_x,sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_r_y, &r_y,sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_c_y, &c_y,sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_m, &m,sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_x, h_x, N*N*sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_y, h_y, N*N*sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy( dev_z, h_z, N*N*sizeof(int),cudaMemcpyHostToDevice);	

	launch_kernel(__gpu_serial_mm__, dev_r_z, dev_c_z, dev_x, dev_r_x, dev_c_x, dev_y, dev_r_y, dev_c_y, dev_z, dev_m);	

	cudaMemcpy( h_z, dev_z,N*N*sizeof(int),cudaMemcpyDeviceToHost);
	output(h_z);
	cudaFree(dev_r_z); cudaFree(dev_c_z); cudaFree(dev_r_x); cudaFree(dev_c_x); cudaFree(dev_r_y); cudaFree(dev_c_y);
	cudaFree(dev_x); cudaFree(dev_y); cudaFree(dev_z); cudaFree(dev_m);
    dec_shared_var_value(sync_cnt);
} 

void parallel_rec_mm(int r_z, int c_z, int x[N][N], int r_x, int c_x, int y[N][N], int r_y, int c_y, int n, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
    int local_rp, local_sync_cnt;
    pthread_t tid = pthread_self();
    if (n == m) {
	local_rp = get_shared_var_value(rp);
        if (local_rp != 3) {        
	        set_shared_var_value(rp, 3);
	        set_shared_var_value(child_sync_cnt, 1);
            run_task(RUN_FLAG, cpu_serial_mm, gpu_serial_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, z, m, child_sync_cnt);
            submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
            return;
        }
        
	local_rp = get_shared_var_value(rp);
        if (local_rp == 3) {
	    local_sync_cnt = get_shared_var_value(child_sync_cnt);
            if (local_sync_cnt > 0) {
                submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
                return;        
            }
        }
	dec_shared_var_value(parent_sync_cnt);
    } else {
	local_rp = get_shared_var_value(rp);
        if (local_rp == 0) {
            int *new_child_sync_cnt1 = new int(4);
            int *child_rp1 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n/2, child_sync_cnt, new_child_sync_cnt1, child_rp1);
            int *new_child_sync_cnt2 = new int(4);
            int *child_rp2 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z, c_z+n/2, x, r_x, c_x, y, r_y, c_y+n/2, n/2, child_sync_cnt, new_child_sync_cnt2, child_rp2);
            
            int *new_child_sync_cnt3 = new int(4);
            int *child_rp3 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z+n/2, c_z, x, r_x+n/2, c_x, y, r_y, c_y, n/2, child_sync_cnt, new_child_sync_cnt3, child_rp3);
            
            int *new_child_sync_cnt4 = new int(4);
            int *child_rp4 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z+n/2, c_z+n/2, x, r_x+n/2, c_x, y, r_y, c_y+n/2, n/2, child_sync_cnt, new_child_sync_cnt4, child_rp4);
            
	    local_sync_cnt = get_shared_var_value(child_sync_cnt);	
            if (local_sync_cnt > 0) {
		set_shared_var_value(rp, 1);	
                submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
                return;
            }
        }
	    
	local_rp = get_shared_var_value(rp);
        if (local_rp == 1) {
	    local_sync_cnt = get_shared_var_value(child_sync_cnt);	
            if (local_sync_cnt > 0) {
		set_shared_var_value(rp, 1);
                submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
                return;
            }
        }
        
	local_rp = get_shared_var_value(rp);
        if (local_rp != 2) {
	    set_shared_var_value(child_sync_cnt, 4);
            int *new_child_sync_cnt5 = new int(4);
            int *child_rp5 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x+n/2, y, r_y+n/2, c_y, n/2, child_sync_cnt, new_child_sync_cnt5, child_rp5);
            
            int *new_child_sync_cnt6 = new int(4);
            int *child_rp6 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z, c_z+n/2, x, r_x, c_x+n/2, y, r_y+n/2, c_y+n/2, n/2, child_sync_cnt, new_child_sync_cnt6, child_rp6);
            
            int *new_child_sync_cnt7 = new int(4);
            int *child_rp7 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z+n/2, c_z, x, r_x+n/2, c_x+n/2, y, r_y+n/2, c_y, n/2, child_sync_cnt, new_child_sync_cnt7, child_rp7);
            
            int *new_child_sync_cnt8 = new int(4);
            int *child_rp8 = new int(0);
            submit_task(tid, parallel_rec_mm, r_z+n/2, c_z+n/2, x, r_x+n/2, c_x+n/2, y, r_y+n/2, c_y+n/2, n/2, child_sync_cnt, new_child_sync_cnt8, child_rp8);
        } 
	    
	local_sync_cnt = get_shared_var_value(child_sync_cnt);
        if (local_sync_cnt > 0) {
            *rp = 2;
	    set_shared_var_value(rp, 2);		
            submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
            return;
        } else {
	    dec_shared_var_value(parent_sync_cnt);
            if (n == N) {
                completed = true;
            }
        }
    }
}
int main(int argc, char *argv[]) {
    populate_matrix(x);
    populate_matrix(y);
    populate_matrix(x);
    print_matrix(x);
    print_matrix(y);
    
    create_threadpool(4);
    int *parent_sync_cnt = new int(1);
    int *rp = new int(0);
    int *child_sync_cnt = new int(4);
    chrono::time_point<std::chrono::system_clock> start, end;
    start = chrono::system_clock::now();
 
    submit_task(cpu_workers[0], parallel_rec_mm, 0, 0, x, 0, 0, y, 0, 0, N, parent_sync_cnt, child_sync_cnt, rp);
    
    wait_until_done();
    end = chrono::system_clock::now();
    chrono::duration<double> elapsed_seconds = end - start;
    print_matrix(z);
    cout<<"Run flag :"<<RUN_FLAG<<endl;
    cout<<"N :"<<N<<endl;
    cout<<"Job time = "<<elapsed_seconds.count()<<"seconds"<<endl;
 return 0;
}

