# Bic Grammar

Bic is the base intermediate language. A bic document is a tree of primitive
shape elements that renders directly to SVG or EPS. Types are named with the
`:bic.grammar/` namespace. Each type corresponds to a validator that accepts a
value and returns the validated (possibly normalised) form, or an error.

---

## :bic.grammar/unit

A physical or typographic unit. All position, size, and stroke-width values in
bic carry an explicit unit.

```
:bic.grammar/unit = :in    -- inches
                  | :cm    -- centimetres
                  | :mm    -- millimetres
                  | :pc    -- picas  (1 pc = 12 pt)
                  | :pt    -- points (1 pt = 1/72 in)
                  | :em    -- relative to current font size
                  | :ex    -- relative to x-height of current font
```

```fennel
[:enum :in :cm :mm :pc :pt :em :ex]
```

`:px` is intentionally excluded — bic targets print output.

`:em` and `:ex` are font-relative units. The renderer is expected to maintain
a current font context (name and size) at all times, so these units are always
resolvable. If font context is unavailable at render time, the renderer issues a
warning and substitutes 0.

---

## :bic.grammar/measurement

A scalar quantity with a unit.

```
:bic.grammar/measurement = [number :bic.grammar/unit]
```

```fennel
[:tuple :number :bic.grammar/unit]
```

Examples: `[72 :pt]`, `[2.54 :cm]`, `[1 :in]`, `[10 :mm]`.

---

## :bic.grammar/color-rgb

An additive RGB colour. Each component is a normalised real in the range 0–1,
matching the EPS `setrgbcolor` and PDF `DeviceRGB` native representations.

```
:bic.grammar/color-rgb = {:r number :g number :b number}
                         -- each component in [0, 1]
```

```fennel
[:map {:closed true}
  [:r [:range 0 1]]
  [:g [:range 0 1]]
  [:b [:range 0 1]]]
```

---

## :bic.grammar/color-hsb

A colour in Hue–Saturation–Brightness (HSV) space. HSB maps directly onto EPS
`sethsbcolor`; no conversion is needed for EPS output. For SVG output the
renderer converts HSB → RGB.

```
:bic.grammar/color-hsb = {:h number :s number :b number}
                         -- h in [0, 360), s and b in [0, 1]
```

```fennel
[:map {:closed true}
  [:h [:range 0 360]]
  [:s [:range 0 1]]
  [:b [:range 0 1]]]
```

---

## :bic.grammar/color-hex

A CSS-style hexadecimal RGB colour string. Both shorthand and full forms are
accepted; shorthand digits are expanded by doubling (`"#abc"` → `"#aabbcc"`).
Alpha is not supported.

```
:bic.grammar/color-hex = "#rgb"      -- 3-digit shorthand
                       | "#rrggbb"   -- 6-digit full form
```

```fennel
[:string [:pattern "^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$"]]
```

---

## :bic.grammar/color-name

A CSS named colour keyword. The full set of 147 CSS named colours is supported.
The canonical RGB 0–1 values for each name are defined in
`src/fennel/bic/colors.fnl`.

```
:bic.grammar/color-name = keyword   -- e.g. :cornflowerblue, :rebeccapurple
```

```fennel
[:member bic.colors/names]
```

---

## :bic.grammar/color

Any colour expression. The validator normalises all forms to an internal
`{:r :g :b}` map (0–1 components) for use by renderers.

```
:bic.grammar/color = :bic.grammar/color-rgb
                   | :bic.grammar/color-hsb
                   | :bic.grammar/color-hex
                   | :bic.grammar/color-name
```

```fennel
[:or
  :bic.grammar/color-rgb
  :bic.grammar/color-hsb
  :bic.grammar/color-hex
  :bic.grammar/color-name]
```

**SVG import note.** Web SVG documents may contain colour formats not in this
grammar (`hsl()`, percentage `rgb()`, `currentColor`, CSS custom properties,
etc.). These are handled by an SVG→bic translation layer that resolves all
such values to concrete `{:r :g :b}` maps before producing a bic document.
The bic colour grammar is deliberately narrower than the CSS colour specification;
the translation layer is responsible for the full CSS gamut.

---

## Document element

The root of a bic document.

```
[:bic {:width  :bic.grammar/measurement
       :height :bic.grammar/measurement}
  & children]
```

`:width` and `:height` define the canvas size. Children are primitive shape
elements; unknown tags are rejected by the renderer.

---

## :rect

An axis-aligned rectangle.

| Attr | Type | Required | Notes |
|---|---|---|---|
| `:x` | `:bic.grammar/measurement` | yes | left edge |
| `:y` | `:bic.grammar/measurement` | yes | top edge (SVG convention; EPS renderer flips) |
| `:width` | `:bic.grammar/measurement` | yes | |
| `:height` | `:bic.grammar/measurement` | yes | |
| `:rx` | `:bic.grammar/measurement` | no | horizontal corner radius |
| `:ry` | `:bic.grammar/measurement` | no | vertical corner radius; defaults to `:rx` if omitted |
| `:fill` | `:bic.grammar/color` | no | |
| `:stroke` | `:bic.grammar/color` | no | |
| `:stroke-width` | `:bic.grammar/measurement` | no | |

If neither `:fill` nor `:stroke` is given, the renderer strokes with the
current default colour.

---

## :circle

A circle.

| Attr | Type | Required | Notes |
|---|---|---|---|
| `:cx` | `:bic.grammar/measurement` | yes | centre x |
| `:cy` | `:bic.grammar/measurement` | yes | centre y |
| `:r` | `:bic.grammar/measurement` | yes | radius |
| `:fill` | `:bic.grammar/color` | no | |
| `:stroke` | `:bic.grammar/color` | no | |
| `:stroke-width` | `:bic.grammar/measurement` | no | |

Same fill/stroke defaulting rules as `:rect`.

---

## :text

A text string placed at a point. The string is rendered in the named font at
the given size. Non-ASCII codepoints are resolved to PostScript glyph names via
the AGL and the font's post table.

| Attr | Type | Required | Notes |
|---|---|---|---|
| `:x` | `:bic.grammar/measurement` | yes | baseline start x |
| `:y` | `:bic.grammar/measurement` | yes | baseline y (SVG convention) |
| `:font` | `string` | yes | PostScript / CSS font-family name |
| `:size` | `:bic.grammar/measurement` | yes | typically `[12 :pt]` |
| `:str` | `string` | yes | UTF-8 text content |
