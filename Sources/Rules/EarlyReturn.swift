//
//  EarlyReturn.swift
//  SwiftFormat
//

import Foundation

public extension FormatRule {
    /// Flag return statements that are not inside guard-else bodies or at the end of an allowed scope.
    static let earlyReturn = FormatRule(
        help: "Flag return statements that are not inside guard-else bodies or at the end of an allowed scope.",
        runOnceOnly: true,
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("return")) { returnIndex, _ in
            // Skip returns inside guard-else bodies (at any nesting depth)
            guard !formatter.isInsideGuardElseBody(at: returnIndex) else { return }

            // Find the enclosing scope (`{` for most scopes, `:` for switch case blocks)
            guard let scopeStart = formatter.startOfScope(at: returnIndex),
                  formatter.tokens[scopeStart] == .startOfScope("{") ||
                  formatter.tokens[scopeStart] == .startOfScope(":")
            else { return }

            // Classify the enclosing scope
            let scopeKind = formatter.enclosingReturnScopeKind(at: scopeStart)

            switch scopeKind {
            case .guardElse, .irrelevant:
                return
            case .allowed:
                // Return as the last statement of an allowed scope is OK
                if formatter.isLastReturnStatementInScope(
                    returnIndex: returnIndex, scopeStart: scopeStart
                ) { return }
            case .disallowed:
                break
            }

            // Skip if already marked (idempotency)
            if formatter.hasEarlyReturnMarker(before: returnIndex) { return }

            // For single-line blocks, place marker at end of line to avoid
            // breaking inline blocks and causing cascading braces rule errors
            let isInSingleLineBlock = formatter.tokens[scopeStart] == .startOfScope("{")
                && formatter.endOfScope(at: scopeStart).map { scopeEnd in
                    formatter.index(of: .linebreak, in: scopeStart + 1 ..< scopeEnd) == nil
                } ?? false

            if isInSingleLineBlock {
                formatter.insertEarlyReturnMarkerAtEndOfLine(at: returnIndex)
            } else {
                formatter.insertEarlyReturnMarker(at: returnIndex)
            }
        }
    } examples: {
        """
        Return statements should only appear in `guard ... else { }` bodies or as the
        last statement of a function, closure, computed property, or switch case.

        ```diff
          func process(value: Int?) -> String {
        -     if value != nil {
        -         return "has value"
        -     }
        -     return "no value"
        +     guard let value else { return "no value" }
        +     return "has value: \\(value)"
          }
        ```

        Returns as the last statement of switch cases and closures are allowed:

        ```swift
        // OK:
        func status(for code: Int) -> String {
            switch code {
            case 200:
                return "OK"
            default:
                return "Unknown"
            }
        }

        let result = items.map { item in
            return item.transformed
        }
        ```
        """
    }
}

// MARK: - Helpers

extension Formatter {
    enum ReturnScopeKind {
        /// Inside a `guard ... else { }` body
        case guardElse
        /// Scope where return-as-last-statement is permitted:
        /// function, init, subscript, computed property, getter/setter/willSet/didSet,
        /// closure, switch case/default, do block, catch block
        case allowed
        /// Scope where return is never permitted:
        /// if, else, for, while, repeat
        case disallowed
        /// Scope that we don't check:
        /// type bodies, #if, defer, parens, brackets
        case irrelevant
    }

    /// Classifies the scope starting at `scopeStart` for earlyReturn checking.
    func enclosingReturnScopeKind(at scopeStart: Int) -> ReturnScopeKind {
        // Switch case/default bodies (`:` scope)
        if tokens[scopeStart] == .startOfScope(":") {
            return .allowed
        }

        guard tokens[scopeStart] == .startOfScope("{") else {
            return .irrelevant
        }

        // Check for guard-else body
        if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: scopeStart),
           tokens[prevIndex] == .keyword("else"),
           isGuardElse(at: prevIndex)
        {
            return .guardElse
        }

