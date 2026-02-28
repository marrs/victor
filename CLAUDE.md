# Development Workflow

## BDD Feature Development

All new features follow a 3-stage workflow:

1. **Spec descriptions** — Write test descriptions with empty bodies. Wait for user approval before proceeding.
2. **Spec bodies** — Write the test implementations and stubs for any new functions under test (so tests fail rather than crash). Wait for user approval before proceeding.
3. **Implementation** — Write code until all tests pass.

Do not edit tests after they have been approved without explicitly asking the user for permission first.

## BDD for Pure Renames

When renaming a module, tag, or function (no new behaviour), the workflow compresses to two rounds with a content-then-rename split:

1. **Content changes** — Edit spec files in place: update all references (local names, function calls, tag literals, require path) to use the new name, but keep the require path pointing at the existing source file so the module still loads. Tests should fail (the source still uses the old name). Wait for user to confirm the diff.
2. **Source update** — Update the source file to use the new name. Tests pass.
3. **File renames** — `git mv` all affected files (source, spec, test assets). Update the require path in the spec and any Makefile targets. Tests still pass.

Key points:
- Never rename files and change content simultaneously — git loses the rename detection and diffs become unreadable.
- The intermediate failing state (after step 1) should produce failing tests, not crashes. The test framework (`src/fennel/test.fnl`) wraps each `deftest` body in `pcall` so uncaught Lua errors are reported as individual test failures rather than aborting the run.

## Build Process

The user builds the code and pastes any errors. Do not run the build yourself.

If the output shows a crash (process aborted, unhandled exception, Lua error propagating to C++, etc.) rather than test failures, identify the root cause, explain it clearly, and ask how to proceed. Do not attempt to fix a crash by modifying source files without that conversation.

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

## Fennel Test Runs Must Never Crash

A Fennel spec run should always produce test output (pass/fail counts). Crashes — where the process aborts before printing results — are bugs to be fixed, not accepted states. The `deftest` macro wraps each test body in `pcall` so that uncaught Lua errors are caught and reported as failures rather than aborting the run. If a spec run crashes instead of reporting failures, identify and fix the root cause before continuing.

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

**Renderers** (`bic.render`, etc.) return a 2-element tuple:
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
