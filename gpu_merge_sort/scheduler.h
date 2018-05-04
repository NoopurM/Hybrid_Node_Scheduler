#include <iostream>
#include <map>
#include <queue>
#include <functional>
#define CUDA_KERNEL __global__
using namespace std;

extern map<pthread_t, deque<function<void()>>> cpu_que_map;
extern map<pthread_t, deque<function<void()>>> gpu_que_map;
extern vector<pthread_t> gpu_workers;

template < typename PTHREADID, typename CALLABLE, typename... ARGS >
void submit_task(PTHREADID tid, CALLABLE fn, ARGS&&... args ) { 
    //cout<<"Submitting task to "<<tid<<" queue"<<endl; 
    cpu_que_map[tid].push_back( bind( fn, args... ) ) ; 
}


template <typename F, typename ...Args>
void launch_kernel(F fun, Args ...args) {
    fun<<<1,1>>>(args...);
    cudaDeviceSynchronize();
  //cuda_check_last(typeid(F).name());
}

template <typename FLAG, typename CALLABLE1, typename CALLABLE2, typename... ARGS>
void run_task(FLAG run_flag, CALLABLE1 fn1, CALLABLE2 fn2, ARGS&& ...args) {
    if (run_flag == 0) {
        cout<<"Flag provided 0 hence executing func on cpu"<<endl;
        fn1(args...);
    } else if (run_flag == 1) {
        cout<<"Flag provided 1 hence launching kernel"<<endl;
        //fn2(args...);
        gpu_que_map[gpu_workers[0]].push_back(bind(fn2, args...));
    } else {
        //decide where to execute
        fn1(args...);
    }
}
