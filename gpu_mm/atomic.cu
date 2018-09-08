/*
 * Noopur Maheshwari : 111464061
 * Rahul Rane : 111465246
 */
#include <pthread.h>
#include <iostream>
using namespace std;
extern pthread_mutex_t lock;

int get_shared_var_value(int *ptr) {
    int ret;
    //cout<<"About to lock 1"<<endl;
    pthread_mutex_lock(&lock);
    //cout<<"lock 1"<<endl;
    ret = *ptr;
    //cout<<"About to unlock 1"<<endl;
    pthread_mutex_unlock(&lock);
    //cout<<"unlocked 1"<<endl;
    return ret;
}

void set_shared_var_value(int *ptr, int val) {
    //cout<<"About to lock 2"<<endl;
    pthread_mutex_lock(&lock);
    //cout<<"lock 2"<<endl;
    (*ptr) = val;
    //cout<<"About to unlock 2"<<endl;
    pthread_mutex_unlock(&lock); 
    //cout<<"unlocked 2"<<endl;
}

void dec_shared_var_value(int *ptr) {
    //cout<<"About to lock 3"<<endl;
    pthread_mutex_lock(&lock);
    //cout<<"lock 3"<<endl;
    (*ptr)--;
    //cout<<"About to unlock 3"<<endl;
    pthread_mutex_unlock(&lock); 
    //cout<<"unlocked 3"<<endl;
}