        // Check for property accessor keywords (identifiers, not keywords)
        if let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: scopeStart),
           case let .identifier(name) = tokens[prevIndex],
           ["get", "set", "willSet", "didSet"].contains(name)
        {
            return .allowed
        }

        // Check for closure
        if isStartOfClosure(at: scopeStart) {
            return .allowed
        }

        // Classify by the last significant keyword before the scope
        guard let keyword = lastSignificantKeyword(at: scopeStart, excluding: ["where", "let", "case"]) else {
            return .irrelevant
        }

        switch keyword {
        case "func", "init", "subscript", "var", "do", "catch":
            return .allowed
        case "if":
            // Allow returns in `if #available(...)` / `if #unavailable(...)` bodies
            if let ifIndex = indexOfLastSignificantKeyword(at: scopeStart, excluding: ["where", "let", "case"]),
               isIfAvailableCheck(ifKeywordIndex: ifIndex)
            {
                return .allowed
            }
            return .disallowed
        case "else":
            // Allow returns in else branches of `if #available` / `if #unavailable`
            if let elseIndex = indexOfLastSignificantKeyword(at: scopeStart, excluding: ["where", "let", "case"]),
               isElseOfIfAvailableCheck(elseKeywordIndex: elseIndex)
            {
                return .allowed
            }
            return .disallowed
        case "for", "while", "repeat":
            return .disallowed
        case "defer":
            return .irrelevant
        default:
            if Token.swiftTypeKeywords.contains(keyword) {
                return .irrelevant
            }
            return .irrelevant
        }
    }

    /// Whether the token at `index` is inside a `guard ... else { }` body
    /// at any nesting depth.
    func isInsideGuardElseBody(at index: Int) -> Bool {
        var i = index
        while let scopeStart = startOfScope(at: i) {
            if tokens[scopeStart] == .startOfScope("{"),
               let prevIndex = self.index(of: .nonSpaceOrCommentOrLinebreak, before: scopeStart),
               tokens[prevIndex] == .keyword("else"),
               isGuardElse(at: prevIndex)
            {
                return true
            }
            i = scopeStart
        }
        return false
    }

    /// Whether the return at `returnIndex` is the last statement in the scope
    /// starting at `scopeStart`.
    func isLastReturnStatementInScope(returnIndex: Int, scopeStart: Int) -> Bool {
        guard var scopeEnd = endOfScope(at: scopeStart) else { return false }

        // If the scope ends at `@unknown default`, the effective boundary is the
        // `@unknown` keyword (which precedes `.endOfScope("default")`).
        if tokens[scopeEnd] == .endOfScope("default"),
           let prevNonSpace = index(of: .nonSpaceOrCommentOrLinebreak, before: scopeEnd),
           tokens[prevNonSpace] == .keyword("@unknown")
        {
            scopeEnd = prevNonSpace
        }

        // Determine if this is a void return (no value expression follows on the same line)
        let isVoidReturn: Bool
        if let nextNonSpace = index(of: .nonSpaceOrComment, after: returnIndex) {
            isVoidReturn = tokens[nextNonSpace].isLinebreak || nextNonSpace >= scopeEnd
        } else {
            isVoidReturn = true
        }

        var returnStatementEnd: Int
        if isVoidReturn {
            returnStatementEnd = returnIndex
        } else {
            // Parse the return value expression
            guard let exprStart = index(of: .nonSpaceOrCommentOrLinebreak, after: returnIndex),
                  let exprRange = parseExpressionRange(
                      startingAt: exprStart,
                      allowConditionalExpressions: true
                  )
            else {
                return false
            }
            returnStatementEnd = exprRange.upperBound

            // Handle `return x = expr` (assignment doesn't form an expression,
            // so parseExpressionRange only captures the LHS)
            if let nextNonSpace = index(of: .nonSpaceOrCommentOrLinebreak, after: returnStatementEnd),
               tokens[nextNonSpace] == .operator("=", .infix),
               let rhsStart = index(of: .nonSpaceOrCommentOrLinebreak, after: nextNonSpace),
               let rhsRange = parseExpressionRange(
                   startingAt: rhsStart,
                   allowConditionalExpressions: true
               )
            {
                returnStatementEnd = rhsRange.upperBound
            }
        }

        // Check that nothing meaningful follows between the return and the scope end
        guard let nextAfterReturn = index(
            of: .nonSpaceOrCommentOrLinebreak, after: returnStatementEnd
        ) else {
            return true
        }
        return nextAfterReturn >= scopeEnd
    }

    /// Whether there is already a `[earlyReturn]` FIXME marker before `index`
    /// or at the end of the line containing `index`.
    func hasEarlyReturnMarker(before index: Int) -> Bool {
        // Check before the return (multi-line block marker)
        if let prevIndex = self.index(of: .nonSpaceOrLinebreak, before: index),
           case let .commentBody(body) = tokens[prevIndex],
           body.contains("[earlyReturn]")
        {
            return true
        }
        // Check at end of line (single-line block marker)
        let lineEnd = endOfLine(at: index)
        if lineEnd > 0,
           let prevIndex = self.index(of: .nonSpaceOrLinebreak, before: lineEnd),
           case let .commentBody(body) = tokens[prevIndex],
           body.contains("[earlyReturn]")
        {
            return true
        }
        return false
    }

    /// Whether the `if` keyword at `ifKeywordIndex` has a condition starting
    /// with `#available` or `#unavailable`.
    func isIfAvailableCheck(ifKeywordIndex: Int) -> Bool {
        guard tokens[ifKeywordIndex] == .keyword("if"),
              let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: ifKeywordIndex),
              case let .keyword(kw) = tokens[nextIndex],
              kw == "#available" || kw == "#unavailable"
        else {
            return false
        }
        return true
    }

    /// Whether the `else` keyword at `elseKeywordIndex` belongs to an
    /// `if #available` / `if #unavailable` chain.
    func isElseOfIfAvailableCheck(elseKeywordIndex: Int) -> Bool {
        guard tokens[elseKeywordIndex] == .keyword("else"),
              let closeBrace = index(of: .nonSpaceOrCommentOrLinebreak, before: elseKeywordIndex),
              tokens[closeBrace] == .endOfScope("}"),
              let openBrace = startOfScope(at: closeBrace)
        else {
            return false
        }
        // Check the keyword for the preceding scope
        guard let keyword = lastSignificantKeyword(at: openBrace, excluding: ["where", "let", "case"]) else {
            return false
        }
        if keyword == "if",
           let ifIndex = indexOfLastSignificantKeyword(at: openBrace, excluding: ["where", "let", "case"])
        {
            return isIfAvailableCheck(ifKeywordIndex: ifIndex)
        }
        // Handle `else if #available` chains
        if keyword == "else",
           let innerElseIndex = indexOfLastSignificantKeyword(at: openBrace, excluding: ["where", "let", "case"])
        {
            return isElseOfIfAvailableCheck(elseKeywordIndex: innerElseIndex)
        }
        return false
    }

    /// Insert a `// FIXME: [earlyReturn]` comment before the token at `index`.
    func insertEarlyReturnMarker(at index: Int) {
        let linebreakToken = linebreakToken(for: index)
        let indent = currentIndentForLine(at: index)
        var tokens: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [earlyReturn] return should be in guard-else or at end of scope"),
            linebreakToken,
        ]
        if !indent.isEmpty {
            tokens.append(.space(indent))
        }
        insert(tokens, at: index)
    }

    /// Insert a `// FIXME: [earlyReturn]` comment at the end of the line containing `index`.
    /// Used for single-line blocks to preserve inline block structure.
    func insertEarlyReturnMarkerAtEndOfLine(at index: Int) {
        let lineEnd = endOfLine(at: index)
        var tokens: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [earlyReturn] return should be in guard-else or at end of scope"),
        ]
        if lineEnd > 0, !self.tokens[lineEnd - 1].isSpace {
            tokens.insert(.space(" "), at: 0)
        }
        insert(tokens, at: lineEnd)
    }
}
