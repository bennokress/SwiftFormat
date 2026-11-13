//
//  MissingDocCommentsTests.swift
//  SwiftFormatTests
//
//  Created by Benno Kress on 2026-11-13.
//

import XCTest
@testable import SwiftFormat

final class MissingDocCommentsTests: XCTestCase {
    // Violations

    func testFlagsUndocumentedTypeAndMembers() {
        let input = """
        struct Store {
            var items: [Item]

            func reset() {}
        }
        """
        let output = """
        // FIXME: [missingDocComments] missing doc comment
        struct Store {
            // FIXME: [missingDocComments] missing doc comment
            var items: [Item]

            // FIXME: [missingDocComments] missing doc comment
            func reset() {}
        }
        """
        testFormatting(for: input, output, rule: .missingDocComments)
    }

    func testFlagsMissingSections() {
        let input = """
        /// Adds up the prices.
        func total(of items: [Item]) throws -> Int {
            0
        }
        """
        let output = """
        /// Adds up the prices.
        // FIXME: [missingDocComments] doc comment lacks - Parameter, - Returns, - Throws
        func total(of items: [Item]) throws -> Int {
            0
        }
        """
        testFormatting(for: input, output, rule: .missingDocComments, exclude: [.unusedArguments])
    }

    func testRegularCommentIsNotADocComment() {
        let input = """
        // Adds up the prices.
        let total = 0
        """
        let output = """
        // Adds up the prices.
        // FIXME: [missingDocComments] missing doc comment
        let total = 0
        """
        testFormatting(for: input, output, rule: .missingDocComments, exclude: [.docComments])
    }

    func testFlagsInitWithParameters() {
        let input = """
        /// A store.
        public struct Store {
            public init(items: [Item]) {}
        }
        """
        let output = """
        /// A store.
        public struct Store {
            // FIXME: [missingDocComments] missing doc comment
            public init(items: [Item]) {}
        }
        """
        testFormatting(for: input, output, rule: .missingDocComments, exclude: [.unusedArguments])
    }

    // No violations

    func testCompleteDocCommentIsAccepted() {
        let input = """
        /// Adds up the prices.
        ///
        /// - Parameters:
        ///   - items: The items to add up.
        ///   - discount: The discount in percent.
        /// - Returns: The total in cents.
        /// - Throws: `PriceError` if an item has no price.
        func total(of items: [Item], discount: Int) throws -> Int {
            0
        }
        """
        testFormatting(for: input, rule: .missingDocComments, exclude: [.unusedArguments])
    }

    func testVoidFunctionNeedsNoReturns() {
        let input = """
        /// Clears the store.
        func reset() -> Void {}
        """
        testFormatting(for: input, rule: .missingDocComments, exclude: [.redundantVoidReturnType])
    }

    func testPrivateDeclarationsAreExempt() {
        let input = """
        private struct Cache {
            var entries: [String] = []
        }

        /// A view model.
        final class Model {
            private var count = 0
            fileprivate func bump() {}
        }

        private extension Model {
            func helper() {}
        }
        """
        testFormatting(for: input, rule: .missingDocComments)
    }

    func testExtensionsEnumCasesAndOverridesAreExempt() {
        let input = """
        /// A direction.
        enum Direction {
            case up
            case down
        }

        extension Direction: Codable {}

        /// A screen.
        final class Screen: UIViewController {
            override func viewDidLoad() {}
        }
        """
        testFormatting(for: input, rule: .missingDocComments)
    }

    func testDefaultExemptionsAreApplied() {
        let input = """
        /// A list of items.
        struct ItemList: View {
            @State var selection: Item?
            @Environment(\\.dismiss) var dismiss

            var body: some View {
                EmptyView()
            }

            init() {}
        }

        /// Opens the list.
        struct OpenList: AppIntent {
            static var title: LocalizedStringResource = "Open List"

            func perform() async throws -> some IntentResult {
                .result()
            }
        }
        """
        testFormatting(for: input, rule: .missingDocComments, exclude: [.privateSwiftUIDynamicProperties])
    }

    func testCustomExemptNames() {
        let input = """
        /// A store.
        struct Store {
            var id: String
        }
        """
        let options = FormatOptions(missingDocCommentsExemptNames: ["id"])
        testFormatting(for: input, rule: .missingDocComments, options: options)
    }

    func testMarkerIsNotAddedTwice() {
        let input = """
        // FIXME: [missingDocComments] missing doc comment
        let total = 0
        """
        testFormatting(for: input, rule: .missingDocComments)
    }
}
