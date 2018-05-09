#include <pthread.h>

int get_shared_var_value(int *ptr);
void set_shared_var_value(int *ptr, int val);
void dec_shared_var_value(int *ptr);

