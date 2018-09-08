CXX=nvcc
CXXFLAGS += -std=c++11
OPFLAGS=-O3
objects := $(patsubst %.cpp,%.o,$(wildcard *.cu))

all: $(objects)
	$(CXX) $(CXXFLAGS) -g -o merge_sort $(objects) -lpthread

clean:
	rm -f *.o
