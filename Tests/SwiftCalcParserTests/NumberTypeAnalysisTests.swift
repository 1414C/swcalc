import XCTest
@testable import SwiftCalcParser
@testable import SwiftCalcTokenizer

/// Test suite for number type analysis pass
/// 
/// This test suite verifies that the NumberTypeAnalysisPass correctly
/// identifies integer and floating-point literals in various AST structures.
final class NumberTypeAnalysisTests: XCTestCase {
    
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
    
    // MARK: - Basic Number Type Detection Tests
    
    /// Test integer literal detection
    func testIntegerLiteralDetection() throws {
        let ast = try createAST(from: "42")
        let pass = NumberTypeAnalysisPass()
        let result = try pass.run(on: ast)
        
        XCTAssertEqual(result.totalCount, 1)
        XCTAssertEqual(result.integerCount, 1)
        XCTAssertEqual(result.floatCount, 0)
        
        let number = result.numbers.first!
        XCTAssertEqual(number.value, "42")
        XCTAssertEqual(number.type, NumberType.integer)
        XCTAssertEqual(number.numericValue, 42.0)
    }
    
    /// Test floating-point literal detection
    func testFloatLiteralDetection() throws {
        let ast = try createAST(from: "3.14")
        let pass = NumberTypeAnalysisPass()
        let result = try pass.run(on: ast)
        
        XCTAssertEqual(result.totalCount, 1)
        XCTAssertEqual(result.integerCount, 0)
        XCTAssertEqual(result.floatCount, 1)
        
        let number = result.numbers.first!
        XCTAssertEqual(number.value, "3.14")
        XCTAssertEqual(number.type, NumberType.float)
        XCTAssertEqual(number.numericValue, 3.14)
    }
    
    /// Test mixed integer and float in binary operation
    func testMixedNumbersInBinaryOperation() throws {
        let ast = try createAST(from: "42 + 3.14")
        let pass = NumberTypeAnalysisPass()
        let result = try pass.run(on: ast)
        
        XCTAssertEqual(result.totalCount, 2)
        XCTAssertEqual(result.integerCount, 1)
        XCTAssertEqual(result.floatCount, 1)
        
        let integers = result.numbers(ofType: NumberType.integer)
        let floats = result.numbers(ofType: NumberType.float)
        
        XCTAssertEqual(integers.count, 1)
        XCTAssertEqual(integers.first?.value, "42")
        
        XCTAssertEqual(floats.count, 1)
        XCTAssertEqual(floats.first?.value, "3.14")
    }
    
    /// Test expression with no numbers
    func testExpressionWithNoNumbers() throws {
        let ast = try createAST(from: "x + y")
        let pass = NumberTypeAnalysisPass()
        let result = try pass.run(on: ast)
        
        XCTAssertEqual(result.totalCount, 0)
        XCTAssertEqual(result.integerCount, 0)
        XCTAssertEqual(result.floatCount, 0)
    }
    
    /// Test the convenience method on Expression
    func testExpressionConvenienceMethod() throws {
        let ast = try createAST(from: "42 + 3.14")
        let result = try ast.analyzeNumberTypes()
        
        XCTAssertEqual(result.totalCount, 2)
        XCTAssertEqual(result.integerCount, 1)
        XCTAssertEqual(result.floatCount, 1)
    }
    
    // MARK: - NumberType Tests
    
    /// Test NumberType description
    func testNumberTypeDescription() {
        XCTAssertEqual(NumberType.integer.description, "integer")
        XCTAssertEqual(NumberType.float.description, "float")
    }
    
    /// Test NumberType equality
    func testNumberTypeEquality() {
        XCTAssertEqual(NumberType.integer, NumberType.integer)
        XCTAssertEqual(NumberType.float, NumberType.float)
        XCTAssertNotEqual(NumberType.integer, NumberType.float)
    }
    
    // MARK: - NumberTypeInfo Tests
    
    /// Test NumberTypeInfo creation and properties
    func testNumberTypeInfoCreation() {
        let position = Position(line: 1, column: 5)
        let info = NumberTypeInfo(
            value: "42",
            type: .integer,
            position: position,
            numericValue: 42.0
        )
        
        XCTAssertEqual(info.value, "42")
        XCTAssertEqual(info.type, NumberType.integer)
        XCTAssertEqual(info.position, position)
        XCTAssertEqual(info.numericValue, 42.0)
    }
    
    // MARK: - NumberTypeAnalysisResult Tests
    
    /// Test NumberTypeAnalysisResult filtering methods
    func testAnalysisResultFiltering() throws {
        let ast = try createAST(from: "42 + 3.14 + 5 + 2.5")
        let pass = NumberTypeAnalysisPass()
        let result = try pass.run(on: ast)
        
        let integers = result.numbers(ofType: NumberType.integer)
        let floats = result.numbers(ofType: NumberType.float)
        
        XCTAssertEqual(integers.count, 2)
        XCTAssertEqual(floats.count, 2)
        
        let integerValues = integers.map { $0.value }.sorted()
        let floatValues = floats.map { $0.value }.sorted()
        
        XCTAssertEqual(integerValues, ["42", "5"])
        XCTAssertEqual(floatValues, ["2.5", "3.14"])
    }
}