#include <iostream>
#include <map>
#include <queue>
#include <functional>
#define CUDA_KERNEL __global__
using namespace std;

extern map<pthread_t, deque<function<void()>>> que_map;
template < typename PTHREADID, typename CALLABLE, typename... ARGS >
void submit_task(PTHREADID tid, CALLABLE fn, ARGS&&... args ) { 
    //cout<<"Submitting task to "<<tid<<" queue"<<endl; 
    que_map[tid].push_back( bind( fn, args... ) ) ; 
}


template <typename F, typename ...Args>
void launch_kernel(F fun, Args ...args) {
    fun<<<1,1>>>(args...);
  //cuda_check_last(typeid(F).name());
}
