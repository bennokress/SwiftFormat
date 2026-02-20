//
//  ScopePaddingTests.swift
//  SwiftFormatTests
//

import XCTest
@testable import SwiftFormat

final class ScopePaddingTests: XCTestCase {
    // MARK: - Type bodies: add padding

    func testStructGetsPadding() {
        let input = """
        struct Foo {
            let bar: Int
        }
        """
        let output = """
        struct Foo {

            let bar: Int

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testClassGetsPadding() {
        let input = """
        class Foo {
            var bar: Int = 0
        }
        """
        let output = """
        class Foo {

            var bar: Int = 0

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testEnumGetsPadding() {
        let input = """
        enum Direction {
            case north
            case south
        }
        """
        let output = """
        enum Direction {

            case north
            case south

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testExtensionGetsPadding() {
        let input = """
        extension Foo {
            func bar() {}
        }
        """
        let output = """
        extension Foo {

            func bar() {}

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testProtocolGetsPadding() {
        let input = """
        protocol Foo {
            func bar()
        }
        """
        let output = """
        protocol Foo {

            func bar()

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testActorGetsPadding() {
        let input = """
        actor MyActor {
            var state: Int = 0
        }
        """
        let output = """
        actor MyActor {

            var state: Int = 0

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    // MARK: - Type bodies: already correct

    func testTypeBodyAlreadyPaddedUnchanged() {
        let input = """
        struct Foo {

            let bar: Int

        }
        """
        testFormatting(for: input, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    // MARK: - Type bodies: excess padding reduced

    func testTypeBodyExcessLeadingPaddingReduced() {
        let input = """
        struct Foo {


            let bar: Int

        }
        """
        let output = """
        struct Foo {

            let bar: Int

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testTypeBodyExcessTrailingPaddingReduced() {
        let input = """
        struct Foo {

            let bar: Int


        }
        """
        let output = """
        struct Foo {

            let bar: Int

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    // MARK: - Non-type scopes: remove padding

    func testFuncBlankLinesRemoved() {
        let input = """
        func foo() {

            bar()

        }
        """
        let output = """
        func foo() {
            bar()
        }
        """
        testFormatting(for: input, output, rule: .scopePadding)
    }

    func testFuncAlreadyCorrectUnchanged() {
        let input = """
        func foo() {
            bar()
        }
        """
        testFormatting(for: input, rule: .scopePadding)
    }

    func testClosureBlankLinesRemoved() {
        let input = """
        someFunc {

            doSomething()

        }
        """
        let output = """
        someFunc {
            doSomething()
        }
        """
        testFormatting(for: input, output, rule: .scopePadding)
    }

    func testClosureWithInKeywordBlankLineRemoved() {
        let input = """
        someFunc { result in

            doSomething(result)

        }
        """
        let output = """
        someFunc { result in
            doSomething(result)
        }
        """
        testFormatting(for: input, output, rule: .scopePadding)
    }

    func testIfScopeBlankLinesRemoved() {
        let input = """
        if condition {

            doSomething()

        }
        """
        let output = """
        if condition {
            doSomething()
        }
        """
        testFormatting(for: input, output, rule: .scopePadding)
    }

    func testSwitchScopeBlankLinesRemoved() {
        let input = """
        switch value {

        case .a:
            doA()
        case .b:
            doB()

        }
        """
        let output = """
        switch value {
        case .a:
            doA()
        case .b:
            doB()
        }
        """
        testFormatting(for: input, output, rule: .scopePadding)
    }

    func testComputedPropertyBlankLinesRemoved() {
        let input = """
        var description: String {

            return "hello"

        }
        """
        let output = """
        var description: String {
            return "hello"
        }
        """
        testFormatting(for: input, output, rule: .scopePadding)
    }

    func testFuncExcessLeadingBlankLinesRemoved() {
        let input = """
        func foo() {


            bar()
        }
        """
        let output = """
        func foo() {
            bar()
        }
        """
        testFormatting(for: input, output, rule: .scopePadding)
    }

    // MARK: - One-liners preserved

    func testOneLineFuncUnchanged() {
        let input = """
        func foo() { bar() }
        """
        testFormatting(for: input, rule: .scopePadding,
                       exclude: [.wrapFunctionBodies])
    }

    func testOneLineStructUnchanged() {
        let input = """
        struct Foo { let x = 1 }
        """
        testFormatting(for: input, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testOneLineClosureUnchanged() {
        let input = """
        let result = items.map { $0 + 1 }
        """
        testFormatting(for: input, rule: .scopePadding)
    }

    func testOneLineGuardUnchanged() {
        let input = """
        guard let x else { return }
        """
        testFormatting(for: input, rule: .scopePadding,
                       exclude: [.wrapConditionalBodies])
    }

    // MARK: - Empty scopes

    func testEmptyFuncUnchanged() {
        let input = """
        func foo() {
        }
        """
        testFormatting(for: input, rule: .scopePadding,
                       exclude: [.emptyBraces])
    }

    func testEmptyStructUnchanged() {
        let input = """
        struct Foo {
        }
        """
        testFormatting(for: input, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
                                 .emptyBraces])
    }

    // MARK: - Combined scenarios

    func testStructWithFuncsHasPaddingWhileFuncsDont() {
        let input = """
        struct Manager {
            let name = "Manager"

            func process() {

                guard let data else { return }
                handle(data)

            }
        }
        """
        let output = """
        struct Manager {

            let name = "Manager"

            func process() {
                guard let data else { return }
                handle(data)
            }

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
                                 .wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testNestedTypeBodiesBothGetPadding() {
        let input = """
        struct Outer {
            struct Inner {
                let x = 1
            }
        }
        """
        let output = """
        struct Outer {

            struct Inner {

                let x = 1

            }

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
                                 .enumNamespaces])
    }

    func testEnumWithComputedPropertyPaddedCorrectly() {
        let input = """
        enum Action: String, Codable {
            case start = "START"
            case stop = "STOP"

            var description: String {

                switch self {
                case .start: return "Start"
                case .stop: return "Stop"
                }

            }
        }
        """
        let output = """
        enum Action: String, Codable {

            case start = "START"
            case stop = "STOP"

            var description: String {
                switch self {
                case .start: return "Start"
                case .stop: return "Stop"
                }
            }

        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testClosureTrailingBlankLineRemoved() {
        let input = """
        manager.prepare { result in
            guard case .success = result else { return }
            navigate()

        }
        """
        let output = """
        manager.prepare { result in
            guard case .success = result else { return }
            navigate()
        }
        """
        testFormatting(for: input, output, rule: .scopePadding,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    // MARK: - Short scope threshold

    func testShortEnumPaddingRemovedWithThreshold() {
        let input = """
        enum Error: Swift.Error {

            case dataCenterError(error: DataCenterError)
            case paymentMeansRetrievalFailed
            case emptyPaymentMeansList(error: EmptyPaymentMeanListCause)

        }
        """
        let output = """
        enum Error: Swift.Error {
            case dataCenterError(error: DataCenterError)
            case paymentMeansRetrievalFailed
            case emptyPaymentMeansList(error: EmptyPaymentMeanListCause)
        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 3)
        testFormatting(for: input, output, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testShortEnumNoPaddingAddedWithThreshold() {
        let input = """
        enum Error: Swift.Error {
            case dataCenterError
            case paymentMeansRetrievalFailed
        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 3)
        testFormatting(for: input, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testLongEnumStillGetsPaddingWithThreshold() {
        let input = """
        enum Direction {
            case north
            case south
            case east
            case west
        }
        """
        let output = """
        enum Direction {

            case north
            case south
            case east
            case west

        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 3)
        testFormatting(for: input, output, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testShortScopeWithBlankLineStillGetsPadding() {
        let input = """
        struct Foo {
            let x: Int

            var y: Int { x }
        }
        """
        let output = """
        struct Foo {

            let x: Int

            var y: Int { x }

        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 3)
        testFormatting(for: input, output, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
                                 .wrapPropertyBodies])
    }

    func testShortScopeWithoutBlankLineSkipsPadding() {
        let input = """
        struct Foo {
            let x: Int
            var y: Int { x }
        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 3)
        testFormatting(for: input, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope,
                                 .wrapPropertyBodies])
    }

    func testNestedShortScopeInLongScope() {
        let input = """
        struct Outer {

            let useCase: String

            enum CodingKeys: String, CodingKey {

                case useCase = "usecase"

            }

        }
        """
        let output = """
        struct Outer {

            let useCase: String

            enum CodingKeys: String, CodingKey {
                case useCase = "usecase"
            }

        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 3)
        testFormatting(for: input, output, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testThresholdZeroDisablesShortScopeFeature() {
        let input = """
        enum Direction {
            case north
        }
        """
        let output = """
        enum Direction {

            case north

        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 0)
        testFormatting(for: input, output, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }

    func testCommentLinesCountTowardThreshold() {
        let input = """
        enum Foo {
            // A comment
            case bar
            case baz
        }
        """
        let output = """
        enum Foo {

            // A comment
            case bar
            case baz

        }
        """
        let options = FormatOptions(scopeLinesWithoutPadding: 2)
        testFormatting(for: input, output, rule: .scopePadding,
                       options: options,
                       exclude: [.blankLinesAtStartOfScope, .blankLinesAtEndOfScope])
    }
}
