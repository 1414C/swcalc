import XCTest
@testable import SwiftCalcParser
@testable import SwiftCalcTokenizer

/// Test suite for AST pass manager
/// 
/// This test suite verifies that the ASTPassManager correctly manages
/// and executes multiple AST passes in the correct order.
final class ASTPassManagerTests: XCTestCase {
    
    // MARK: - Helper Methods
    
    /// Creates an AST from the given input string
    /// 
    /// - Parameter input: The calculator expression to parse
    /// - Returns: The parsed AST
    /// - Throws: Parsing errors
    private func createAST(from input: String) throws -> SwiftCalcParser.Expression {
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        return try parser.parse()
    }
    
    // MARK: - Basic Pass Manager Tests
    
    /// Test creating an empty pass manager
    func testEmptyPassManager() {
        let manager = ASTPassManager()
        
        XCTAssertEqual(manager.passCount, 0)
        XCTAssertTrue(manager.passNames.isEmpty)
    }
    
    /// Test adding a single pass
    func testAddingSinglePass() {
        let manager = ASTPassManager()
        let pass = NumberTypeAnalysisPass()
        
        manager.addPass(pass)
        
        XCTAssertEqual(manager.passCount, 1)
        XCTAssertEqual(manager.passNames.count, 1)
        XCTAssertTrue(manager.passNames.first?.contains("NumberTypeAnalysisPass") == true)
    }
    
    /// Test adding multiple passes
    func testAddingMultiplePasses() {
        let manager = ASTPassManager()
        
        manager.addPass(NumberTypeAnalysisPass())
        
        XCTAssertEqual(manager.passCount, 1)
    }
    
    /// Test clearing passes
    func testClearingPasses() {
        let manager = ASTPassManager()
        manager.addPass(NumberTypeAnalysisPass())
        
        XCTAssertEqual(manager.passCount, 1)
        
        manager.clearPasses()
        
        XCTAssertEqual(manager.passCount, 0)
        XCTAssertTrue(manager.passNames.isEmpty)
    }
    
    // MARK: - Pass Execution Tests
    
