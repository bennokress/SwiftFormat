//
//  ModifierAfterMultilineBlock.swift
//  SwiftFormat
//

import Foundation

public extension FormatRule {
    /// Flag modifiers chained after multi-line blocks.
    static let modifierAfterMultilineBlock = FormatRule(
        help: "Flag modifiers chained after multi-line blocks.",
        runOnceOnly: true,
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.operator(".", .infix)) { dotIndex, _ in
            // Find the previous meaningful token
            guard let prevIndex = formatter.index(of: .nonSpaceOrCommentOrLinebreak, before: dotIndex),
                  formatter.tokens[prevIndex] == .endOfScope("}")
            else { return }

            // Find the matching opening brace
            guard let openBrace = formatter.startOfScope(at: prevIndex) else { return }

            // Skip one-liners (opening and closing brace on the same line)
            guard !formatter.onSameLine(openBrace, prevIndex) else { return }

            // Skip if already marked (idempotency)
            if formatter.hasModifierAfterMultilineBlockMarker(between: prevIndex, and: dotIndex) { return }

            // Violation — insert a FIXME comment
            formatter.insertModifierAfterMultilineBlockMarker(at: dotIndex, closeBrace: prevIndex)
        }
    } examples: {
        """
        Chaining modifiers after multi-line blocks reduces readability. Extract the
        block content so that modifiers can be chained directly on a single-line
        expression instead.

        ```diff
        - Button("Jump to #8") {
        -     value.scrollTo(8)
        - }
        - .padding()
        + Button("Jump to #8", action: scrollToEight)
        +     .padding()
        ```
        """
    }
}

extension Formatter {
    /// Whether a FIXME marker for `modifierAfterMultilineBlock` already exists
    /// between the closing brace and the dot operator.
    func hasModifierAfterMultilineBlockMarker(between closeBrace: Int, and dotIndex: Int) -> Bool {
        for idx in closeBrace ... dotIndex {
            if case let .commentBody(body) = tokens[idx],
               body.contains("[modifierAfterMultilineBlock]")
            {
                return true
            }
        }
        return false
    }

    /// Inserts a `// FIXME:` comment before the dot operator to flag the violation.
    func insertModifierAfterMultilineBlockMarker(at dotIndex: Int, closeBrace: Int) {
        let linebreakToken = linebreakToken(for: dotIndex)
        let indent = currentIndentForLine(at: dotIndex)

        var insertionTokens: [Token] = []

        // If the dot is on the same line as }, insert a linebreak first
        if onSameLine(closeBrace, dotIndex) {
            insertionTokens.append(linebreakToken)
            if !indent.isEmpty {
                insertionTokens.append(.space(indent))
            }
        }

        insertionTokens.append(contentsOf: [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [modifierAfterMultilineBlock] consider extracting the block content to improve readability"),
            linebreakToken,
        ])
        if !indent.isEmpty {
            insertionTokens.append(.space(indent))
        }

        insert(insertionTokens, at: dotIndex)
    }
}
