//
//  EarlyReturnTests.swift
//  SwiftFormatTests
//

import XCTest
@testable import SwiftFormat

final class EarlyReturnTests: XCTestCase {
    // MARK: - No change (return is allowed)

    func testReturnInGuardElseBody() {
        let input = """
        func test(value: Int?) {
            guard let value else { return }
            print(value)
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testReturnAsLastStatementOfFunction() {
        let input = """
        func test() -> Int {
            let x = compute()
            return x
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantProperty, .redundantVariable])
    }

    func testVoidReturnAsLastStatementOfFunction() {
        let input = """
        func test() {
            doSomething()
            return
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantReturn])
    }

    func testReturnAsLastStatementOfClosure() {
        let input = """
        let result = items.map { item in
            return item.transformed
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantReturn])
    }

    func testReturnAsLastStatementOfComputedProperty() {
        let input = """
        var value: Int {
            let x = compute()
            return x
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantProperty, .redundantVariable])
    }

    func testReturnAsLastStatementOfGetter() {
        let input = """
        var value: Int {
            get {
                let x = compute()
                return x
            }
            set { _value = newValue }
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantProperty, .redundantVariable])
    }

    func testReturnAsLastStatementOfInit() {
        let input = """
        init?(value: Int?) {
            guard let value else { return nil }
            self.value = value
            return
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies, .redundantReturn, .blankLinesAfterGuardStatements])
    }

    func testReturnInSwitchCaseArms() {
        let input = """
        func status(for code: Int) -> String {
            switch code {
            case 200:
                return "OK"
            case 404:
                return "Not Found"
            default:
                return "Unknown"
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn)
    }

    func testReturnAsLastStatementOfDoBlock() {
        let input = """
        func test() -> Int {
            do {
                let value = try compute()
                return value
            } catch {
                return 0
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantProperty, .redundantVariable])
    }

    func testReturnInsideGuardElseWithNestedIf() {
        let input = """
        func test(value: Int?) {
            guard let value else {
                if debugMode {
                    return
                }
                return
            }
            print(value)
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies, .redundantReturn, .blankLinesAfterGuardStatements])
    }

    func testMultiLineReturnExpressionAsLastStatement() {
        let input = """
        func test() -> String {
            return foo
                .bar
                .baz
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantReturn])
    }

    func testSingleReturnInFunction() {
        let input = """
        func test() -> Int {
            return 42
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantReturn])
    }

    func testReturnInClosureInsideForLoop() {
        let input = """
        func test(items: [Int?]) {
            for item in items {
                let mapped = item.map { value in
                    return value * 2
                }
                print(mapped ?? 0)
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantReturn])
    }

    func testGuardWithReturnThenFinalReturn() {
        let input = """
        func test(value: Int?) -> String {
            guard let value else { return "none" }
            return "\\(value)"
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testReturnAsLastStatementOfSubscript() {
        let input = """
        subscript(index: Int) -> Int {
            return array[index]
        }
        """
        testFormatting(for: input, rule: .earlyReturn, exclude: [.redundantReturn])
    }

    func testReturnInIfAvailableBody() {
        let input = """
        func test() -> some View {
            if #available(iOS 17.0, *) {
                return Text("new")
            } else {
                return Text("old")
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn)
    }

    func testReturnInIfUnavailableBody() {
        let input = """
        func test() -> Int {
            if #unavailable(iOS 17.0) {
                return legacyValue()
            } else {
                return modernValue()
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn)
    }

    func testReturnInElseIfAvailableChain() {
        let input = """
        func test() -> Int {
            if #available(iOS 18.0, *) {
                return 3
            } else if #available(iOS 17.0, *) {
                return 2
            } else {
                return 1
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn)
    }

    func testReturnInCaseBeforeUnknownDefault() {
        let input = """
        func test(_ value: BiometryType) -> String {
            switch value {
            case .faceID:
                return "faceID"
            case .touchID:
                return "touchID"
            @unknown default:
                return "unknown"
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn)
    }

    func testReturnInUnknownDefaultBody() {
        let input = """
        func test(_ value: BiometryType) -> String {
            switch value {
            case .none:
                return "none"
            @unknown default:
                log("unknown type")
                return "unknown"
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn)
    }

    func testReturnWithAssignmentAsLastStatement() {
        let input = """
        func handleResult(_ result: Result<Void, Error>) {
            guard condition else { return content = .success }
            return content = .success(.done(result))
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testReturnWithAssignmentInSwitchCase() {
        let input = """
        func handleError(_ error: Error) {
            switch error {
            case .canceled:
                return content = .canceled
            default:
                return content = .failed
            }
        }
        """
        testFormatting(for: input, rule: .earlyReturn)
    }

    // MARK: - Violations (return is flagged)

    func testReturnInsideIfBody() {
        let input = """
        func test(value: Int?) -> String {
            if value != nil {
                return "has value"
            }
            return "no value"
        }
        """
        let output = """
        func test(value: Int?) -> String {
            if value != nil {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return "has value"
            }
            return "no value"
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testReturnInsideElseBody() {
        let input = """
        func test(flag: Bool) -> String {
            if flag {
                print("flag set")
            } else {
                return "not set"
            }
            return "done"
        }
        """
        let output = """
        func test(flag: Bool) -> String {
            if flag {
                print("flag set")
            } else {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return "not set"
            }
            return "done"
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testReturnInsideForLoopBody() {
        let input = """
        func test(items: [Int]) -> Int? {
            for item in items {
                return item
            }
            return nil
        }
        """
        let output = """
        func test(items: [Int]) -> Int? {
            for item in items {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return item
            }
            return nil
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn)
    }

    func testReturnInsideWhileLoopBody() {
        let input = """
        func test() -> Int {
            while let value = next() {
                return value
            }
            return 0
        }
        """
        let output = """
        func test() -> Int {
            while let value = next() {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return value
            }
            return 0
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn)
    }

    func testReturnInsideRepeatLoopBody() {
        let input = """
        func test() -> Int {
            repeat {
                return compute()
            } while false
        }
        """
        let output = """
        func test() -> Int {
            repeat {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return compute()
            } while false
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn)
    }

    func testReturnNotLastStatementOfFunction() {
        let input = """
        func test(flag: Bool) -> String {
            if flag {
                return "early"
            }
            doSomething()
            return "late"
        }
        """
        let output = """
        func test(flag: Bool) -> String {
            if flag {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return "early"
            }
            doSomething()
            return "late"
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testMultipleViolationsInOneFunction() {
        let input = """
        func test(x: Bool, y: Bool) -> String {
            if x {
                return "x"
            }
            if y {
                return "y"
            }
            return "neither"
        }
        """
        let output = """
        func test(x: Bool, y: Bool) -> String {
            if x {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return "x"
            }
            if y {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return "y"
            }
            return "neither"
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies])
    }

    // MARK: - Edge cases

    func testIdempotencyAlreadyMarked() {
        let input = """
        func test(flag: Bool) -> String {
            if flag {
                // FIXME: [earlyReturn] return should be in guard-else or at end of scope
                return "early"
            }
            return "late"
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testReturnInSingleLineIfBlockFlaggedAtEndOfLine() {
        let input = """
        func test(flag: Bool) -> String {
            if flag { return "early" }
            return "late"
        }
        """
        let output = """
        func test(flag: Bool) -> String {
            if flag { return "early" } // FIXME: [earlyReturn] return should be in guard-else or at end of scope
            return "late"
        }
        """
        testFormatting(for: input, output, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testReturnInSingleLineBlockNoBracesConflict() {
        let input = """
        func test(flag: Bool) -> String {
            if flag { return "early" }
            return "late"
        }
        """
        let output = """
        func test(flag: Bool) -> String {
            if flag { return "early" } // FIXME: [earlyReturn] return should be in guard-else or at end of scope
            return "late"
        }
        """
        testFormatting(for: input, [output], rules: [.earlyReturn, .braces],
                       exclude: [.wrapConditionalBodies])
    }

    func testReturnInSingleLineBlockIdempotent() {
        let input = """
        func test(flag: Bool) -> String {
            if flag { return "early" } // FIXME: [earlyReturn] return should be in guard-else or at end of scope
            return "late"
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies])
    }

    func testGuardElseContainingIfWithReturn() {
        let input = """
        func test(value: Int?) {
            guard let value else {
                if shouldLog {
                    log("missing value")
                    return
                }
                return
            }
            print(value)
        }
        """
        testFormatting(for: input, rule: .earlyReturn,
                       exclude: [.wrapConditionalBodies, .redundantReturn, .blankLinesAfterGuardStatements])
    }
}
