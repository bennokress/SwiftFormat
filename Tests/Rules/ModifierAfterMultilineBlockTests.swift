//
//  ModifierAfterMultilineBlockTests.swift
//  SwiftFormatTests
//

import XCTest
@testable import SwiftFormat

final class ModifierAfterMultilineBlockTests: XCTestCase {
    func testModifierAfterMultilineClosureOnNextLine() {
        let input = """
        Button("Jump to #8") {
            value.scrollTo(8)
        }
        .padding()
        """
        let output = """
        Button("Jump to #8") {
            value.scrollTo(8)
        }
        // FIXME: [modifierAfterMultilineBlock] consider extracting the block content to improve readability
        .padding()
        """
        testFormatting(for: input, output, rule: .modifierAfterMultilineBlock)
    }

    func testModifierAfterMultilineClosureOnSameLine() {
        let input = """
        Button("Jump to #8") {
            value.scrollTo(8)
        }.padding()
        """
        let output = """
        Button("Jump to #8") {
            value.scrollTo(8)
        }
        // FIXME: [modifierAfterMultilineBlock] consider extracting the block content to improve readability
        .padding()
        """
        testFormatting(for: input, output, rule: .modifierAfterMultilineBlock)
    }

    func testOneLinerBlockNotAffected() {
        let input = """
        Button("OK") { dismiss() }
            .padding()
        """
        testFormatting(for: input, rule: .modifierAfterMultilineBlock)
    }

    func testOneLinerBlockOnSameLineNotAffected() {
        let input = """
        Button("OK") { dismiss() }.padding()
        """
        testFormatting(for: input, rule: .modifierAfterMultilineBlock)
    }

    func testModifierChainWithoutBracesNotAffected() {
        let input = """
        SGScreen(as: screenType, title: screenTitle)
            .withAttachedBottomSheet(bottomSheet, isVisible: $showList)
            .addSceletonLoadingPlaceholder(while: $manager.isLoading)
            .allowsHitTesting(!showDialog)
        """
        testFormatting(for: input, rule: .modifierAfterMultilineBlock)
    }

    func testSwiftUIViewWithMultipleViolations() {
        let input = """
        var body: some View {
            ScrollViewReader { value in
                ScrollView {
                    Button("Jump to #8") {
                        value.scrollTo(8)
                    }
                    .padding()

                    ForEach(0 ..< 100) { i in
                        Text("Example \\(i)")
                            .font(.title)
                            .frame(width: 200, height: 200)
                            .background(colors[i % colors.count])
                            .id(i)
                    }
                }
            }
            .frame(height: 350)
        }
        """
        let output = """
        var body: some View {
            ScrollViewReader { value in
                ScrollView {
                    Button("Jump to #8") {
                        value.scrollTo(8)
                    }
                    // FIXME: [modifierAfterMultilineBlock] consider extracting the block content to improve readability
                    .padding()

                    ForEach(0 ..< 100) { i in
                        Text("Example \\(i)")
                            .font(.title)
                            .frame(width: 200, height: 200)
                            .background(colors[i % colors.count])
                            .id(i)
                    }
                }
            }
            // FIXME: [modifierAfterMultilineBlock] consider extracting the block content to improve readability
            .frame(height: 350)
        }
        """
        testFormatting(for: input, output, rule: .modifierAfterMultilineBlock)
    }

    func testIdempotency() {
        let input = """
        Button("Jump to #8") {
            value.scrollTo(8)
        }
        // FIXME: [modifierAfterMultilineBlock] consider extracting the block content to improve readability
        .padding()
        """
        testFormatting(for: input, rule: .modifierAfterMultilineBlock)
    }

    func testNoModifierAfterClosingBrace() {
        let input = """
        if condition {
            doSomething()
        }
        """
        testFormatting(for: input, rule: .modifierAfterMultilineBlock)
    }

    func testModifierAfterSingleLineNotAffected() {
        let input = """
        Text("Hello")
            .font(.title)
            .padding()
        """
        testFormatting(for: input, rule: .modifierAfterMultilineBlock)
    }

    func testOnlyFirstModifierInChainFlagged() {
        let input = """
        Button("Jump") {
            action()
        }
        .padding()
        .background(Color.red)
        """
        let output = """
        Button("Jump") {
            action()
        }
        // FIXME: [modifierAfterMultilineBlock] consider extracting the block content to improve readability
        .padding()
        .background(Color.red)
        """
        testFormatting(for: input, output, rule: .modifierAfterMultilineBlock)
    }
}
