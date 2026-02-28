CXX      = g++
TARGET   = target/victor
UNITY    = src/main.cc

CXXFLAGS = -std=c++17 -Wall -Wextra \
           -I lib \
           $(shell pkg-config --cflags freetype2 harfbuzz fontconfig lua5.4)

LDLIBS   = $(shell pkg-config --libs freetype2 harfbuzz fontconfig lua5.4)

SPECS     = $(wildcard spec/fennel/*.fnl)
SPEC      = target/spec
SRC_FILES = $(wildcard src/*.cc src/*.h)
SPEC_FILES = spec/main.cc spec/util.cc spec/font.cc spec/groff.cc \
             spec/font-mocks.h spec/fs-mocks.h spec/capture.h spec/test.h \
             $(SRC_FILES)

SVG_VIEWER = imv-x11 -b checks
EPS_VIEWER = zathura

.PHONY: all clean tags test smoketest $(SPECS)

all: target $(TARGET)

$(TARGET): $(SRC_FILES) | target
	$(CXX) $(CXXFLAGS) $(UNITY) $(LDLIBS) -o $@

$(SPEC): $(SPEC_FILES) | target
	$(CXX) $(CXXFLAGS) spec/main.cc $(shell pkg-config --libs lua5.4) -ldl -o $@

target:
	mkdir -p target

$(SPECS): $(TARGET)
	$(TARGET) $@

test: $(SPEC)
	$(SPEC)
	for spec in $(SPECS); do $(TARGET) $$spec || exit 1; done
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

target/test-groff.ps: test-assets/test-groff.ms $(TARGET) | target
	$(TARGET) groff $< | groff -ms - > $@

smoketest: target/smiley-svg-dsl.svg target/smiley-eps-dsl.ps \
           target/smiley-pic-svg.svg target/smiley-pic-eps.ps \
           target/test-groff.ps
	$(SVG_VIEWER) target/smiley-svg-dsl.svg &
	$(SVG_VIEWER) target/smiley-pic-svg.svg &
	$(EPS_VIEWER) target/smiley-eps-dsl.ps &
	$(EPS_VIEWER) target/smiley-pic-eps.ps &
	$(EPS_VIEWER) target/test-groff.ps

tags:
	ctags -R *

clean:
	rm -rf target
