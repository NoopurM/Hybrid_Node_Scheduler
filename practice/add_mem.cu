//#include "../common/book.h"
#include<iostream>
#define N 10
#define CUDA_KERNEL __global__
using namespace std;

template <typename F, typename ...Args>
void cuda_launch_kernel(F fun, Args ...args) {
    fun<<<1,1>>>(args...);
  //cuda_check_last(typeid(F).name());
}

CUDA_KERNEL void add( int *a, int *b, int *c ) {
 for (int i=0; i < N; i++) {
 c[i] = a[i] + b[i];
 }
}

int main( void ) {
	 int a[N], b[N], c[N];
	 int *dev_a, *dev_b, *dev_c;

	 // allocate the memory on the GPU
	 cudaMalloc( (void**)&dev_a, N * sizeof(int) ) ;
	 cudaMalloc( (void**)&dev_b, N * sizeof(int) ) ;
	 cudaMalloc( (void**)&dev_c, N * sizeof(int) );

	 // fill the arrays 'a' and 'b' on the CPU
	 for (int i=0; i<N; i++) {
	 a[i] = i;
	 b[i] = i * i;
	 c[i] = 0;
	 }

	// copy the arrays 'a' and 'b' to the GPU
	 cudaMemcpy( dev_a, a, N * sizeof(int),
	 cudaMemcpyHostToDevice );
	 cudaMemcpy( dev_b, b, N * sizeof(int),
	 cudaMemcpyHostToDevice ) ;
	 cuda_launch_kernel(add, dev_a, dev_b, dev_c);

	 // copy the array 'c' back from the GPU to the CPU
	 cudaMemcpy( c, dev_c, N * sizeof(int),
	 cudaMemcpyDeviceToHost );

	 // display the results
	 for (int i=0; i<N; i++) {
	 printf( "%d + %d = %d\n", a[i], b[i], c[i] );
	 }

	 // free the memory allocated on the GPU
	 cudaFree( dev_a );
	 cudaFree( dev_b );
	 cudaFree( dev_c );
	 return 0;
}
