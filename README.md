# diagram

A C++ programme that renders SVG from a high-level language based on Fennel.
Supports font-to-path conversion and text dimension calculation for non-embedded fonts.

## Dependencies

- `lua5.4` + `fennel.lua` — Fennel language runtime
- `freetype2` — font metrics and glyph outline decomposition
- `harfbuzz` — text shaping (kerning, ligatures, complex scripts)
- `fontconfig` — font discovery by name

## Building

```sh
make
```

Output is written to `target/diagram`.

## Project Structure

```
src/    source files
lib/    vendored external libraries
target/ build output
```

## Developer Notes

See `CLAUDE.md` for coding style and workflow conventions.
