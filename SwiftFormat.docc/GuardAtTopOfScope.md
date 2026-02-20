# guardAtTopOfScope

@Metadata {
    @TitleHeading("Rule")
}

Ensure guard statements are only used appropriately within scope bodies.

## Overview

This rule enforces that `guard` statements are placed at the very beginning of their enclosing scope body. Guards are a precondition mechanism and should appear before any other logic. Consecutive guard statements are allowed, and comments between guards are permitted.

The rule checks all scope types:
- Function bodies (`func`, `init`, `subscript`)
- Computed property bodies (implicit getters and explicit `get`/`set` accessors)
- Closures (including completion handlers)
- `do`, `catch`, `case`, and `for` blocks
- `if`, `while`, `defer`, `else`, `repeat`, and `switch` blocks

Type bodies (`class`, `struct`, `enum`, `protocol`, `extension`, `actor`) are not checked.

> Note: This rule is **lint-only**. It reports violations but does not automatically modify code, because the intended fix may be ambiguous. Use `--lint-only guardAtTopOfScope` in your configuration to enable it only during linting.

## Options

### `--guard-exceptions`

A comma-separated list of function names that are allowed to appear before guard statements. This is useful for logging or tracing calls that conventionally precede precondition checks.

```
--guard-exceptions print
```

With this configuration, calls to `print` are ignored when determining whether a guard is at the top of the scope:

```swift
// No violation — print is in the exceptions list:
func foo() {
    print("This is okay.")
    guard isTested else { return }
    bar()
    // ...
}
```

Only the listed function names are excepted. Other statements between an excepted call and a guard are still flagged:

```swift
// Still a violation — bar() is not in the exceptions list:
func foo() {
    print("This is not okay.")
    bar()
    guard isTested else { return }  // violation
    // ...
}
```

If `--guard-exceptions` is not set, all non-guard, non-comment code before a guard is considered a violation (the default behavior).

## Examples

### Functions and Closures

Guards at the top of the scope are valid:

```swift
func process(value: Int?, flag: Bool) {
    guard let value else { return }
    guard flag else { return }
    print("all good: \(value)")
}

fetchData { result in
    guard case let .success(data) = result else { return }
    process(data)
}
```

Guards after non-guard code are flagged:

```swift
func process(value: Int?, flag: Bool) {
    guard let value else { return }
    print("doing something")
    guard flag else { return }  // violation: guard after code
    print("all good")
}
```

### Control Flow and Other Scopes

All scope types follow the same rules — guards at the top are valid, guards after code are flagged:

```swift
// Valid:
if condition {
    guard value != nil else { return }
    doWork()
}

do {
    guard condition else { return }
    try something()
}

// Violation:
for item in items {
    print("processing")
    guard let item else { continue }  // violation: guard after code
}
```
