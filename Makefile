CXX      = g++
TARGET   = target/diagram
UNITY    = src/main.cc

CXXFLAGS = -std=c++17 -Wall -Wextra \
           -I lib \
           $(shell pkg-config --cflags freetype2 harfbuzz fontconfig lua5.4)

LDLIBS   = $(shell pkg-config --libs freetype2 harfbuzz fontconfig lua5.4)

.PHONY: all clean

all: target $(TARGET)

$(TARGET): $(UNITY)
	$(CXX) $(CXXFLAGS) $< $(LDLIBS) -o $@

target:
	mkdir -p target

clean:
	rm -f $(TARGET)
