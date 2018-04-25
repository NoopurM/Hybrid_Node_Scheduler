#include <iostream>
#include <map>
#include <queue>
#include <functional>
#include "scheduler.h"
using namespace std;

map<pthread_t, deque<function<void()>>> que_map;
map<pthread_t, pthread_mutex_t> lock_map;
extern bool completed;

pthread_t get_random() {
    static unsigned long x=123456789, y=362436069, z=521288629;

    unsigned long t;
    x ^= x << 16;
    x ^= x >> 5;
    x ^= x << 1;

    t = x;
    x = y;
    y = z;
    z = t ^ x ^ y;
    auto itr = que_map.begin();
    return next(itr, z%que_map.size())->first;
}

void* do_work(void *data) {
    pthread_t tid, tid_stolen;
    while(!completed) {
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
        
        //Steal from other queue
        tid_stolen = get_random(); 
        pthread_mutex_lock(&lock_map[tid_stolen]); 
        if (completed && que_map[tid_stolen].size() == 0) {
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
    cout<<tid<<" exited"<<endl;
    pthread_exit(NULL);
}

