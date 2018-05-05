#include <iostream>
#include <cmath>
#include <vector>
#include <map>
#include <queue>
#include <functional>
#include "scheduler.h"
#include "atomic.h"
using namespace std;

extern bool create_threadpool(int nworkers);
extern void wait_until_done();
