#  Font Rendering

Three approaches exist for rendering text in SVG and EPS output:

1. **Glyph paths** — use FreeType (`FT_Outline_Decompose`) to convert each
   glyph to bezier curves and emit them as geometry. No font data in the
   output file.
2. **Embed font** — encode the font binary (as WOFF2 for SVG, Type 42 for
   EPS) into the output file.
3. **System font** — emit the font name and string; the viewer resolves the
   font at render time.

All three options require HarfBuzz + FreeType at generation time to shape
text and compute metrics (advance widths, bounding boxes) for layout. The
options differ only in what is emitted.

Victor supports (or will support) system fonts and glyph paths.  Embedded fonts
add too much bloat for the amount of text required by the kind of content
Victor produces.

### Copyright awareness

Embedding fonts or converting to paths both reproduce glyph outlines, which
are copyrightable. Only OFL-licensed fonts (e.g. most Google Fonts) explicitly
permit this in output files. Commercial and system fonts (macOS, Windows, most
Linux distros) typically prohibit redistribution of outlines. System font
output avoids this issue entirely since no font data is included.

Victor will issue a warning to stderr when vectorising fonts.

## Unicode: always UTF-16BE via CIDFont

PostScript's traditional encoding vectors map byte values 0–255 to glyph
names. This is insufficient for Unicode. The correct PostScript solution is
**CIDFonts** with the **Identity-H** CMap, which maps UTF-16BE byte pairs
directly to glyph IDs:

```postscript
/FontName findfont /Identity-H composefont 14 scalefont setfont
50 60 moveto
(\x00H\x00e\x00l\x00l\x00o) show
```

An alternative is to split strings into ASCII and non-ASCII runs, using a
cheap 8-bit encoding for ASCII and CIDFont only for non-ASCII characters.
This was rejected:

- **Space saving is negligible.** At 100 words of diagram text per 5 pages (all
  ASCII, worst case), the UTF-16BE overhead is ~2 KB uncompressed and ~150
  bytes compressed. Even at 500 pages this is trivial compared to diagram
  geometry data.
- **Complexity is not trivial.** Run-splitting requires font-switching between
  segments and risks metric mismatches at join points if the interpreter
  resolves the two font objects to different underlying data.
- **Uniformity.** A single code path for all text is easier to reason about and
  test.

UTF-16BE is used throughout. The Fennel/Lua layer converts UTF-8 input
strings to UTF-16BE before embedding them in EPS output.

## Features deferred

- **`charpath` / outlined text** — useful for decorative text; deferred until
  such time as there is a demand for it..
- **Glyph path emission** — will be required for v1.
