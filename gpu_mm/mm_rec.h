#include <iostream>
#include <vector>
#include <queue>
#include <functional>
#include <map>
#include <chrono>
#include "scheduler.h"
#include "atomic.h"
using namespace std;

extern bool create_threadpool(int nworkers);
extern void wait_until_done();
//extern template void submit_task(typename PTHREADID, typename CALLABLE, typename... ARGS);
