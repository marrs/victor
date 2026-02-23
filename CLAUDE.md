# Development Workflow

## BDD Feature Development

All new features follow a 3-stage workflow:

1. **Spec descriptions** — Write test descriptions with empty bodies. Wait for user approval before proceeding.
2. **Spec bodies** — Write the test implementations. Wait for user approval before proceeding.
3. **Implementation** — Write code until all tests pass.

Do not edit tests after they have been approved without explicitly asking the user for permission first.

## C++ Style

The codebase is written in a C-style subset of C++:

- No RAII
- No constructor functions or destructors for resource management
- No dynamic dispatch — do not use `virtual`
- Inheritance is permitted for shared fields and compile-time type relationships (no vtables)
- Function signature overloading is used heavily
- No templates
- No features that negatively impact compilation time
