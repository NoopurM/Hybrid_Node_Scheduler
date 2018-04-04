#include <iostream>
#include <vector>
#include <queue>
#include <functional>
#include <map>
using namespace std;

int matrix_sz=32;
vector<vector<int> > x(matrix_sz, vector<int>(matrix_sz, 3));
vector<vector<int> > y(matrix_sz, vector<int>(matrix_sz, 3));
vector<vector<int> > z(matrix_sz, vector<int>(matrix_sz));

map<pthread_t, deque<function<void()>>> que_map;
map<pthread_t, pthread_cond_t> que_cond_map;
map<pthread_t, pthread_mutex_t> lock_map;

bool completed=false;

template < typename PTHREADID, typename CALLABLE, typename... ARGS >
void submit_task(PTHREADID tid, CALLABLE fn, ARGS&&... args ) { 
    //cout<<"Submitting task to "<<tid<<" queue"<<endl; 
    que_map[tid].push_back( bind( fn, args... ) ) ; 
}

void print_matrix(vector<vector<int> > a) {
    cout<<"Matrix :"<<endl;
    for(int i=0;i<a.size();i++) {
        for(int j=0; j<a[0].size();j++) {
            cout<<a[i][j]<<" ";
        }
        cout<<"\n";
    }
}


void parallel_rec_mm(int r_z, int c_z, vector<vector<int> > x, int r_x, int c_x, vector<vector<int> > y, int r_y, int c_y, int n, int *parent_sync_cnt, int *child_sync_cnt, int *rp) {
    pthread_t tid = pthread_self();
    cout<<"parallel_rec_mm: n="<<n<<endl;
    if (n == 1) {
        z[r_z][c_z] = z[r_z][c_z] + x[r_x][c_x]*y[r_y][c_y];
        (*parent_sync_cnt)--;
    } else {
        if (*rp == 0) {
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
            
            if (*(child_sync_cnt) > 0) {
                *rp = 1;
                submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
                return;
            }
        }
        if (*rp == 1) {
            if (*(child_sync_cnt) > 0) {
                *rp = 1;
                submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
                return;
            }
        } 
        
        if (*rp != 2) {
            *child_sync_cnt = 4;
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
        if (*(child_sync_cnt) > 0) {
            *rp = 2;
            submit_task(tid, parallel_rec_mm, r_z, c_z, x, r_x, c_x, y, r_y, c_y, n, parent_sync_cnt, child_sync_cnt, rp);
            return;
        } else {
            (*parent_sync_cnt)--;
        }
    }
}


pthread_t get_random(pthread_t selfid) {
    pthread_t res = selfid;
    auto itr = que_map.begin();
    while(res == selfid) {
        res = next(itr, rand()%que_map.size())->first;
    }
    //cout<<"Stealing from :"<<res<<endl;
    return res;
}
bool check_ques_empty() {
    for(auto itr=que_map.begin();itr!=que_map.end();itr++) {
        if (itr->second.size() > 0) {
            return false;
        }
    }
    return true;
}
void* do_work(void *data) {
    pthread_t tid, tid_stolen;
    while(1) {
        tid = pthread_self();
        pthread_mutex_lock(&(lock_map[tid]));
        if (completed && que_map[tid].size() == 0) {
            pthread_mutex_unlock(&lock_map[tid]);
            break;
        }
        if (!que_map[tid].empty()) {
            que_map[tid].front()();
            que_map[tid].pop_front();
            pthread_mutex_unlock(&lock_map[tid]);
            continue;
        } else {
            pthread_mutex_unlock(&lock_map[tid]);
        }
        
        //cout<<tid<<" : "<<que_map[tid].size()<<endl;
        //Steal from other queue
        tid_stolen = get_random(tid); 
        pthread_mutex_lock(&lock_map[tid_stolen]); 
        if (completed && que_map[tid].size() == 0) {
            pthread_mutex_unlock(&lock_map[tid_stolen]);
            break;
        }
        if (!que_map[tid_stolen].empty()) {
            que_map[tid_stolen].back()();
            que_map[tid_stolen].pop_back();
            pthread_mutex_unlock(&lock_map[tid_stolen]);
            continue;
        } else {
            pthread_mutex_unlock(&lock_map[tid_stolen]);
        }
    }
    pthread_exit(NULL);
}

void dr_steal() {
    vector<pthread_t>tids(4);
    void *status;
    
    for(int i=0;i<4;i++) {
        if(pthread_create(&tids[i], NULL, do_work, (void *)(i+1))) {
            cout<<"Failed to create thread for id :"<<i<<endl;
        } else {
            pthread_mutex_init(&lock_map[tids[i]], NULL);
        }
    }
    
    int *parent_sync_cnt = new int(4);
    int *rp = new int(0);
    int *child_sync_cnt = new int(4);
 
    submit_task(tids[0], parallel_rec_mm, 0, 0, x, 0, 0, y, 0, 0, matrix_sz, parent_sync_cnt, child_sync_cnt, rp);

    while(*rp != 2);
    completed = true;
    for(int i=0;i<4;i++) {
        if(pthread_join(tids[i], &status)) {
            cout<<"Failed to join thread for id :"<<i<<endl;
        }
        cout<<" "<<que_map[tids[i]].size();
    }

}
int main(int argc, char *argv[]) {
    //int n=4;
    //vector<vector<int> > x(n, vector<int>(n, 3));
    //vector<vector<int> > y(n, vector<int>(n, 3));
    //vector<vector<int> > z(n, vector<int>(n));

    //populate_matrix(x);
    //populate_matrix(y);
    //populate_matrix(x);
    print_matrix(x);
    print_matrix(y);
    print_matrix(z);

    dr_steal();
    print_matrix(z);
	return 0;
}


