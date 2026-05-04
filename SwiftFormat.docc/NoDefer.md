# noDefer

@Metadata {
    @TitleHeading("Rule")
}

Flag defer statements; prefer explicit cleanup at every exit point.

## Overview

This rule flags every `defer` statement as a violation. `defer` hides cleanup logic at the bottom of the enclosing scope and interacts poorly with <doc:GuardAtTopOfScope>, since registering the cleanup counts as non-guard code at the top of the scope.

Preferred alternatives:

1. For short bodies, repeat the cleanup call before every exit point.
2. For longer bodies, extract the cleanup into a helper function and call it at each exit point.

> Note: This rule is **lint-only**. It reports violations but does not automatically modify code, because the intended fix requires restructuring control flow. Use `--lint-only noDefer` in your configuration to enable it only during linting. In format mode, the rule would instead insert `// FIXME: [noDefer]` comments (placed at the end of the line for single-line blocks, to preserve inline block structure).

## Examples

### Violation: defer for lock cleanup

```swift
func loadData() throws -> Data {
    lock.lock()
    defer { lock.unlock() }  // violation
    guard let data = try? read() else { throw Error.missing }
    return data
}
```

Rewrite with explicit cleanup at every exit point:

```swift
func loadData() throws -> Data {
    lock.lock()
    guard let data = try? read() else {
        lock.unlock()
        throw Error.missing
    }
    lock.unlock()
    return data
}
```

### Longer bodies: extract a helper

When the cleanup involves multiple statements or there are many exit points, extract it into a helper function instead of repeating the statements inline:

```swift
func process() {
    startSpinner()
    guard validate() else {
        finish()
        return
    }
    doWork()
    finish()
}

private func finish() {
    stopSpinner()
    logCompletion()
}
```
