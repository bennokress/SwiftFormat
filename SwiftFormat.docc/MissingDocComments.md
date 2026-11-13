# missingDocComments

@Metadata {
    @TitleHeading("Rule")
}

Require doc comments on non-private declarations, with Parameter, Returns and Throws sections where they apply.

## Overview

Every declaration that other files can see carries a `///` doc comment. A function, `init` or `subscript` also documents each parameter (`- Parameter` or `- Parameters:`), its return value (`- Returns:`) unless it returns `Void`, and the errors it throws (`- Throws:`).

The rule checks `actor`, `class`, `enum`, `func`, `init`, `let`, `protocol`, `struct`, `subscript`, `typealias` and `var` declarations at file and type level. These are exempt:

- `private` and `fileprivate` declarations, and everything inside a `private` or `fileprivate` type or extension
- extensions, enum cases and `#if` blocks
- `override`s and a parameterless `init()`
- the names in `--doc-exempt-names`
- properties with an attribute in `--doc-exempt-attributes`
- properties of a type that declares a conformance in `--doc-exempt-conformances`

> Note: This rule is **lint-only**. It reports violations but does not automatically modify code, because only a person can write the documentation. Use `--lint-only missingDocComments` in your configuration to enable it only during linting. In format mode, the rule would instead insert `// FIXME: [missingDocComments]` comments before each declaration.

## Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `--doc-exempt-names` | Declaration names that need no doc comment. | `body,perform,typeDisplayRepresentation` |
| `--doc-exempt-attributes` | Property attributes, without `@`, whose properties need no doc comment. | `State,Environment,FocusState,Namespace,Parameter` |
| `--doc-exempt-conformances` | Protocols whose conforming types need no doc comments on their properties. | `AppIntent` |

## Limitations

> Important: The rule sees syntax, not types. It cannot tell whether a method fulfils a protocol requirement, so protocol methods other than those in `--doc-exempt-names` are flagged. A conformance counts only when the type or extension declares it directly. A parameter section is only checked for presence, not for every parameter name.

## Examples

### Missing doc comment

```swift
func reset() {}  // violation: missing doc comment
```

### Missing sections

```swift
/// Adds up the prices.
func total(of items: [Item]) throws -> Int  // violation: lacks - Parameter, - Returns, - Throws
```

### Already Conforming Code

```swift
/// Adds up the prices.
///
/// - Parameter items: The items to add up.
/// - Returns: The total in cents.
/// - Throws: `PriceError` if an item has no price.
func total(of items: [Item]) throws -> Int
```
