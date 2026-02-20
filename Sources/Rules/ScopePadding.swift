//
//  ScopePadding.swift
//  SwiftFormat
//

import Foundation

public extension FormatRule {
    /// Enforce blank lines at start/end of type bodies, remove them from other scopes.
    static let scopePadding = FormatRule(
        help: "Enforce blank lines at start/end of type bodies, remove them from other scopes.",
        disabledByDefault: true,
        options: ["scope-lines-without-padding"]
    ) { formatter in
        let shortScopeThreshold = formatter.options.scopeLinesWithoutPadding

        formatter.forEach(.startOfScope("{")) { i, _ in
            guard let endOfScope = formatter.endOfScope(at: i) else { return }

            // Skip one-liners (no linebreaks between braces)
            guard formatter.index(of: .linebreak, in: i + 1 ..< endOfScope) != nil else { return }

            // Skip scopes with no actual content (only whitespace/comments)
            guard let firstContent = formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                  firstContent < endOfScope
            else { return }

            // For closures with captures/params, skip to the `in` keyword
            var effectiveStart = i
            if formatter.isStartOfClosure(at: i),
               let inIndex = formatter.index(of: .keyword("in"), in: i + 1 ..< endOfScope),
               formatter.startOfScope(at: inIndex) == i
            {
                effectiveStart = inIndex
            }

            var requireBlankLine = formatter.isStartOfTypeBody(at: i)

            // Check if this type body qualifies as a "short scope"
            if requireBlankLine, shortScopeThreshold > 0 {
                let metrics = formatter.scopeBodyMetrics(from: effectiveStart, to: endOfScope)
                if !metrics.hasBlankLines, metrics.contentLines <= shortScopeThreshold {
                    requireBlankLine = false
                }
            }

            formatter.enforceScopePaddingLeading(scopeStart: i, effectiveStart: effectiveStart, requireBlankLine: requireBlankLine)
            formatter.enforceScopePaddingTrailing(scopeStart: i, effectiveStart: effectiveStart, requireBlankLine: requireBlankLine)
        }
    } examples: {
        """
        Type bodies (struct, class, enum, extension, protocol, actor) get padded
        with exactly one blank line at the start and end:

        ```diff
          struct Foo {
        +
              let bar: Int
        +
          }
        ```

        Function bodies and other scopes have blank lines removed:

        ```diff
          func foo() {
        -
              bar()
        -
          }
        ```

        With `--scope-lines-without-padding 3`, short type bodies skip padding:

        ```diff
          enum Error {
        -
              case networkError
              case timeout
        -
          }
        ```
        """
    }
}

extension Formatter {
    /// Returns the number of non-blank content lines and whether any blank lines
    /// exist between content lines in the scope body (excluding leading/trailing padding).
    func scopeBodyMetrics(from start: Int, to end: Int) -> (contentLines: Int, hasBlankLines: Bool) {
        var contentLines = 0
        var hasBlankLines = false
        var currentLineHasContent = false
        var blankLinesSinceLastContent = 0

        for idx in (start + 1) ..< end {
            let token = tokens[idx]
            if token.isLinebreak {
                if currentLineHasContent {
                    contentLines += 1
                    blankLinesSinceLastContent = 0
                } else if contentLines > 0 {
                    blankLinesSinceLastContent += 1
                }
                currentLineHasContent = false
            } else if !token.isSpaceOrLinebreak {
                if blankLinesSinceLastContent > 0 {
                    hasBlankLines = true
                }
                currentLineHasContent = true
            }
        }

        if currentLineHasContent {
            contentLines += 1
        }

        return (contentLines, hasBlankLines)
    }

    func enforceScopePaddingLeading(scopeStart: Int, effectiveStart: Int, requireBlankLine: Bool) {
        guard let end = endOfScope(at: scopeStart) else { return }
        let range = ClosedRange(effectiveStart + 1 ..< end)
        let current = tokens[range].numberOfLeadingLinebreaks()

        if requireBlankLine {
            if current < 2 {
                addLeadingBlankLineIfNeeded(in: range)
            } else if current > 2 {
                removeLeadingBlankLinesIfPresent(in: range)
                guard let end = endOfScope(at: scopeStart) else { return }
                addLeadingBlankLineIfNeeded(in: ClosedRange(effectiveStart + 1 ..< end))
            }
        } else {
            if current > 1 {
                removeLeadingBlankLinesIfPresent(in: range)
            }
        }
    }

    func enforceScopePaddingTrailing(scopeStart: Int, effectiveStart: Int, requireBlankLine: Bool) {
        guard let end = endOfScope(at: scopeStart) else { return }
        let range = ClosedRange(effectiveStart + 1 ..< end)
        let current = tokens[range].numberOfTrailingLinebreaks()

        if requireBlankLine {
            if current < 2 {
                addTrailingBlankLineIfNeeded(in: range)
            } else if current > 2 {
                removeTrailingBlankLinesIfPresent(in: range)
                guard let end = endOfScope(at: scopeStart) else { return }
                addTrailingBlankLineIfNeeded(in: ClosedRange(effectiveStart + 1 ..< end))
            }
        } else {
            if current > 1 {
                removeTrailingBlankLinesIfPresent(in: range)
            }
        }
    }
}
