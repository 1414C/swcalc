import XCTest
@testable import SwiftCalcParser
@testable import SwiftCalcTokenizer

/// Test suite for variable type inference pass
/// 
/// This test suite verifies that the VariableTypeInferencePass correctly
/// infers variable types based on their usage and the type promotion rules.
final class VariableTypeInferenceTests: XCTestCase {
    
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
    
    /// Creates a program AST from the given input string
    /// 
    /// - Parameter input: The multi-line calculator program to parse
    /// - Returns: The parsed program AST
    /// - Throws: Parsing errors
    private func createProgramAST(from input: String) throws -> Program {
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        return try parser.parseProgram()
    }
    
    /// Runs both number analysis and variable type inference on an AST
    /// 
    /// - Parameter ast: The AST to analyze
    /// - Returns: The variable type inference result
    /// - Throws: Analysis errors
    private func runTypeInference(on ast: SwiftCalcParser.Expression) throws -> VariableTypeInferenceResult {
        // First run number type analysis
        let numberPass = NumberTypeAnalysisPass()
        let numberResult = try numberPass.run(on: ast)
        
        // Then run variable type inference
        let typePass = VariableTypeInferencePass()
        return try typePass.run(on: ast, with: numberResult)
    }
    
    // MARK: - Basic Variable Type Inference Tests
    
    /// Test simple integer assignment
    func testSimpleIntegerAssignment() throws {
        let ast = try createAST(from: "x = 42")
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 1)
        XCTAssertEqual(result.integerVariableCount, 1)
        XCTAssertEqual(result.floatVariableCount, 0)
        
