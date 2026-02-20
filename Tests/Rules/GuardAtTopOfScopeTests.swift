//
//  GuardAtTopOfScopeTests.swift
//  SwiftFormatTests
//

import XCTest
@testable import SwiftFormat

final class GuardAtTopOfScopeTests: XCTestCase {
    // MARK: - No change (valid)

    func testGuardsAtTopConsecutive() {
        let input = """
        func test(value: Int?, flag: Bool) {
            guard let value else { return }
            guard flag else { return }
            print("all good: \\(value)")
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testSingleGuardAtTop() {
        let input = """
        func test(flag: Bool) {
            guard flag else { return }
            print("proceed")
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testMultiLineGuardFollowedByGuard() {
        let input = """
        func test(value: Int?) {
            guard let value else {
                print("missing value")
                return
            }
            guard value > 0 else { return }
            print("value is \\(value)")
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardsWithCommentBetween() {
        let input = """
        func test(value: Int?, flag: Bool) {
            guard let value else { return }
            // Ensure flag is set
            guard flag else { return }
            print("proceed")
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardWithCommentBefore() {
        let input = """
        func test(flag: Bool) {
            // Check the precondition
            guard flag else { return }
            print("proceed")
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardInComputedProperty() {
        let input = """
        var value: Int {
            guard let stored = _stored else { return 0 }
            return stored
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardInInit() {
        let input = """
        init?(value: Int?) {
            guard let value else { return nil }
            self.value = value
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardInSubscript() {
        let input = """
        subscript(index: Int) -> Int {
            guard index >= 0 else { return 0 }
            return array[index]
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardInPropertyGetter() {
        let input = """
        var value: Int {
            get {
                guard let stored = _stored else { return 0 }
                return stored
            }
            set { _stored = newValue }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    // MARK: - Valid (guard at top of non-function scopes)

    func testGuardAtTopOfClosure() {
        let input = """
        func test() {
            items.forEach {
                guard let value = $0 else { return }
                print(value)
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements, .preferForLoop])
    }

    func testGuardAtTopOfDoBlock() {
        let input = """
        func test() {
            do {
                guard condition else { return }
                try something()
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfCatchBlock() {
        let input = """
        func test() {
            do {
                try something()
            } catch {
                guard canRecover else { return }
                recover()
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfCaseBlock() {
        let input = """
        func test(value: Int) {
            switch value {
            case 0:
                guard condition else { return }
                handle()
            default:
                break
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements, .blankLineAfterSwitchCase])
    }

    func testGuardAtTopOfForLoop() {
        let input = """
        func test(items: [Int?]) {
            for item in items {
                guard let item else { continue }
                print(item)
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    // MARK: - Violations in non-function scopes

    func testGuardAfterCodeInForLoop() {
        let input = """
        func test(items: [Int?]) {
            for item in items {
                print("processing")
                guard let item else { continue }
                print(item)
            }
        }
        """
        let output = """
        func test(items: [Int?]) {
            for item in items {
                print("processing")
                // FIXME: [guardAtTopOfScope] guard should be at top of scope
                guard let item else { continue }
                print(item)
            }
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterCodeInClosure() {
        let input = """
        func test() {
            items.forEach {
                print("processing")
                guard let value = $0 else { return }
                print(value)
            }
        }
        """
        let output = """
        func test() {
            items.forEach {
                print("processing")
                // FIXME: [guardAtTopOfScope] guard should be at top of scope
                guard let value = $0 else { return }
                print(value)
            }
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements, .preferForLoop])
    }

    func testGuardAfterCodeInDoBlock() {
        let input = """
        func test() {
            do {
                print("trying")
                guard condition else { return }
                try something()
            }
        }
        """
        let output = """
        func test() {
            do {
                print("trying")
                // FIXME: [guardAtTopOfScope] guard should be at top of scope
                guard condition else { return }
                try something()
            }
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfIfBody() {
        let input = """
        func test(flag: Bool, value: Int?) {
            if flag {
                guard let value else { return }
                print(value)
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfDeferBlock() {
        let input = """
        func test() {
            defer {
                guard condition else { return }
                cleanup()
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfWhileBody() {
        let input = """
        func test() {
            while true {
                guard condition else { break }
                doWork()
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfElseBlock() {
        let input = """
        func test(flag: Bool, value: Int?) {
            if flag {
                print("flag set")
            } else {
                guard let value else { return }
                print(value)
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfRepeatBlock() {
        let input = """
        func test() {
            repeat {
                guard condition else { break }
                doWork()
            } while shouldContinue
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAtTopOfCompletionHandlerClosure() {
        let input = """
        func test() {
            fetchData { result in
                guard case let .success(data) = result else { return }
                process(data)
            }
        }
        """
        testFormatting(for: input, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardInSwitchCaseAfterCodeFlagged() {
        let input = """
        func test(value: Int) {
            switch value {
            case 0:
                print("zero")
                guard condition else { return }
                handle()
            default:
                break
            }
        }
        """
        let output = """
        func test(value: Int) {
            switch value {
            case 0:
                print("zero")
                // FIXME: [guardAtTopOfScope] guard should be at top of scope
                guard condition else { return }
                handle()
            default:
                break
            }
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements, .blankLineAfterSwitchCase])
    }

    // MARK: - Violations (should trigger)

    func testGuardAfterCode() {
        let input = """
        func test(value: Int?, flag: Bool) {
            guard let value else { return }
            print("doing something")
            guard flag else { return }
            print("all good: \\(value)")
        }
        """
        let output = """
        func test(value: Int?, flag: Bool) {
            guard let value else { return }
            print("doing something")
            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard flag else { return }
            print("all good: \\(value)")
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterCodeWithBlankLine() {
        let input = """
        func test(flag: Bool) {
            print("setup")

            guard flag else { return }
            print("proceed")
        }
        """
        let output = """
        func test(flag: Bool) {
            print("setup")

            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard flag else { return }
            print("proceed")
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterCodeWithComment() {
        let input = """
        func test(flag: Bool) {
            print("setup")
            // check the flag
            guard flag else { return }
            print("proceed")
        }
        """
        let output = """
        func test(flag: Bool) {
            print("setup")
            // check the flag
            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard flag else { return }
            print("proceed")
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterCodeInComputedProperty() {
        let input = """
        var value: Int {
            let x = compute()
            guard x > 0 else { return 0 }
            return x
        }
        """
        let output = """
        var value: Int {
            let x = compute()
            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard x > 0 else { return 0 }
            return x
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testMultipleGuardsAfterCode() {
        let input = """
        func test(a: Int?, b: Int?) {
            print("setup")
            guard let a else { return }
            guard let b else { return }
            print(a + b)
        }
        """
        let output = """
        func test(a: Int?, b: Int?) {
            print("setup")
            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard let a else { return }
            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard let b else { return }
            print(a + b)
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    // MARK: - Exceptions (--guard-exceptions)

    func testGuardAfterExceptedFunctionCall() {
        let input = """
        func test(value: Int?) {
            logP("Processing value")
            guard let value else { return }
            print(value)
        }
        """
        let options = FormatOptions(guardAtTopOfScopeExceptions: ["logP"])
        testFormatting(for: input, rule: .guardAtTopOfScope, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterMultipleExceptedFunctionCalls() {
        let input = """
        func test(value: Int?) {
            logP(managerName, "Changing value", category: .manager)
            logW("Warning about value")
            guard let value else { return }
            print(value)
        }
        """
        let options = FormatOptions(guardAtTopOfScopeExceptions: ["logP", "logW"])
        testFormatting(for: input, rule: .guardAtTopOfScope, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterExceptedAndGuardStatements() {
        let input = """
        func test(value: Int?, flag: Bool) {
            logP("Starting process")
            guard let value else { return }
            guard flag else { return }
            print(value)
        }
        """
        let options = FormatOptions(guardAtTopOfScopeExceptions: ["logP"])
        testFormatting(for: input, rule: .guardAtTopOfScope, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterNonExceptedFunctionStillFlags() {
        let input = """
        func test(value: Int?) {
            setup()
            guard let value else { return }
            print(value)
        }
        """
        let output = """
        func test(value: Int?) {
            setup()
            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard let value else { return }
            print(value)
        }
        """
        let options = FormatOptions(guardAtTopOfScopeExceptions: ["logP"])
        testFormatting(for: input, output, rule: .guardAtTopOfScope, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterExceptedCallBetweenGuards() {
        let input = """
        func adjustAccessProtectionCode(to newCode: String, onCompletion callback: @escaping (Result<SuccessCase, Error>) -> Void) {
            logP(managerName, "Changing Access Protection Code", category: .manager)
            guard let oldAccessProtection = storage.accessProtection else { fatalLog("Not found!") }
            guard let newHashedCode = PBKDF2HashingHelper.hash(newCode, with: oldAccessProtection.hashingSalt) else {
                logW("Could not hash Access Protection Code", category: .general)
                return callback(.failure(.hashingFailed))
            }
            print("done")
        }
        """
        let options = FormatOptions(guardAtTopOfScopeExceptions: ["logP", "logW"])
        testFormatting(for: input, rule: .guardAtTopOfScope, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardWithEmptyExceptionsStillFlags() {
        let input = """
        func test(value: Int?) {
            logP("Processing value")
            guard let value else { return }
            print(value)
        }
        """
        let output = """
        func test(value: Int?) {
            logP("Processing value")
            // FIXME: [guardAtTopOfScope] guard should be at top of scope
            guard let value else { return }
            print(value)
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    func testGuardAfterMultiLineExceptedCall() {
        let input = """
        func test(value: Int?) {
            logP(managerName,
                 "Changing Access Protection Code",
                 category: .manager)
            guard let value else { return }
            print(value)
        }
        """
        let options = FormatOptions(guardAtTopOfScopeExceptions: ["logP"])
        testFormatting(for: input, rule: .guardAtTopOfScope, options: options,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }

    // MARK: - Violations in property getters

    func testGuardAfterCodeInPropertyGetter() {
        let input = """
        var value: Int {
            get {
                let x = compute()
                guard x > 0 else { return 0 }
                return x
            }
            set { _value = newValue }
        }
        """
        let output = """
        var value: Int {
            get {
                let x = compute()
                // FIXME: [guardAtTopOfScope] guard should be at top of scope
                guard x > 0 else { return 0 }
                return x
            }
            set { _value = newValue }
        }
        """
        testFormatting(for: input, output, rule: .guardAtTopOfScope,
                       exclude: [.wrapConditionalBodies, .blankLinesAfterGuardStatements])
    }
}
