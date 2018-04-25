#include <iostream>
#include <vector>
#include <map>
using namespace std;

extern void *do_work(void *data);
extern map<pthread_t, pthread_mutex_t> lock_map;
vector<pthread_t> workers;

bool create_threadpool(int nworkers) {
    workers.resize(nworkers);
    bool ret = true;
    for (int i=0; i<nworkers; i++) {
        if(pthread_create(&workers[i], NULL, do_work, (void *)(i+1))) {
            cout<<"Failed to create thread for id :"<<i<<endl;
            ret = false;
        } else {
            pthread_mutex_init(&lock_map[workers[i]], NULL);
        }
    }
    return ret;
}

void wait_until_done() {
    void *status;
    for(int i=0; i<workers.size(); i++) {
        if(pthread_join(workers[i], &status)) {
            cout<<"Failed to join thread for id :"<<i<<endl;
        }
    }
    return;
}
