# Development Workflow

## BDD Feature Development

All new features follow a 3-stage workflow:

1. **Spec descriptions** — Write test descriptions with empty bodies. Wait for user approval before proceeding.
2. **Spec bodies** — Write the test implementations. Wait for user approval before proceeding.
3. **Implementation** — Write code until all tests pass.

Do not edit tests after they have been approved without explicitly asking the user for permission first.

## Build Process

The user builds the code and pastes any errors. Do not run the build yourself.

## C++ Style

The codebase is written in a C-style subset of C++:

- No RAII
- No constructor functions or destructors for resource management
- No dynamic dispatch — do not use `virtual`
- Inheritance is permitted for shared fields and compile-time type relationships (no vtables)
- Function signature overloading is used heavily
- No templates
- No features that negatively impact compilation time

## Fennel Notes

- Dotted names in `deftest` (e.g. `deftest eps.str`) compile to table field assignment, overwriting the module function and causing infinite recursion. The `deftest` macro binds the test function to a gensym to avoid this.
- `/` → `:` transformation (for namespaced XML tags/attrs) only applies to globals, not locals. Use dot notation for local variable field access: `xml.str`, not `xml/str`.

## EPS / PS Output

- `src/fennel/eps.fnl` — EPS DSL module with a dispatch table mapping operator keywords to ordered argument lists.
- EPS DSL mirrors SVG DSL structure: `[:eps {:width w :height h} op1 op2 ...]`
- Raw EPS cannot be viewed standalone in zathura — the `EPSF-3.0` header causes libspectre to treat it as an embedded document (blank page). Wrap as PS by inserting `showpage` before `%%EOF` via sed. Requires the `zathura-ps` plugin.
- SVG viewed with `imv-x11`.

## Error / Warning Convention

Functions that validate or transform return values using one of two conventions:

**Validators** (`validator.validate`, etc.) return a single issue map or `nil`:
```fennel
nil                                          ;; valid
{:level :error   :type :ns/code :msg "..."}  ;; invalid
{:level :warning :type :ns/code :msg "..."}  ;; valid but suspicious
```

**Renderers** (`pic.render`, etc.) return a 2-element tuple:
```fennel
[nil result]                                 ;; success
[{:level :warning :type :ns/code :msg "..."} result]  ;; warning — result still produced
[{:level :error   :type :ns/code :msg "..."} nil]     ;; error — no result
```

The caller decides how to handle issues (collect warnings, abort on first error, etc.).

## Naming Conventions

- Single-character variable names are never used — they make searching difficult
- Short names are acceptable for small utility functions or localised blocks of code where the definition is in close proximity to its use:
  - Abbreviations: up to 4 chars (e.g. `buf`, `len`, `tmp`)
  - Words: up to 6 chars (e.g. `depth`, `result`)
- Struct properties should use short words where possible
- Abbreviations are acceptable if they are idiomatic in C or established in the codebase
