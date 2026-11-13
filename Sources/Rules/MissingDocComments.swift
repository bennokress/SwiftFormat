//
//  MissingDocComments.swift
//  SwiftFormat
//
//  Created by Benno Kress on 2026-11-13.
//

import Foundation

public extension FormatRule {
    /// Flag non-private declarations without a doc comment, and functions whose doc comment
    /// lacks a section for their parameters, return value or errors.
    static let missingDocComments = FormatRule(
        help: "Require doc comments on non-private declarations, with Parameter, Returns and Throws sections where they apply.",
        runOnceOnly: true,
        disabledByDefault: true,
        options: ["doc-exempt-names", "doc-exempt-attributes", "doc-exempt-conformances"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        var findings: [(declaration: Declaration, problem: String)] = []
        formatter.parseDeclarations().forEachRecursiveDeclaration { declaration in
            guard formatter.requiresDocComment(declaration),
                  let problem = formatter.docCommentProblem(of: declaration)
            else { return }
            findings.append((declaration, problem))
        }

        // Insert from the bottom up, so earlier insertions don't shift later declarations.
        for (declaration, problem) in findings.reversed() {
            let index = declaration.startOfModifiersIndex(includingAttributes: true)
            guard !formatter.hasMissingDocCommentsMarker(before: index) else { continue }
            formatter.insertMissingDocCommentsMarker(problem, at: index)
        }
    } examples: {
        """
        Every declaration that other files can see carries a doc comment. A function
        documents each of its parameters, its return value and the errors it throws.

        ```diff
        - func total(of items: [Item]) throws -> Int {
        + /// The sum of all item prices.
        + ///
        + /// - Parameter items: The items to add up.
        + /// - Returns: The total in cents.
        + /// - Throws: `PriceError` if an item has no price.
        + func total(of items: [Item]) throws -> Int {
        ```

        Private and fileprivate declarations, `override`s, a parameterless `init()`,
        and the names, property attributes and conformances in `--doc-exempt-names`,
        `--doc-exempt-attributes` and `--doc-exempt-conformances` are exempt.
        """
    }
}

extension Formatter {
    /// The declaration keywords this rule checks. Extensions, enum cases and `#if` blocks need no doc comment.
    static let missingDocCommentsKeywords: Set<String> = [
        "actor", "class", "enum", "func", "init", "let", "protocol", "struct", "subscript", "typealias", "var",
    ]

    /// Whether `declaration` is visible outside its file and not covered by an exemption.
    func requiresDocComment(_ declaration: Declaration) -> Bool {
        guard Formatter.missingDocCommentsKeywords.contains(declaration.keyword) else { return false }

        let hidden: Set<Visibility> = [.private, .fileprivate]
        let chain = declaration.parentDeclarations + [declaration]
        if chain.contains(where: { $0.visibility().map(hidden.contains) ?? false }) {
            return false
        }

        if declaration.hasModifier("override") {
            return false
        }
        if let name = declaration.name, options.missingDocCommentsExemptNames.contains(name) {
            return false
        }

        if declaration.keyword == "init",
           let function = parseFunctionDeclaration(keywordIndex: declaration.keywordIndex),
           function.arguments.isEmpty
        {
            return false
        }

        if declaration.keyword == "var" || declaration.keyword == "let" {
            // `@Environment(\.dismiss)` arrives with its arguments; only the name counts.
            let attributes = declaration.attributes.map { $0.dropFirst().prefix { $0 != "(" } }.map(String.init)
            if attributes.contains(where: options.missingDocCommentsExemptAttributes.contains) {
                return false
            }

            let conformances = declaration.parentType?.conformances.map(\.conformance.string) ?? []
            if conformances.contains(where: options.missingDocCommentsExemptConformances.contains) {
                return false
            }
        }

        return true
    }

    /// A short description of what is missing from the doc comment of `declaration`, or `nil` if nothing is.
    func docCommentProblem(of declaration: Declaration) -> String? {
        guard let commentRange = declaration.docCommentRange,
              commentRange.contains(where: { isDocComment(startOfComment: $0) })
        else { return "missing doc comment" }

        guard ["func", "init", "subscript"].contains(declaration.keyword),
              let function = parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
        else { return nil }

        let text = tokens[commentRange].filter(\.isCommentBody).map(\.string).joined(separator: "\n").lowercased()
        var missing: [String] = []

        if !function.arguments.isEmpty, !text.contains("- parameter") {
            missing.append("- Parameter")
        }
        if let returnType = function.returnType?.string, !["Void", "()"].contains(returnType), !text.contains("- returns:") {
            missing.append("- Returns")
        }
        if !function.effects.isDisjoint(with: ["throws", "rethrows"]), !text.contains("- throws:") {
            missing.append("- Throws")
        }

        return missing.isEmpty ? nil : "doc comment lacks " + missing.joined(separator: ", ")
    }

    /// Whether a `[missingDocComments]` marker already sits on the line before `index`.
    func hasMissingDocCommentsMarker(before index: Int) -> Bool {
        guard let previousIndex = self.index(of: .nonSpaceOrLinebreak, before: index),
              case let .commentBody(body) = tokens[previousIndex]
        else { return false }
        return body.contains("[missingDocComments]")
    }

    /// Insert a `// FIXME: [missingDocComments]` comment on its own line before the token at `index`.
    func insertMissingDocCommentsMarker(_ problem: String, at index: Int) {
        var marker: [Token] = [
            .startOfScope("//"),
            .space(" "),
            .commentBody("FIXME: [missingDocComments] \(problem)"),
            linebreakToken(for: index),
        ]
        let indent = currentIndentForLine(at: index)
        if !indent.isEmpty {
            marker.append(.space(indent))
        }
        insert(marker, at: index)
    }
}
