//
//  NoDefer.swift
//  SwiftFormat
//
//  Created by Benno Kress on 2026-05-04.
//

import Foundation

public extension FormatRule {
    /// Flag every `defer` statement as a manual-fix violation.
    static let noDefer = FormatRule(
        help: "Flag defer statements; prefer explicit cleanup at every exit point.",
        runOnceOnly: true,
        disabledByDefault: true,
        sharedOptions: ["linebreaks"]
    ) { formatter in
        formatter.forEach(.keyword("defer")) { deferIndex, _ in
            // Skip if already marked (idempotency)
            if formatter.hasNoDeferMarker(near: deferIndex) { return }

            // For single-line enclosing blocks, place marker at end of line
            // to avoid breaking inline blocks (mirrors guardAtTopOfScope).
            let isInSingleLineBlock: Bool = {
                guard let scopeStart = formatter.startOfScope(at: deferIndex),
                      formatter.tokens[scopeStart] == .startOfScope("{"),
                      let scopeEnd = formatter.endOfScope(at: scopeStart)
                else { return false }
                return formatter.index(of: .linebreak, in: scopeStart + 1 ..< scopeEnd) == nil
            }()

            if isInSingleLineBlock {
                formatter.insertNoDeferMarkerAtEndOfLine(at: deferIndex)
            } else {
                formatter.insertNoDeferMarker(at: deferIndex)
            }
        }
    } examples: {
        """
        `defer` hides cleanup at the bottom of the scope and interacts poorly with
        `guardAtTopOfScope`. For short bodies, repeat the call at every exit point;
        for longer bodies, extract a helper and call it at each exit point.

        ```diff
          func loadData() throws -> Data {
        -     lock.lock()
        -     defer { lock.unlock() }
        -     guard let data = try? read() else { throw Error.missing }
        -     return data
        +     lock.lock()
        +     guard let data = try? read() else {
        +         lock.unlock()
        +         throw Error.missing
        +     }
        +     lock.unlock()
        +     return data
          }
        ```
        """
    }
}

extension Formatter {
    /// Whether there is already a `[noDefer]` FIXME marker near `index`
    /// (either before the defer or at end of line).
    func hasNoDeferMarker(near index: Int) -> Bool {
        if let prevIndex = self.index(of: .nonSpaceOrLinebreak, before: index),
           case let .commentBody(body) = tokens[prevIndex],
           body.contains("[noDefer]")
        {
            return true
        }
        let lineEnd = endOfLine(at: index)
        if lineEnd > 0,
           let prevIndex = self.index(of: .nonSpaceOrLinebreak, before: lineEnd),
           case let .commentBody(body) = tokens[prevIndex],
           body.contains("[noDefer]")
        {
            return true
        }
        return false
    }

    /// Insert a `// FIXME: [noDefer]` comment before the token at `index`.
    func insertNoDeferMarker(at index: Int) {
        let linebreakToken = linebreakToken(for: index)
        let indent = currentIndentForLine(at: index)
        var tokens: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies"),
            linebreakToken,
        ]
        if !indent.isEmpty {
            tokens.append(.space(indent))
        }
        insert(tokens, at: index)
    }

    /// Insert a `// FIXME: [noDefer]` comment at the end of the line containing `index`.
    /// Used for single-line blocks to preserve inline block structure.
    func insertNoDeferMarkerAtEndOfLine(at index: Int) {
        let lineEnd = endOfLine(at: index)
        var tokens: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies"),
        ]
        if lineEnd > 0, !self.tokens[lineEnd - 1].isSpace {
            tokens.insert(.space(" "), at: 0)
        }
        insert(tokens, at: lineEnd)
    }
}