        let xInfo = result.typeInfo(for: "x")
        XCTAssertNotNil(xInfo)
        XCTAssertEqual(xInfo?.inferredType, NumberType.integer)
        XCTAssertEqual(xInfo?.name, "x")
    }
    
    /// Test simple float assignment
    func testSimpleFloatAssignment() throws {
        let ast = try createAST(from: "x = 3.14")
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 1)
        XCTAssertEqual(result.integerVariableCount, 0)
        XCTAssertEqual(result.floatVariableCount, 1)
        
        let xInfo = result.typeInfo(for: "x")
        XCTAssertNotNil(xInfo)
        XCTAssertEqual(xInfo?.inferredType, NumberType.float)
        XCTAssertEqual(xInfo?.name, "x")
    }
    
    // MARK: - Type Promotion Tests
    
    /// Test integer + integer = integer
    func testIntegerPlusInteger() throws {
        let program = """
        a = 5
        b = 10
        result = a + b
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 3)
        XCTAssertEqual(result.integerVariableCount, 3)
        XCTAssertEqual(result.floatVariableCount, 0)
        
        XCTAssertEqual(result.typeInfo(for: "a")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "b")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "result")?.inferredType, NumberType.integer)
    }
    
    /// Test integer + float = float
    func testIntegerPlusFloat() throws {
        let program = """
        a = 5
        b = 3.14
        result = a + b
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 3)
        XCTAssertEqual(result.integerVariableCount, 1)
        XCTAssertEqual(result.floatVariableCount, 2)
        
        XCTAssertEqual(result.typeInfo(for: "a")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "b")?.inferredType, NumberType.float)
        XCTAssertEqual(result.typeInfo(for: "result")?.inferredType, NumberType.float)
    }
    
    /// Test float + float = float
    func testFloatPlusFloat() throws {
        let program = """
        a = 2.5
        b = 3.14
        result = a + b
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 3)
        XCTAssertEqual(result.integerVariableCount, 0)
        XCTAssertEqual(result.floatVariableCount, 3)
        
        XCTAssertEqual(result.typeInfo(for: "a")?.inferredType, NumberType.float)
        XCTAssertEqual(result.typeInfo(for: "b")?.inferredType, NumberType.float)
        XCTAssertEqual(result.typeInfo(for: "result")?.inferredType, NumberType.float)
    }
    
    // MARK: - Complex Expression Tests
    
    /// Test mixed operations with multiple variables
    func testMixedOperations() throws {
        let program = """
        intVar = 10
        floatVar = 2.5
        mixedResult = intVar * floatVar
        intResult = intVar + 5
        floatResult = floatVar * 2.0
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 5)
        XCTAssertEqual(result.integerVariableCount, 2)
        XCTAssertEqual(result.floatVariableCount, 3)
        
        XCTAssertEqual(result.typeInfo(for: "intVar")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "floatVar")?.inferredType, NumberType.float)
        XCTAssertEqual(result.typeInfo(for: "mixedResult")?.inferredType, NumberType.float)
        XCTAssertEqual(result.typeInfo(for: "intResult")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "floatResult")?.inferredType, NumberType.float)
    }
    
    /// Test function calls (should return float)
    func testFunctionCallInference() throws {
        let program = """
        x = 5
        result = sin(x)
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 2)
        XCTAssertEqual(result.integerVariableCount, 1)
        XCTAssertEqual(result.floatVariableCount, 1)
        
        XCTAssertEqual(result.typeInfo(for: "x")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "result")?.inferredType, NumberType.float)
    }
    
    /// Test parenthesized expressions
    func testParenthesizedExpressions() throws {
        let program = """
        a = 5
        b = 10
        result = (a + b) * 2
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 3)
        XCTAssertEqual(result.integerVariableCount, 3)
        XCTAssertEqual(result.floatVariableCount, 0)
        
        XCTAssertEqual(result.typeInfo(for: "a")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "b")?.inferredType, NumberType.integer)
        XCTAssertEqual(result.typeInfo(for: "result")?.inferredType, NumberType.integer)
    }
    
    // MARK: - Variable Reassignment Tests
    
    /// Test variable type promotion through reassignment
    func testVariableTypePromotion() throws {
        let program = """
        x = 5
        x = 3.14
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 1)
        XCTAssertEqual(result.integerVariableCount, 0)
        XCTAssertEqual(result.floatVariableCount, 1)
        
        let xInfo = result.typeInfo(for: "x")
        XCTAssertNotNil(xInfo)
        XCTAssertEqual(xInfo?.inferredType, NumberType.float)
        XCTAssertTrue(xInfo?.reason.contains("Type promotion") == true)
    }
    
    // MARK: - Edge Cases
    
    /// Test expression with no variables
    func testExpressionWithNoVariables() throws {
        let ast = try createAST(from: "5 + 3")
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 0)
        XCTAssertEqual(result.integerVariableCount, 0)
        XCTAssertEqual(result.floatVariableCount, 0)
    }
    
    /// Test variable used before assignment (should default to integer)
    func testVariableUsedBeforeAssignment() throws {
        let program = """
        result = x + 5
        x = 10
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        XCTAssertEqual(result.totalVariableCount, 2)
        
        let xInfo = result.typeInfo(for: "x")
        let resultInfo = result.typeInfo(for: "result")
        
        XCTAssertNotNil(xInfo)
        XCTAssertNotNil(resultInfo)
        XCTAssertEqual(xInfo?.inferredType, NumberType.integer)
        XCTAssertEqual(resultInfo?.inferredType, NumberType.integer)
    }
    
    // MARK: - Convenience Method Tests
    
    /// Test the convenience method on Expression
    func testExpressionConvenienceMethod() throws {
        let ast = try createAST(from: "x = 42")
        
        // First get number analysis
        let numberResult = try ast.analyzeNumberTypes()
        
        // Then run variable type inference
        let result = try ast.inferVariableTypes(with: numberResult)
        
        XCTAssertEqual(result.totalVariableCount, 1)
        XCTAssertEqual(result.typeInfo(for: "x")?.inferredType, NumberType.integer)
    }
    
    // MARK: - Result Filtering Tests
    
    /// Test result filtering methods
    func testResultFiltering() throws {
        let program = """
        intVar1 = 5
        intVar2 = 10
        floatVar1 = 3.14
        floatVar2 = 2.5
        mixedResult = intVar1 + floatVar1
        """
        
        let ast = try createProgramAST(from: program)
        let result = try runTypeInference(on: ast)
        
        let integerVars = result.variables(ofType: NumberType.integer)
        let floatVars = result.variables(ofType: NumberType.float)
        
        XCTAssertEqual(integerVars.count, 2)
        XCTAssertEqual(floatVars.count, 3)
        
        let integerNames = integerVars.map { $0.name }.sorted()
        let floatNames = floatVars.map { $0.name }.sorted()
        
        XCTAssertEqual(integerNames, ["intVar1", "intVar2"])
        XCTAssertEqual(floatNames, ["floatVar1", "floatVar2", "mixedResult"])
    }
    
    // MARK: - Error Handling Tests
    
    /// Test error when number analysis is not provided
    func testErrorWithoutNumberAnalysis() throws {
        let ast = try createAST(from: "x = 42")
        let typePass = VariableTypeInferencePass()
        
        XCTAssertThrowsError(try typePass.run(on: ast)) { error in
            XCTAssertTrue(error is ASTPassError)
            if case ASTPassError.invalidInput(let message) = error {
                XCTAssertTrue(message.contains("Number type analysis results are required"))
            } else {
                XCTFail("Expected invalidInput error")
            }
        }
    }
}