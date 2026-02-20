# modifierAfterMultilineBlock

@Metadata {
    @TitleHeading("Rule")
}

Flag modifiers chained after multi-line blocks.

## Overview

This rule detects method or property chains (`.modifier()`) applied directly after a closing brace `}` where the matching opening brace `{` is on a different line. This pattern reduces readability because the modifier visually detaches from the expression it applies to, making it difficult to see the full chain at a glance.

The recommended fix is to extract the block content into a separate computed property or function, so that modifiers can be chained directly on a single-line expression.

> Note: This rule is **lint-only**. It reports violations but does not automatically modify code, because the intended fix may be ambiguous. Use `--lint-only modifierAfterMultilineBlock` in your configuration to enable it only during linting.

## Examples

### Violation

Chaining a modifier after a multi-line trailing closure is flagged:

```swift
var body: some View {
    ScrollViewReader { proxy in
        ScrollView {
            content(proxy: proxy)
        }
    }
    .frame(height: 350)  // violation
}
```

Extract the block content so the modifier chains directly:

```swift
var body: some View {
    scrollView
        .frame(height: 350)
}

private var scrollView: some View {
    ScrollViewReader { proxy in
        ScrollView {
            content(proxy: proxy)
        }
    }
}
```

### One-liner Blocks

Modifiers after single-line blocks are not flagged, since the full expression is visible at a glance:

```swift
Button("OK") { dismiss() }
    .padding()
```

### Modifier Chains Without Braces

Modifiers chained on expressions without braces are not affected:

```swift
SGScreen(as: screenType, title: screenTitle)
    .withAttachedBottomSheet(bottomSheet, isVisible: $showList)
    .allowsHitTesting(!showDialog)
```
