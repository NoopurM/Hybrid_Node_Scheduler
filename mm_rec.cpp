#include <iostream>
#include <vector>
#include <queue>
#include <functional>
#include <map>
#include <chrono>
//#include "queue1.h"
#include "mm_rec.h"
//#include <cilk/cilk_api.h>
using namespace std;

extern map<pthread_t, deque<function<void()>>> que_map;
pthread_mutex_t sync_cnt_lock;
extern vector<pthread_t> workers;

#define N 1024
int m=32;

int x[N][N];
int y[N][N];
int z[N][N];

bool completed=false;

template < typename PTHREADID, typename CALLABLE, typename... ARGS >
void submit_task(PTHREADID tid, CALLABLE fn, ARGS&&... args ) { 
    //cout<<"Submitting task to "<<tid<<" queue"<<endl; 
    que_map[tid].push_back( bind( fn, args... ) ) ; 
}

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

void serial_mm(int r_z, int c_z, int x[N][N], int r_x, int c_x, int y[N][N], int r_y, int c_y, int m) {
    for(int i=r_x, u=r_z; i<r_x+m; i++,u++) {
        for(int k=c_x; k<c_x+m; k++) {
            for(int j=c_y,v=c_z ; j<c_y+m; j++,v++) {
                z[u][v] = z[u][v] + x[i][k] * y[k][j];
            }
        }
    }
} 

void parallel_rec_mm(int r_z, int c_z, int x[N][N], int r_x, int c_x, int y[N][N], int r_y, int c_y, int n, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
    //cout<<"parallel_rec called :"<<n<<endl;
    pthread_t tid = pthread_self();
    if (n == m) {
        //z[r_z][c_z] = z[r_z][c_z] + x[r_x][c_x]*y[r_y][c_y];
        serial_mm(r_z, c_z, x, r_x, c_x, y, r_y, c_y, m);
	    pthread_mutex_lock(&sync_cnt_lock);
        (*parent_sync_cnt)--;
	    pthread_mutex_unlock(&sync_cnt_lock);
    } else {
	    pthread_mutex_lock(&sync_cnt_lock);
        if (*rp == 0) {
            pthread_mutex_unlock(&sync_cnt_lock);
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
            
	        pthread_mutex_lock(&sync_cnt_lock);
            if (*(child_sync_cnt) > 0) {
                *rp = 1;
                submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
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
                submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
	            pthread_mutex_unlock(&sync_cnt_lock);
                return;
            }
	        pthread_mutex_unlock(&sync_cnt_lock);
        } else {
	        pthread_mutex_unlock(&sync_cnt_lock);
        }
        
        pthread_mutex_lock(&sync_cnt_lock);
        if (*rp != 2) {
            *child_sync_cnt = 4;
	        pthread_mutex_unlock(&sync_cnt_lock);
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
        } else {
	        pthread_mutex_unlock(&sync_cnt_lock);
        }
	    
        pthread_mutex_lock(&sync_cnt_lock);
        if (*(child_sync_cnt) > 0) {
            *rp = 2;
            submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
	        pthread_mutex_unlock(&sync_cnt_lock);
            return;
        } else {
            (*parent_sync_cnt)--;
	        //cout<<"second half completed :"<<n<<endl;
            pthread_mutex_unlock(&sync_cnt_lock);
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
 
    submit_task(workers[0], parallel_rec_mm, 0, 0, x, 0, 0, y, 0, 0, N, parent_sync_cnt, child_sync_cnt, rp);
    
    wait_until_done();
    print_matrix(z);
    return 0;
}