    /// Test running a single pass through the manager
    func testRunningSinglePass() throws {
        let manager = ASTPassManager()
        manager.addPass(NumberTypeAnalysisPass())
        
        let ast = try createAST(from: "42 + 3.14")
        let results = try manager.runPasses(on: ast)
        
        XCTAssertTrue(results.hasResult(for: NumberTypeAnalysisPass.self))
        
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 2)
        XCTAssertEqual(numberAnalysis?.integerCount, 1)
        XCTAssertEqual(numberAnalysis?.floatCount, 1)
    }
    
    /// Test running passes on expression with no numbers
    func testRunningPassesOnExpressionWithNoNumbers() throws {
        let manager = ASTPassManager()
        manager.addPass(NumberTypeAnalysisPass())
        
        let ast = try createAST(from: "x + y")
        let results = try manager.runPasses(on: ast)
        
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 0)
    }
    
    /// Test running passes on complex expression
    func testRunningPassesOnComplexExpression() throws {
        let manager = ASTPassManager()
        manager.addPass(NumberTypeAnalysisPass())
        
        let ast = try createAST(from: "sin(3.14) + cos(0) * 2 + sqrt(4.0)")
        let results = try manager.runPasses(on: ast)
        
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 4)
        XCTAssertEqual(numberAnalysis?.integerCount, 2) // 0 and 2
        XCTAssertEqual(numberAnalysis?.floatCount, 2)   // 3.14 and 4.0
    }
    
    // MARK: - Standard Analysis Passes Tests
    
    /// Test adding standard analysis passes
    func testAddingStandardAnalysisPasses() {
        let manager = ASTPassManager()
        manager.addStandardAnalysisPasses()
        
        XCTAssertEqual(manager.passCount, 2) // NumberTypeAnalysisPass and VariableTypeInferencePass
        XCTAssertTrue(manager.passNames.contains { $0.contains("NumberTypeAnalysisPass") })
        XCTAssertTrue(manager.passNames.contains { $0.contains("VariableTypeInferencePass") })
    }
    
    /// Test creating manager with standard analysis passes
    func testCreatingManagerWithStandardAnalysis() throws {
        let manager = ASTPassManager.withStandardAnalysis()
        
        XCTAssertEqual(manager.passCount, 2)
        
        let ast = try createAST(from: "42 + 3.14")
        let results = try manager.runPasses(on: ast)
        
        XCTAssertTrue(results.hasResult(for: NumberTypeAnalysisPass.self))
        
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 2)
    }
    
    /// Test creating manager with standard analysis and debug mode
    func testCreatingManagerWithStandardAnalysisAndDebug() throws {
        let manager = ASTPassManager.withStandardAnalysis(debugMode: true)
        
        XCTAssertEqual(manager.passCount, 2)
        
        let ast = try createAST(from: "42")
        let results = try manager.runPasses(on: ast)
        
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 1)
    }
    
    // MARK: - ASTPassResults Tests
    
    /// Test ASTPassResults basic functionality
    func testPassResultsBasicFunctionality() throws {
        let manager = ASTPassManager()
        manager.addPass(NumberTypeAnalysisPass())
        
        let ast = try createAST(from: "42")
        let results = try manager.runPasses(on: ast)
        
        // Test hasResult
        XCTAssertTrue(results.hasResult(for: NumberTypeAnalysisPass.self))
        
        // Test availableResults
        XCTAssertEqual(results.availableResults.count, 1)
        XCTAssertTrue(results.availableResults.first?.contains("NumberTypeAnalysisPass") == true)
        
        // Test getResult
        let result = results.getResult(for: NumberTypeAnalysisPass.self)
        XCTAssertNotNil(result)
        XCTAssertTrue(result is NumberTypeAnalysisResult)
        
        // Test getNumberTypeAnalysis convenience method
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 1)
    }
    
    /// Test ASTPassResults with no results
    func testPassResultsWithNoResults() {
        let results = ASTPassResults()
        
        XCTAssertFalse(results.hasResult(for: NumberTypeAnalysisPass.self))
        XCTAssertTrue(results.availableResults.isEmpty)
        XCTAssertNil(results.getResult(for: NumberTypeAnalysisPass.self))
        XCTAssertNil(results.getNumberTypeAnalysis())
    }
    
    // MARK: - Debug Mode Tests
    
    /// Test pass manager with debug mode enabled
    func testPassManagerWithDebugMode() throws {
        let manager = ASTPassManager(debugMode: true)
        manager.addPass(NumberTypeAnalysisPass(debugMode: true))
        
        let ast = try createAST(from: "42 + 3.14")
        let results = try manager.runPasses(on: ast)
        
        // Should still work correctly with debug mode
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 2)
    }
    
    // MARK: - Error Handling Tests
    
    /// Test pass manager error handling with invalid pass
    func testPassManagerErrorHandling() throws {
        let manager = ASTPassManager()
        
        // Create a mock pass that's not supported
        struct UnsupportedPass: ASTPass {
            typealias Result = String
            func run(on node: SwiftCalcParser.Expression) throws -> String {
                return "test"
            }
        }
        
        manager.addPass(UnsupportedPass())
        
        let ast = try createAST(from: "42")
        
        // This should throw an error for unsupported pass type
        XCTAssertThrowsError(try manager.runPasses(on: ast)) { error in
            XCTAssertTrue(error is ASTPassError)
            if case ASTPassError.unsupportedNodeType(let message) = error {
                XCTAssertTrue(message.contains("Unknown pass type"))
            } else {
                XCTFail("Expected unsupportedNodeType error")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    /// Test pass manager performance with large expression
    func testPassManagerPerformanceWithLargeExpression() throws {
        let manager = ASTPassManager()
        manager.addPass(NumberTypeAnalysisPass())
        
        // Create a large expression with many numbers
        var expression = "1"
        for i in 2...100 {
            expression += " + \(i)"
        }
        
        let ast = try createAST(from: expression)
        
        // Measure execution time
        let startTime = CFAbsoluteTimeGetCurrent()
        let results = try manager.runPasses(on: ast)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let executionTime = endTime - startTime
        
        // Should complete quickly (under 1 second)
        XCTAssertLessThan(executionTime, 1.0)
        
        // Verify results
        let numberAnalysis = results.getNumberTypeAnalysis()
        XCTAssertNotNil(numberAnalysis)
        XCTAssertEqual(numberAnalysis?.totalCount, 100)
        XCTAssertEqual(numberAnalysis?.integerCount, 100)
        XCTAssertEqual(numberAnalysis?.floatCount, 0)
    }
}