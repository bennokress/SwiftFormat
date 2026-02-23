# earlyReturn

@Metadata {
    @TitleHeading("Rule")
}

Flag return statements that are not inside guard-else bodies or at the end of an allowed scope.

## Overview

This rule enforces a coding style where `return` statements only appear in two places:

1. Inside `guard ... else { }` bodies — the idiomatic Swift way to handle preconditions
2. As the **last statement** of a scope body — function, closure, computed property, switch case, etc.

Any other `return` (e.g., inside `if`/`else` bodies, loops, or in the middle of a function) is flagged as a violation. This encourages linear code flow: guards handle preconditions at the top, and a single return at the bottom produces the result.

**Allowed scopes** (return as last statement is OK):
- Function, `init`, `subscript` bodies
- Computed property bodies, getter/setter/willSet/didSet
- Closures
- Switch `case`/`default` arms
- `do` and `catch` blocks

**Disallowed scopes** (return is never OK):
- `if` and `else` bodies
- `for`, `while`, and `repeat` loop bodies

> Note: This rule is **lint-only**. It reports violations but does not automatically modify code, because the intended fix may be ambiguous. Use `--lint-only earlyReturn` in your configuration to enable it only during linting.

> Warning: `#if` blocks are not checked. Returns inside conditional compilation blocks are ignored.

## Examples

### Violation — return inside if body

```swift
func process(value: Int?) -> String {
    if value != nil {
        return "has value"  // violation
    }
    return "no value"
}
```

Rewrite using guard:

```swift
func process(value: Int?) -> String {
    guard let value else { return "no value" }
    return "has value: \(value)"
}
```

### Allowed — return in switch case

Each case arm is an allowed scope, so returning as the last statement of a case is fine:

```swift
func status(for code: Int) -> String {
    switch code {
    case 200:
        return "OK"
    case 404:
        return "Not Found"
    default:
        return "Unknown"
    }
}
```

### Allowed — return in closure

The immediate enclosing scope is the closure, not any outer loop or conditional:

```swift
let results = items.map { item in
    return item.transformed
}
```
