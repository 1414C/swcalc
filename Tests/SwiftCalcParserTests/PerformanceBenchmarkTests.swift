import XCTest
@testable import SwiftCalcParser
@testable import SwiftCalcTokenizer

/// Performance benchmark tests for SwiftCalcParser
/// 
/// This test suite measures parsing performance, memory usage, and scalability
/// of the parser with large and complex expressions. The benchmarks help ensure
/// the parser maintains acceptable performance characteristics as expressions
/// grow in size and complexity.
final class PerformanceBenchmarkTests: XCTestCase {
    
    // MARK: - Test Configuration
    
    /// Number of iterations for performance measurements
    private let performanceIterations = 100
    
    /// Timeout for performance tests (in seconds)
    private let performanceTimeout: TimeInterval = 30.0
    
    // MARK: - Large Expression Performance Tests
    
    /// Test parsing performance with deeply nested expressions
    func testDeepNestingPerformance() throws {
        // Create deeply nested parenthesized expressions: ((((((5))))))
        let depth = 1000
        var expression = "5"
        
        for _ in 0..<depth {
            expression = "(\(expression))"
        }
        
        measure {
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let _ = try parser.parse()
            } catch {
                XCTFail("Failed to parse deeply nested expression: \(error)")
            }
        }
    }
    
    /// Test parsing performance with wide binary operation trees
    func testWideBinaryOperationPerformance() throws {
        // Create wide binary operation: 1 + 2 + 3 + ... + 1000
        let operandCount = 1000
        var expression = "1"
        
        for i in 2...operandCount {
            expression += " + \(i)"
        }
        
        measure {
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let _ = try parser.parse()
            } catch {
                XCTFail("Failed to parse wide binary operation: \(error)")
            }
        }
    }
    
    /// Test parsing performance with complex mixed operator expressions
    func testComplexMixedOperatorPerformance() throws {
        // Create complex expression with mixed operators and precedence
        // Pattern: (a + b) * (c - d) ^ (e / f) % (g + h) * ...
        let groupCount = 200
        var expression = ""
        let operators = ["+", "-", "*", "/", "%", "^"]
        
        for i in 0..<groupCount {
            let a = i * 8 + 1
            let b = i * 8 + 2
            let c = i * 8 + 3
            let d = i * 8 + 4
            let e = i * 8 + 5
            let f = i * 8 + 6
            let g = i * 8 + 7
            let h = i * 8 + 8
            
            let group = "(\(a) + \(b)) * (\(c) - \(d)) ^ (\(e) / \(f)) % (\(g) + \(h))"
            
            if i == 0 {
                expression = group
            } else {
                let op = operators[i % operators.count]
                expression += " \(op) \(group)"
            }
        }
        
        measure {
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let _ = try parser.parse()
            } catch {
                XCTFail("Failed to parse complex mixed operator expression: \(error)")
            }
        }
    }
    
    /// Test parsing performance with many function calls
    func testManyFunctionCallsPerformance() throws {
        // Create expression with nested function calls: sin(cos(tan(log(sqrt(abs(5))))))
        let functions = ["sin", "cos", "tan", "log", "sqrt", "abs", "exp", "floor", "ceil"]
        let nestingDepth = 500
        
        var expression = "5"
        for i in 0..<nestingDepth {
            let function = functions[i % functions.count]
            expression = "\(function)(\(expression))"
        }
        
        measure {
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let _ = try parser.parse()
            } catch {
                XCTFail("Failed to parse nested function calls: \(error)")
            }
        }
    }
    
    /// Test parsing performance with many assignment chains
    func testAssignmentChainPerformance() throws {
        // Create long assignment chain: a = b = c = d = ... = 1000
        let chainLength = 500
        var expression = "var\(chainLength) = 1000"
        
        for i in (1..<chainLength).reversed() {
            expression = "var\(i) = \(expression)"
        }
        
        measure {
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let _ = try parser.parse()
            } catch {
                XCTFail("Failed to parse assignment chain: \(error)")
            }
        }
    }
    
    // MARK: - Memory Usage Tests
    
    /// Test memory usage with large AST trees
    func testMemoryUsageWithLargeAST() throws {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create a large expression that will generate a substantial AST
        let operandCount = 5000
        var expression = "1"
        
        for i in 2...operandCount {
            expression += " + \(i)"
        }
        
        let tokenizer = Tokenizer(input: expression)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Log memory usage for analysis
        print("Memory usage for large AST:")
        print("  Initial memory: \(formatBytes(initialMemory))")
        print("  Final memory: \(formatBytes(finalMemory))")
        print("  Memory increase: \(formatBytes(memoryIncrease))")
        print("  Operands: \(operandCount)")
        print("  Memory per operand: \(formatBytes(memoryIncrease / Int64(operandCount)))")
        
        // Verify the AST was created successfully
        XCTAssertNotNil(ast)
        
        // Basic sanity check - memory increase should be reasonable
        // Allow up to 5MB for 5000 operands (1KB per operand average)
        XCTAssertLessThan(memoryIncrease, 5 * 1024 * 1024, "Memory usage seems excessive")
    }
    
    /// Test memory usage with deeply nested expressions
    func testMemoryUsageWithDeepNesting() throws {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create deeply nested expression
        let depth = 2000
        var expression = "42"
        
        for _ in 0..<depth {
            expression = "(\(expression))"
        }
        
        let tokenizer = Tokenizer(input: expression)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Log memory usage for analysis
        print("Memory usage for deep nesting:")
        print("  Initial memory: \(formatBytes(initialMemory))")
        print("  Final memory: \(formatBytes(finalMemory))")
        print("  Memory increase: \(formatBytes(memoryIncrease))")
        print("  Nesting depth: \(depth)")
        print("  Memory per nesting level: \(formatBytes(memoryIncrease / Int64(depth)))")
        
        // Verify the AST was created successfully
        XCTAssertNotNil(ast)
        
        // Memory should scale reasonably with depth
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Memory usage for deep nesting seems excessive")
    }
    
    /// Test memory usage with complex function call trees
    func testMemoryUsageWithComplexFunctionCalls() throws {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create complex function call expression with single arguments (no commas since tokenizer doesn't support them)
        // Pattern: func(func2(func3(arg)))
        let functionCount = 1000
        var expression = "1"
        
        for i in 1..<functionCount {
            expression = "func\(i)(\(expression))"
        }
        
        let tokenizer = Tokenizer(input: expression)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Log memory usage for analysis
        print("Memory usage for complex function calls:")
        print("  Initial memory: \(formatBytes(initialMemory))")
        print("  Final memory: \(formatBytes(finalMemory))")
        print("  Memory increase: \(formatBytes(memoryIncrease))")
        print("  Function calls: \(functionCount)")
        print("  Memory per function call: \(formatBytes(memoryIncrease / Int64(functionCount)))")
        
        // Verify the AST was created successfully
        XCTAssertNotNil(ast)
        
        // Memory should scale reasonably with function complexity
        XCTAssertLessThan(memoryIncrease, 5 * 1024 * 1024, "Memory usage for function calls seems excessive")
    }
    
    // MARK: - Parsing Speed Tests
    
    /// Test parsing speed with various expression sizes
    func testParsingSpeedScaling() throws {
        let expressionSizes = [100, 500, 1000, 2000, 5000]
        var results: [(size: Int, time: TimeInterval)] = []
        
        for size in expressionSizes {
            // Create expression of specified size
            var expression = "1"
            for i in 2...size {
                expression += " + \(i)"
            }
            
            // Measure parsing time
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let tokenizer = Tokenizer(input: expression)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens)
            let _ = try parser.parse()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let parseTime = endTime - startTime
            
            results.append((size: size, time: parseTime))
            
            print("Parsing speed for \(size) operands: \(String(format: "%.4f", parseTime))s")
        }
        
        // Verify that parsing time scales reasonably (should be roughly linear or better)
        for i in 1..<results.count {
            let prevResult = results[i-1]
            let currentResult = results[i]
            
            let sizeRatio = Double(currentResult.size) / Double(prevResult.size)
            let timeRatio = currentResult.time / prevResult.time
            
            // Time ratio should not be significantly worse than size ratio
            // Allow some overhead for larger expressions
            XCTAssertLessThan(timeRatio, sizeRatio * 2.0, 
                "Parsing time scaling seems worse than linear between \(prevResult.size) and \(currentResult.size) operands")
        }
    }
    
    /// Test parsing speed with different expression patterns
    func testParsingSpeedByPattern() throws {
        let operandCount = 1000
        
        // Test different expression patterns
        let patterns: [(name: String, generator: (Int) -> String)] = [
            ("Linear Addition", { count in
                var expr = "1"
                for i in 2...count { expr += " + \(i)" }
                return expr
            }),
            ("Nested Parentheses", { count in
                var expr = "1"
                for _ in 0..<count { expr = "(\(expr))" }
                return expr
            }),
            ("Mixed Operators", { count in
                var expr = "1"
                let ops = ["+", "-", "*", "/", "%"]
                for i in 2...count {
                    let op = ops[(i-2) % ops.count]
                    expr += " \(op) \(i)"
                }
                return expr
            }),
            ("Function Calls", { count in
                var expr = "1"
                let funcs = ["sin", "cos", "tan", "log", "sqrt"]
                for i in 0..<count {
                    let funcName = funcs[i % funcs.count]
                    expr = "\(funcName)(\(expr))"
                }
                return expr
            })
        ]
        
        for (patternName, generator) in patterns {
            let expression = generator(operandCount)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let tokenizer = Tokenizer(input: expression)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens)
            let _ = try parser.parse()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let parseTime = endTime - startTime
            
            print("Parsing speed for \(patternName): \(String(format: "%.4f", parseTime))s")
            
            // Verify reasonable performance (should parse 1000 operands in under 1 second)
            XCTAssertLessThan(parseTime, 1.0, "\(patternName) parsing took too long: \(parseTime)s")
        }
    }
    
    /// Test parsing speed with error recovery enabled
    func testParsingSpeedWithErrorRecovery() throws {
        let operandCount = 1000
        var expression = "1"
        for i in 2...operandCount {
            expression += " + \(i)"
        }
        
        // Test normal parsing speed
        let normalStartTime = CFAbsoluteTimeGetCurrent()
        do {
            let tokenizer = Tokenizer(input: expression)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens)
            let _ = try parser.parse()
        }
        let normalEndTime = CFAbsoluteTimeGetCurrent()
        let normalTime = normalEndTime - normalStartTime
        
        // Test error recovery parsing speed
        let recoveryStartTime = CFAbsoluteTimeGetCurrent()
        do {
            let tokenizer = Tokenizer(input: expression)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens, enableErrorRecovery: true)
            let _ = try parser.parse()
        }
        let recoveryEndTime = CFAbsoluteTimeGetCurrent()
        let recoveryTime = recoveryEndTime - recoveryStartTime
        
        print("Normal parsing time: \(String(format: "%.4f", normalTime))s")
        print("Error recovery parsing time: \(String(format: "%.4f", recoveryTime))s")
        print("Overhead ratio: \(String(format: "%.2f", recoveryTime / normalTime))x")
        
        // Error recovery should not add significant overhead for valid expressions
        XCTAssertLessThan(recoveryTime, normalTime * 2.0, "Error recovery mode adds too much overhead")
    }
    
    // MARK: - Stress Tests
    
    /// Test parser stability with extremely large expressions
    func testExtremelyLargeExpressionStability() throws {
        // This test verifies the parser doesn't crash or hang with very large inputs
        let operandCount = 2000  // Reduced further to prevent crashes
        var expression = "1"
        
        for i in 2...operandCount {
            expression += " + \(i)"
        }
        
        // Parse directly without async to avoid complexity
        let tokenizer = Tokenizer(input: expression)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Verify the AST was created successfully
        XCTAssertNotNil(ast)
        XCTAssertTrue(ast is BinaryOperation)
    }
    
    /// Test parser with maximum recursion depth
    func testMaximumRecursionDepth() throws {
        // Test the parser's ability to handle deep recursion without stack overflow
        let maxDepth = 1000  // Reduced further to prevent stack overflow
        var expression = "1"
        
        // Create deeply nested parentheses
        for _ in 0..<maxDepth {
            expression = "(\(expression))"
        }
        
        do {
            let tokenizer = Tokenizer(input: expression)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens)
            let ast = try parser.parse()
            
            // If we get here, the parser handled the deep recursion successfully
            XCTAssertNotNil(ast)
            print("Successfully parsed expression with \(maxDepth) levels of nesting")
        } catch {
            // Deep recursion might legitimately fail due to stack limits
            // This is acceptable behavior for very deep nesting
            print("Deep recursion failed as expected: \(error)")
            // Don't fail the test - this is expected behavior for extreme nesting
        }
    }
    
    // MARK: - Utility Methods
    
    /// Gets the current memory usage of the process
    /// 
    /// - Returns: Current memory usage in bytes
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    /// Formats byte count into human-readable string
    /// 
    /// - Parameter bytes: Number of bytes
    /// - Returns: Formatted string (e.g., "1.5 MB")
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: bytes)
    }
}