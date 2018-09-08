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
    pthread_mutex_lock(&lock);
    ret = *ptr;
    pthread_mutex_unlock(&lock);
    return ret;
}

void set_shared_var_value(int *ptr, int val) {
    pthread_mutex_lock(&lock);
    (*ptr) = val;
    pthread_mutex_unlock(&lock); 
}

void dec_shared_var_value(int *ptr) {
    pthread_mutex_lock(&lock);
    (*ptr)--;
    pthread_mutex_unlock(&lock); 
}
