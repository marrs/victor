CXX      = g++
TARGET   = target/victor
UNITY    = src/main.cc

CXXFLAGS = -std=c++17 -Wall -Wextra \
           -I lib \
           $(shell pkg-config --cflags freetype2 harfbuzz fontconfig lua5.4)

LDLIBS   = $(shell pkg-config --libs freetype2 harfbuzz fontconfig lua5.4)

SPECS = $(wildcard spec/fennel/*.fnl)

SVG_VIEWER = imv-x11
EPS_VIEWER = zathura

.PHONY: all clean test smoketest $(SPECS)

all: target $(TARGET)

$(TARGET): $(UNITY)
	$(CXX) $(CXXFLAGS) $< $(LDLIBS) -o $@

target:
	mkdir -p target

$(SPECS): $(TARGET)
	$(TARGET) $@

test: $(TARGET) $(SPECS)
	$(TARGET) test-assets/test-basic.fnl

target/smiley-svg-dsl.svg: test-assets/smiley-svg-dsl.fnl $(TARGET) | target
	$(TARGET) $< > $@

target/smiley-eps-dsl.eps: test-assets/smiley-eps-dsl.fnl $(TARGET) | target
	$(TARGET) $< > $@

# EPS cannot be viewed standalone — zathura (libspectre) treats the EPSF-3.0
# header as an embedded document.  Wrapping it as PS (adding showpage) makes it
# a proper standalone document.
target/smiley-eps-dsl.ps: target/smiley-eps-dsl.eps
	sed 's/%%EOF/showpage\n%%EOF/' $< > $@

target/smiley-pic-svg.svg: test-assets/smiley-pic-svg.fnl $(TARGET) | target
	$(TARGET) $< > $@

target/smiley-pic-eps.eps: test-assets/smiley-pic-eps.fnl $(TARGET) | target
	$(TARGET) $< > $@

target/smiley-pic-eps.ps: target/smiley-pic-eps.eps
	sed 's/%%EOF/showpage\n%%EOF/' $< > $@

smoketest: target/smiley-svg-dsl.svg target/smiley-eps-dsl.ps \
           target/smiley-pic-svg.svg target/smiley-pic-eps.ps
	$(SVG_VIEWER) target/smiley-svg-dsl.svg &
	$(SVG_VIEWER) target/smiley-pic-svg.svg &
	$(EPS_VIEWER) target/smiley-eps-dsl.ps &
	$(EPS_VIEWER) target/smiley-pic-eps.ps

clean:
	rm -f $(TARGET)
