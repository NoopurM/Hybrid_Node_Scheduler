#include <iostream>
#include <map>
#include <queue>
#include <functional>
//#include "scheduler.h"
using namespace std;

map<pthread_t, deque<function<void()>>> cpu_que_map;
map<pthread_t, pthread_mutex_t> cpu_lock_map;
map<pthread_t, deque<function<void()>>> gpu_que_map;
map<pthread_t, pthread_mutex_t> gpu_lock_map;
map<pthread_t, cudaStream_t> stream_map;
extern bool completed;

pthread_t get_random_cpu() {
    static unsigned long x=123456789, y=362436069, z=521288629;

    unsigned long t;
    x ^= x << 16;
    x ^= x >> 5;
    x ^= x << 1;

    t = x;
    x = y;
    y = z;
    z = t ^ x ^ y;
    auto itr = cpu_que_map.begin();
    return next(itr, z%cpu_que_map.size())->first;
}

pthread_t get_random_gpu() {
    static unsigned long x=123456789, y=362436069, z=521288629;

    unsigned long t;
    x ^= x << 16;
    x ^= x >> 5;
    x ^= x << 1;

    t = x;
    x = y;
    y = z;
    z = t ^ x ^ y;
    auto itr = gpu_que_map.begin();
    return next(itr, z%gpu_que_map.size())->first;
}

void* __do_work_cpu(void *data) {
    pthread_t tid, tid_stolen;
    while(!completed) {
        tid = pthread_self();
        pthread_mutex_lock(&(cpu_lock_map[tid]));
        if (completed && cpu_que_map[tid].size() == 0) {
            pthread_mutex_unlock(&cpu_lock_map[tid]);
            break;
        }
        if (!cpu_que_map[tid].empty()) {
            cpu_que_map[tid].front()();
            cpu_que_map[tid].pop_front();
            pthread_mutex_unlock(&cpu_lock_map[tid]);
            continue;
        } else {
            pthread_mutex_unlock(&cpu_lock_map[tid]);
        }
        
        //Steal from other queue
        tid_stolen = get_random_cpu(); 
        pthread_mutex_lock(&cpu_lock_map[tid_stolen]); 
        if (completed && cpu_que_map[tid_stolen].size() == 0) {
            pthread_mutex_unlock(&cpu_lock_map[tid_stolen]);
            break;
        }
        if (!cpu_que_map[tid_stolen].empty()) {
            cpu_que_map[tid_stolen].back()();
            cpu_que_map[tid_stolen].pop_back();
            pthread_mutex_unlock(&cpu_lock_map[tid_stolen]);
            continue;
        } else {
            pthread_mutex_unlock(&cpu_lock_map[tid_stolen]);
        }
    }
    cout<<"CPU:"<<tid<<" exited"<<endl;
    pthread_exit(NULL);
}

void* __do_work_gpu(void *data) {
    pthread_t tid, tid_stolen;
    while(!completed) {
        tid = pthread_self();
        pthread_mutex_lock(&(gpu_lock_map[tid]));
        if (completed && gpu_que_map[tid].size() == 0) {
            pthread_mutex_unlock(&gpu_lock_map[tid]);
            break;
        }
        if (!gpu_que_map[tid].empty()) {
            gpu_que_map[tid].front()();
            gpu_que_map[tid].pop_front();
            pthread_mutex_unlock(&gpu_lock_map[tid]);
            continue;
        } else {
            pthread_mutex_unlock(&gpu_lock_map[tid]);
        }
        
        //Steal from other queue
        tid_stolen = get_random_gpu(); 
        pthread_mutex_lock(&gpu_lock_map[tid_stolen]); 
        if (completed && gpu_que_map[tid_stolen].size() == 0) {
            pthread_mutex_unlock(&gpu_lock_map[tid_stolen]);
            break;
        }
        if (!gpu_que_map[tid_stolen].empty()) {
            gpu_que_map[tid_stolen].back()();
            gpu_que_map[tid_stolen].pop_back();
            pthread_mutex_unlock(&gpu_lock_map[tid_stolen]);
            continue;
        } else {
            pthread_mutex_unlock(&gpu_lock_map[tid_stolen]);
        }
    }
    cout<<"GPU:"<<tid<<" exited"<<endl;
    pthread_exit(NULL);
}

