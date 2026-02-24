CXX      = g++
TARGET   = target/diagram
UNITY    = src/main.cc

CXXFLAGS = -std=c++17 -Wall -Wextra \
           -I lib \
           $(shell pkg-config --cflags freetype2 harfbuzz fontconfig lua5.4)

LDLIBS   = $(shell pkg-config --libs freetype2 harfbuzz fontconfig lua5.4)

SPECS = $(wildcard spec/fennel/*.fnl)

.PHONY: all clean test $(SPECS)

all: target $(TARGET)

$(TARGET): $(UNITY)
	$(CXX) $(CXXFLAGS) $< $(LDLIBS) -o $@

target:
	mkdir -p target

$(SPECS): $(TARGET)
	$(TARGET) $@

test: $(TARGET) $(SPECS)
	$(TARGET) test-assets/test-basic.fnl

clean:
	rm -f $(TARGET)
