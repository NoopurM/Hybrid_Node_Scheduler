#include <iostream>
#include <map>
#include <queue>
#include <functional>
#include <iostream>
using namespace std;

extern map<pthread_t, deque<function<void()>>> que_map;
template < typename PTHREADID, typename CALLABLE, typename... ARGS >
void submit_task(PTHREADID tid, CALLABLE fn, ARGS&&... args ) { 
    //cout<<"Submitting task to "<<tid<<" queue"<<endl; 
    que_map[tid].push_back( bind( fn, args... ) ) ; 
}
