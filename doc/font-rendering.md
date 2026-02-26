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

## Unicode: `show` for ASCII runs, `glyphshow` for individual non-ASCII glyphs

PostScript's traditional encoding vectors map byte values 0–255 to glyph
names. This is sufficient for ASCII but not for Unicode.

The approach used here splits text at the caller level (the layer that
compiles the high-level diagram DSL to the EPS DSL):

- **ASCII runs** are emitted as a plain PS string literal with `show`:

  ```postscript
  /Helvetica findfont 14 scalefont setfont
  50 60 moveto
  (Hello, World! ) show
  ```

- **Individual non-ASCII codepoints** are emitted by glyph name with
  `glyphshow`. The caller is responsible for looking up the Adobe Glyph List
  name for the codepoint (`uniXXXX` for BMP, `uXXXXX` for supplementary):

  ```postscript
  /uni263A glyphshow
  ```

  `glyphshow` bypasses the font's encoding vector and addresses the glyph
  directly by name. It works for any font that carries a `post` table with
  standard AGL names — which is true of well-formed OpenType/TrueType fonts.

### Why not CIDFont + Identity-H?

The canonical PostScript Unicode solution is `composefont` with the
`Identity-H` CMap, which maps UTF-16BE byte pairs directly to glyph IDs.
This was rejected for two reasons:

1. **Runtime dependency.** `composefont` requires a CIDFont resource to be
   registered with GhostScript. No stock Debian GhostScript installation
   provides usable CIDFont resources for common Latin or emoji fonts; the
   `composefont` call raises `typecheck in composefontdict` at runtime.
2. **DSL statelessness.** The EPS DSL emits independent operator nodes;
   `:setfont` and `:show` cannot share encoding state. A re-encoded Type 42
   wrapper would have to be embedded inline at the `:setfont` site with no
   coordination possible at the `:show` site.

### Glyph name coverage

`glyphshow` requires the font to expose the glyph under its AGL name. Fonts
without a `post` table (or with a format-3 `post` that omits names) cause
GhostScript to synthesise names of the form `_NNNN` (glyph index), which
do not match AGL names. The C++ layer must verify glyph-name coverage before
emitting a `:glyphshow` node and fall back gracefully when the name is absent.

## Features deferred

- **`charpath` / outlined text** — useful for decorative text; deferred until
  such time as there is a demand for it..
- **Glyph path emission** — will be required for v1.
