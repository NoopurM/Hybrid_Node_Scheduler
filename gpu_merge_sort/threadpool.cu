#include <iostream>
#include <vector>
#include <map>
using namespace std;

extern void *__do_work_cpu(void *data);
extern void *__do_work_gpu(void *data);
extern map<pthread_t, pthread_mutex_t> cpu_lock_map;
extern map<pthread_t, pthread_mutex_t> gpu_lock_map;
extern map<pthread_t, cudaStream_t> stream_map;
vector<pthread_t> cpu_workers;
vector<pthread_t> gpu_workers;

bool __create_cpu_threadpool(int nworkers) {
    cpu_workers.resize(nworkers);
    bool ret = true;
    for (int i=0; i<nworkers; i++) {
        if(pthread_create(&cpu_workers[i], NULL, __do_work_cpu, (void *)(i+1))) {
            cout<<"Failed to create thread for id :"<<i<<endl;
            ret = false;
        } else {
            pthread_mutex_init(&cpu_lock_map[cpu_workers[i]], NULL);
        }
    }
    return ret;
}

bool __create_gpu_threadpool(int nworkers) {
    gpu_workers.resize(nworkers);
    bool ret = true;
    for (int i=0; i<nworkers; i++) {
        if(pthread_create(&gpu_workers[i], NULL, __do_work_gpu, (void *)(i+1))) {
            //cout<<"Failed to create thread for id :"<<i<<endl;
            ret = false;
        } else {
            cudaStreamCreate(&stream_map[gpu_workers[i]]);
            pthread_mutex_init(&gpu_lock_map[gpu_workers[i]], NULL);
        }
    }
    return ret;
}

bool create_threadpool(int nworkers) {
    bool ret;
    ret = __create_cpu_threadpool(nworkers);
    if (!ret) {
        cout<<"Failed to spawn cpu threads"<<endl;
    }

    ret = __create_gpu_threadpool(nworkers);
    if (!ret) {
        //cout<<"Failed to spawn gpu threads"<<endl;
    }

    return ret;
}

void wait_until_done() {
    void *status;
    for(int i=0; i<cpu_workers.size(); i++) {
        if(pthread_join(cpu_workers[i], &status)) {
            cout<<"Failed to join thread for id :"<<i<<endl;
        }
    }
    cout<<"CPU threads finished"<<endl; 
    for(int i=0; i<gpu_workers.size()-1; i++) {
        if(pthread_join(gpu_workers[i], &status)) {
            cout<<"Failed to join thread for id :"<<i<<endl;
        }
    }
    cudaDeviceReset();
    cout<<"GPU threads finished"<<endl;
    return;
}
