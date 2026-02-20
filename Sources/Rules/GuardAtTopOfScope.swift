//
//  GuardAtTopOfScope.swift
//  SwiftFormat
//

import Foundation

public extension FormatRule {
    /// Ensure guard statements are only used appropriately within scope bodies.
    static let guardAtTopOfScope = FormatRule(
        help: "Ensure guard statements are only used appropriately within scope bodies.",
        runOnceOnly: true,
        disabledByDefault: true,
        options: ["guard-exceptions"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("guard")) { guardIndex, _ in
            // Find the enclosing scope (`{` for most scopes, `:` for switch case blocks)
            guard let scopeStart = formatter.startOfScope(at: guardIndex),
                  formatter.tokens[scopeStart] == .startOfScope("{") ||
                  formatter.tokens[scopeStart] == .startOfScope(":")
            else { return }

            // Skip type bodies (guards can't appear there)
            guard !formatter.isIgnoredGuardScope(at: scopeStart) else { return }

            // Check if the guard is at the top of the scope
            if formatter.isGuardAtTopOfBody(guardIndex, scopeStart: scopeStart) { return }

            // Skip if already marked (idempotency)
            if formatter.hasGuardAtTopOfScopeMarker(near: guardIndex) { return }

            // For single-line blocks, place marker at end of line to avoid
            // breaking inline blocks and causing cascading braces rule errors
            let isInSingleLineBlock = formatter.tokens[scopeStart] == .startOfScope("{")
                && formatter.endOfScope(at: scopeStart).map { scopeEnd in
                    formatter.index(of: .linebreak, in: scopeStart + 1 ..< scopeEnd) == nil
                } ?? false

            if isInSingleLineBlock {
                formatter.insertGuardAtTopOfScopeMarkerAtEndOfLine(at: guardIndex)
            } else {
                formatter.insertGuardAtTopOfScopeMarker(at: guardIndex)
            }
        }
    } examples: {
        """
        Guards should be at the top of their enclosing scope. Only comments and
        excepted function calls are permitted before or between consecutive guard
        statements.

        ```diff
          func process(value: Int?, flag: Bool) {
              guard let value else { return }
        -     print("doing something")
        -     guard flag else { return }
        +     guard flag else { return }
        +     print("doing something")
              print("all good: \\(value)")
          }
        ```

        Use `--guard-exceptions` to allow specific function calls (e.g. logging)
        before guard statements:

        `--guard-exceptions print`

        ```diff
          func process(value: Int?) {
              print("Processing value")
              guard let value else { return }
              // ...
          }
        ```
        """
    }
}

extension Formatter {
    /// Whether the scope at `scopeStart` should be ignored for guard checking.
    /// Only type bodies are ignored (guards can't meaningfully appear there).
    func isIgnoredGuardScope(at scopeStart: Int) -> Bool {
        guard tokens[scopeStart] == .startOfScope("{") else {
            // `:` scopes (switch case/default) are always checked
            return false
        }
        return isStartOfTypeBody(at: scopeStart)
    }

    /// Returns the index from which the body of the scope begins, skipping past
    /// closure parameter lists (e.g. `{ result in` → returns index of `in`).
    func bodyStartIndex(at scopeStart: Int) -> Int {
        guard tokens[scopeStart] == .startOfScope("{"),
              isStartOfClosure(at: scopeStart),
              let inIndex = index(of: .keyword("in"), after: scopeStart),
              inIndex < (endOfScope(at: scopeStart) ?? tokens.count)
        else { return scopeStart }
        return inIndex
    }

