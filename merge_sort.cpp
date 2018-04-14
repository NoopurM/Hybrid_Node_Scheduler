#include <iostream>
#include <cmath>
#include <cilk/cilk.h>
#include <cilk/cilk_api.h>
using namespace std;

void merge(int *arr, int p, int q, int r) {
	int left[q-p+1], right[r-q];
	int i,j,k;
	for(i=0;i<q-p+1;i++) {
		left[i] = arr[i+p];
	}
	for(i=0;i<r-q;i++) {
		right[i] = arr[i+q+1];
	}
	for(k=p,i=0,j=0;i<(q-p+1) && j<(r-q);) {
		if (left[i] <= right[j]) {
			arr[k] = left[i];
			i++;
			k++;
		} else {
			arr[k] = right[j];
			j++;
			k++;
		}
	}
	while(i<(q-p+1)) {
		arr[k] = left[i];
		k++;
		i++;
	}
	while(j<(r-q)) {
		arr[k] = right[j];
		k++;
		j++;
	}
}
int parallel_merge_sort(int *arr, int p, int r) {
	cout<<"p = "<<p<<" r = "<<r<<endl;
	if (p < r) {
		int q = floor((p+r)/2);
		//cout<<q<<endl;
		cilk_spawn parallel_merge_sort(arr, p, q);
		//parallel_merge_sort(arr, p, q);
		parallel_merge_sort(arr, q+1, r);
		cilk_sync;

		merge(arr, p, q, r);
		for(int i=p;i<r;i++) {
			cout<<arr[i]<<" ";
		}
		cout<<endl;
	}
}
int main() {
	int arr[10] = {23,12,11,33,2,1,4,22,12,10};
	parallel_merge_sort(arr, 0, 9);
	for (int i=0;i<10;i++) {
		cout<<arr[i]<<" ";
	}
}
