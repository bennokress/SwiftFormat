//
//  NoDeferTests.swift
//  SwiftFormatTests
//
//  Created by Benno Kress on 2026-05-04.
//

import XCTest
@testable import SwiftFormat

final class NoDeferTests: XCTestCase {
    // Violations

    func testFlagsSingleStatementDeferInFunction() {
        let input = """
        func loadData() {
            lock.lock()
            defer { lock.unlock() }
            work()
        }
        """
        let output = """
        func loadData() {
            lock.lock()
            // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
            defer { lock.unlock() }
            work()
        }
        """
        testFormatting(for: input, output, rule: .noDefer)
    }

    func testFlagsMultiStatementDeferInFunction() {
        let input = """
        func process() {
            defer {
                cleanup()
                log("done")
            }
            work()
        }
        """
        let output = """
        func process() {
            // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
            defer {
                cleanup()
                log("done")
            }
            work()
        }
        """
        testFormatting(for: input, output, rule: .noDefer)
    }

    func testFlagsDeferInsideDoBlock() {
        let input = """
        func process() {
            do {
                defer { cleanup() }
                try work()
            } catch {
                log(error)
            }
        }
        """
        let output = """
        func process() {
            do {
                // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
                defer { cleanup() }
                try work()
            } catch {
                log(error)
            }
        }
        """
        testFormatting(for: input, output, rule: .noDefer)
    }

    func testFlagsDeferInsideClosure() {
        let input = """
        func run() {
            queue.async {
                defer { cleanup() }
                work()
            }
        }
        """
        let output = """
        func run() {
            queue.async {
                // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
                defer { cleanup() }
                work()
            }
        }
        """
        testFormatting(for: input, output, rule: .noDefer)
    }

    func testFlagsMultipleDefersInSameScope() {
        let input = """
        func process() {
            defer { releaseA() }
            defer { releaseB() }
            work()
        }
        """
        let output = """
        func process() {
            // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
            defer { releaseA() }
            // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
            defer { releaseB() }
            work()
        }
        """
        testFormatting(for: input, output, rule: .noDefer)
    }

    func testFlagsDeferInSingleLineEnclosingBlockAtEndOfLine() {
        let input = """
        func test() { defer { cleanup() } }
        """
        let output = """
        func test() { defer { cleanup() } } // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
        """
        testFormatting(for: input, output, rule: .noDefer, exclude: [.wrapFunctionBodies])
    }

    // Idempotency

    func testDoesNotDuplicateExistingMarker() {
        let input = """
        func loadData() {
            lock.lock()
            // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
            defer { lock.unlock() }
            work()
        }
        """
        testFormatting(for: input, rule: .noDefer)
    }

    func testDoesNotDuplicateExistingEndOfLineMarker() {
        let input = """
        func test() { defer { cleanup() } } // FIXME: [noDefer] avoid defer; repeat the call before each exit, or extract a helper for longer bodies
        """
        testFormatting(for: input, rule: .noDefer, exclude: [.wrapFunctionBodies])
    }
}
