# Custom SwiftFormat Rules

@Metadata {
    @TitleHeading("Documentation")
}

Formatting rules added to this SwiftFormat fork on top of the upstream [nicklockwood/SwiftFormat](https://github.com/nicklockwood/SwiftFormat) rules.

## Overview

This documentation catalogs all custom formatting rules maintained in this fork of SwiftFormat. Each rule includes a description of the formatting it enforces, usage examples showing before/after transformations, and any known limitations.

> Tip: All custom rules follow the same implementation patterns as upstream SwiftFormat rules. They integrate seamlessly with existing configuration and can be enabled or disabled individually.

## Configuration

Custom rules are disabled by default. To activate them, add the following to your `.swiftformat` configuration file:

### Lint-only rules

These rules report violations but do not automatically fix code. When SwiftFormat is run with the `--lint` option, they produce warnings for each violation. In default (format) mode, they would only insert `// FIXME:` comments to mark violations — which is why we recommend using `--lint-only` to restrict them to lint passes.

```
# Custom Rules (lint-only)
--lint-only guardAtTopOfScope
--lint-only modifierAfterMultilineBlock
--lint-only earlyReturn
--lint-only noDefer
```

### Rules with autofix

These rules detect violations and automatically fix them. Use `--enable` so they apply corrections in both format and lint mode.

```
# Custom Rules (autofix)
--enable scopePadding
--scope-lines-without-padding 3
```

## Topics

### Rules

- <doc:GuardAtTopOfScope>
- <doc:ModifierAfterMultilineBlock>
- <doc:EarlyReturn>
- <doc:ScopePadding>
- <doc:NoDefer>
