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

## Naming Conventions

- Single-character variable names are never used — they make searching difficult
- Short names are acceptable for small utility functions or localised blocks of code where the definition is in close proximity to its use:
  - Abbreviations: up to 4 chars (e.g. `buf`, `len`, `tmp`)
  - Words: up to 6 chars (e.g. `depth`, `result`)
- Struct properties should use short words where possible
- Abbreviations are acceptable if they are idiomatic in C or established in the codebase
