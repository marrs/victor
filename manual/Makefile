.DELETE_ON_ERROR:

VICTOR   = ../target/victor
GROFF    = groff -ms
CHAPTERS = vic bic eps svg

PROCESSED = $(CHAPTERS:%=../target/man-%.ms)

../target/man-%-src.ms: src/%.ms | ../target
	awk -f codex-expand $< > $@

../target/man-%.ms: ../target/man-%-src.ms $(VICTOR)
	cd .. && $(abspath $(VICTOR)) groff -i target target/man-$*-src.ms > target/man-$*.ms

../target/manual.ps: src/manual.ms src/macros.ms $(PROCESSED)
	cd .. && $(GROFF) manual/src/manual.ms > target/manual.ps

../target/manual.pdf: ../target/manual.ps
	ps2pdf $< $@

../target:
	mkdir -p ../target

.PHONY: all
all: ../target/manual.pdf
