CXX=g++
CXXFLAGS += -std=c++11
OPFLAGS=-O3
objects := $(patsubst %.cpp,%.o,$(wildcard *.cpp))

all: $(objects)
	$(CXX) $(CXXFLAGS) -o mm_rec $(objects) -lpthread

clean:
	rm -f *.o