    /// Whether the guard at `guardIndex` is at the top of the body starting at `scopeStart`.
    /// "At the top" means only other guard statements, comments, whitespace, and
    /// calls to excepted functions precede it.
    func isGuardAtTopOfBody(_ guardIndex: Int, scopeStart: Int) -> Bool {
        let exceptions = options.guardAtTopOfScopeExceptions
        var searchIndex = bodyStartIndex(at: scopeStart)
        while searchIndex < guardIndex {
            guard let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: searchIndex) else {
                return true
            }

            if nextIndex >= guardIndex {
                return true
            }

            if tokens[nextIndex] == .keyword("guard") {
                // Skip over this guard statement to its closing brace
                guard let endOfGuard = endOfGuardStatement(at: nextIndex) else {
                    return false
                }
                searchIndex = endOfGuard
            } else if let endOfCall = endOfExceptedFunctionCall(at: nextIndex, exceptions: exceptions) {
                searchIndex = endOfCall
            } else {
                return false
            }
        }
        return true
    }

    /// If the token at `index` starts a call to an excepted function, returns
    /// the index of the last token in that statement. Returns nil otherwise.
    func endOfExceptedFunctionCall(at index: Int, exceptions: Set<String>) -> Int? {
        guard !exceptions.isEmpty,
              case let .identifier(name) = tokens[index],
              exceptions.contains(name),
              let parenStart = self.index(of: .nonSpaceOrCommentOrLinebreak, after: index),
              tokens[parenStart] == .startOfScope("("),
              let parenEnd = endOfScope(at: parenStart)
        else { return nil }

        // Check there's nothing else on the line after the closing paren
        // (other than a trailing closure which is part of the same call)
        let endOfLine = endOfLine(at: parenEnd)
        let nextNonSpace = self.index(of: .nonSpaceOrCommentOrLinebreak, after: parenEnd)
        if let nextNonSpace, nextNonSpace < endOfLine,
           tokens[nextNonSpace] != .startOfScope("{")
        {
            return nil
        }

        // If there's a trailing closure, skip past it
        if let nextNonSpace, nextNonSpace < endOfLine,
           tokens[nextNonSpace] == .startOfScope("{"),
           let closureEnd = endOfScope(at: nextNonSpace)
        {
            return closureEnd
        }

        return parenEnd
    }

    /// Finds the closing `}` of a guard statement starting at the given index.
    func endOfGuardStatement(at guardIndex: Int) -> Int? {
        guard tokens[guardIndex] == .keyword("guard") else { return nil }

        // Find the else keyword
        guard var elseIndex = index(of: .keyword("else"), after: guardIndex) else {
            return nil
        }

        // Handle cases where the `else` is part of an if-else within the guard condition
        if !isGuardElse(at: elseIndex) {
            guard let nextElse = index(of: .keyword("else"), after: elseIndex) else {
                return nil
            }
            elseIndex = nextElse
        }

        // Find the else block's closing brace
        guard let elseBodyStart = index(of: .startOfScope("{"), after: elseIndex),
              let elseBodyEnd = endOfScope(at: elseBodyStart)
        else {
            return nil
        }

        return elseBodyEnd
    }

    /// Whether there is already a `[guardAtTopOfScope]` FIXME marker near `index`
    /// (either before the guard or at end of line).
    func hasGuardAtTopOfScopeMarker(near index: Int) -> Bool {
        // Check before the guard (multi-line block marker)
        if let prevIndex = self.index(of: .nonSpaceOrLinebreak, before: index),
           case let .commentBody(body) = tokens[prevIndex],
           body.contains("[guardAtTopOfScope]")
        {
            return true
        }
        // Check at end of line (single-line block marker)
        let lineEnd = endOfLine(at: index)
        if lineEnd > 0,
           let prevIndex = self.index(of: .nonSpaceOrLinebreak, before: lineEnd),
           case let .commentBody(body) = tokens[prevIndex],
           body.contains("[guardAtTopOfScope]")
        {
            return true
        }
        return false
    }

    /// Insert a `// FIXME: [guardAtTopOfScope]` comment before the token at `index`.
    func insertGuardAtTopOfScopeMarker(at index: Int) {
        let linebreakToken = linebreakToken(for: index)
        let indent = currentIndentForLine(at: index)
        var tokens: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [guardAtTopOfScope] guard should be at top of scope"),
            linebreakToken,
        ]
        if !indent.isEmpty {
            tokens.append(.space(indent))
        }
        insert(tokens, at: index)
    }

    /// Insert a `// FIXME: [guardAtTopOfScope]` comment at the end of the line containing `index`.
    /// Used for single-line blocks to preserve inline block structure.
    func insertGuardAtTopOfScopeMarkerAtEndOfLine(at index: Int) {
        let lineEnd = endOfLine(at: index)
        var tokens: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [guardAtTopOfScope] guard should be at top of scope"),
        ]
        if lineEnd > 0, !self.tokens[lineEnd - 1].isSpace {
            tokens.insert(.space(" "), at: 0)
        }
        insert(tokens, at: lineEnd)
    }
}
