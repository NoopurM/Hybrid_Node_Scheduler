CXX=icpc
CXXFLAGS += -std=c++11
OPFLAGS=-O3
objects := $(patsubst %.cpp,%.o,$(wildcard *.cpp))

all: $(objects)
	#$(CXX) $(CXXFLAGS) -o mm_rec $(objects) -lpthread
	$(CXX) $(CXXFLAGS) -g -o merge_sort $(objects) -lpthread

clean:
	rm -f *.o
