//
//  CustomDefaultExclusions.swift
//  SwiftFormat
//
//  Created by Benno Kress on 2026-03-04.
//

@testable import SwiftFormat

/// Custom fork rules excluded from the "all rules" test pass.
/// Add new custom rules here instead of modifying `defaultExclusions`
/// in `XCTestCase+testFormatting.swift` to avoid upstream rebase conflicts.
enum CustomDefaultExclusions {
    static let rules: [FormatRule] = [
        .guardAtTopOfScope,
        .scopePadding,
        .modifierAfterMultilineBlock,
    ]
}
