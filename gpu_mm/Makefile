CXX=nvcc
CXXFLAGS += -std=c++11
OPFLAGS=-O3
objects := $(patsubst %.cpp,%.o,$(wildcard *.cu))

all: $(objects)
	$(CXX) $(CXXFLAGS) -g -o mm_rec $(objects) -lpthread

clean:
	rm -f *.o
