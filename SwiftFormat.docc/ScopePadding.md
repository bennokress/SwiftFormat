# scopePadding

@Metadata {
    @TitleHeading("Rule")
}

Enforce blank lines at the start and end of type bodies, and remove them from other scopes.

## Overview

This rule enforces consistent blank line padding inside scope bodies based on the scope type:

- **Type bodies** (`struct`, `class`, `enum`, `extension`, `protocol`, `actor`) must have exactly one blank line after the opening brace and before the closing brace.
- **All other scopes** (`func`, computed properties, closures, `if`, `guard`, `switch`, `do`, `for`, etc.) must not have blank lines at the start or end of the scope.

One-liner scopes (where the entire body is on the same line as the braces) and empty scopes are left unchanged.

> Tip: This rule supports **autofix**. Running SwiftFormat will automatically apply the formatting changes described below.

## Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `--scope-lines-without-padding` | Max content lines in a type body to skip padding. Type bodies with this many lines or fewer (and no internal blank lines) are left without padding. `0` disables short-scope detection. | `0` |

## Limitations

> Warning: This rule conflicts with the built-in `blankLinesAtStartOfScope` and `blankLinesAtEndOfScope` rules. When enabling `scopePadding`, you should disable or exclude those rules to avoid contradictory formatting.

## Examples

### Type Bodies Get Padded

The rule adds blank lines at the start and end of type bodies:

```swift
// Before:
struct Manager {
    let name = "Manager"
    func process(data: Data?) {
        guard let data else { return }
        handle(data)
    }
    func cleanup() {
        reset()
    }
}

// After:
struct Manager {

    let name = "Manager"
    func process(data: Data?) {
        guard let data else { return }
        handle(data)
    }
    func cleanup() {
        reset()
    }

}
```

### Short Type Bodies Skip Padding

With `--scope-lines-without-padding 2`, type bodies with two or fewer content lines (and no internal blank lines) are left without padding:

```swift
// Left unchanged:
struct NotificationData: Codable {
    let actionType: ActionType
    let consentID: String?
}
// Before:
func process(data: Data?) {

    guard let data else { return }
    handle(data)

}

// After:
func process(data: Data?) {
    guard let data else { return }
    handle(data)
}
```

### One-Liners Are Preserved

Scopes that fit on a single line are left unchanged:

```swift
func toggle() { isEnabled.toggle() }
guard let value else { return }
let doubled = items.map { $0 * 2 }
```
