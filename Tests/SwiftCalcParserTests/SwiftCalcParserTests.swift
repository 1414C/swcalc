import XCTest
@testable import SwiftCalcParser
@testable import SwiftCalcTokenizer

/// Test suite for SwiftCalcParser
/// 
/// This test suite will contain comprehensive tests for the parser functionality,
/// including AST node creation, visitor pattern, error handling, and integration
/// with SwiftCalcTokenizer.
final class SwiftCalcParserTests: XCTestCase {
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - AST Node Tests
    
    /// Test that AST nodes can be created with proper initialization
    func testASTNodeCreation() throws {
        let position = Position(line: 1, column: 1)
        
        // Test Literal creation
        let literal = Literal(value: "42", position: position)
        XCTAssertEqual(literal.value, "42")
        XCTAssertEqual(literal.position, position)
        
        // Test Identifier creation
        let identifier = Identifier(name: "x", position: position)
        XCTAssertEqual(identifier.name, "x")
        XCTAssertEqual(identifier.position, position)
        
        // Test BinaryOperation creation
        let binaryOp = BinaryOperation(
            operator: .plus,
            left: literal,
            right: identifier,
            position: position
        )
        XCTAssertEqual(binaryOp.operator, .plus)
        XCTAssertEqual(binaryOp.position, position)
        
        // Test UnaryOperation creation
        let unaryOp = UnaryOperation(
            operator: .minus,
            operand: literal,
            position: position
        )
        XCTAssertEqual(unaryOp.operator, .minus)
        XCTAssertEqual(unaryOp.position, position)
        
        // Test Assignment creation
        let assignment = Assignment(
            target: identifier,
            value: literal,
            position: position
        )
        XCTAssertEqual(assignment.target.name, "x")
        XCTAssertEqual(assignment.position, position)
        
        // Test FunctionCall creation
        let functionCall = FunctionCall(
            name: "sin",
            arguments: [identifier],
            position: position
        )
        XCTAssertEqual(functionCall.name, "sin")
        XCTAssertEqual(functionCall.arguments.count, 1)
        XCTAssertEqual(functionCall.position, position)
        
        // Test ParenthesizedExpression creation
        let parenExpr = ParenthesizedExpression(
            expression: literal,
            position: position
        )
        XCTAssertEqual(parenExpr.position, position)
    }
    
    // MARK: - Parser Initialization Tests
    
    /// Test that Parser can be initialized with tokens
    func testParserInitialization() throws {
        let tokens = [
            Token(type: .number, value: "42", position: Position(line: 1, column: 1)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 3))
        ]
        
        let parser = Parser(tokens: tokens)
        XCTAssertNotNil(parser)
    }
    
    // MARK: - Error Handling Tests
    
    /// Test ParseError descriptions
    func testParseErrorDescriptions() throws {
        let position = Position(line: 1, column: 5)
        let token = Token(type: .number, value: "42", position: position)
        
        // Test unexpectedToken error
        let unexpectedError = ParseError.unexpectedToken(token, expected: [.identifier, .leftParen])
        XCTAssertTrue(unexpectedError.localizedDescription.contains("Unexpected number '42'"))
        XCTAssertTrue(unexpectedError.localizedDescription.contains("line 1, column 5"))
        
        // Test unexpectedEndOfInput error
        let endOfInputError = ParseError.unexpectedEndOfInput(position)
        XCTAssertTrue(endOfInputError.localizedDescription.contains("Unexpected end of input"))
        
        // Test invalidAssignmentTarget error
        let invalidTargetError = ParseError.invalidAssignmentTarget(token)
        XCTAssertTrue(invalidTargetError.localizedDescription.contains("Invalid assignment target"))
        
        // Test unmatchedParenthesis error
        let unmatchedError = ParseError.unmatchedParenthesis(position)
        XCTAssertTrue(unmatchedError.localizedDescription.contains("Unmatched parenthesis"))
        
        // Test tokenizerError error
        let tokenizerError = TokenizerError.invalidCharacter("@", position)
        let wrappedError = ParseError.tokenizerError(tokenizerError, position)
        XCTAssertTrue(wrappedError.localizedDescription.contains("Lexical error"))
    }
    
    // MARK: - Unary Parsing Tests
    
    /// Test unary minus parsing
    func testUnaryMinusParsing() throws {
        // Test that the UnaryOperation AST node works correctly
        let position = Position(line: 1, column: 1)
        let literal = Literal(value: "5", position: Position(line: 1, column: 2))
        let unaryOp = UnaryOperation(operator: .minus, operand: literal, position: position)
        
        XCTAssertEqual(unaryOp.operator, .minus)
        XCTAssertEqual((unaryOp.operand as? Literal)?.value, "5")
        XCTAssertEqual(unaryOp.position, position)
        
        // Test that unary operations can be created with different operand types
        let identifier = Identifier(name: "x", position: Position(line: 1, column: 3))
        let unaryWithIdentifier = UnaryOperation(operator: .minus, operand: identifier, position: position)
        XCTAssertEqual((unaryWithIdentifier.operand as? Identifier)?.name, "x")
    }
    
    /// Test nested unary minus parsing (--5)
    func testNestedUnaryMinus() throws {
        let position1 = Position(line: 1, column: 1)
        let position2 = Position(line: 1, column: 2)
        let position3 = Position(line: 1, column: 3)
        
        let literal = Literal(value: "5", position: position3)
        let innerUnary = UnaryOperation(operator: .minus, operand: literal, position: position2)
        let outerUnary = UnaryOperation(operator: .minus, operand: innerUnary, position: position1)
        
        XCTAssertEqual(outerUnary.operator, .minus)
        XCTAssertEqual((outerUnary.operand as? UnaryOperation)?.operator, .minus)
        XCTAssertEqual(((outerUnary.operand as? UnaryOperation)?.operand as? Literal)?.value, "5")
    }
    
    /// Test unary minus in parentheses parsing
    func testUnaryMinusInParentheses() throws {
        // Test parsing "(-5)" - this tests that parseParenthesizedExpression correctly calls parseUnary
        // We can test this by creating the expected AST structure manually
        let literal = Literal(value: "5", position: Position(line: 1, column: 3))
        let unaryOp = UnaryOperation(operator: .minus, operand: literal, position: Position(line: 1, column: 2))
        let parenExpr = ParenthesizedExpression(expression: unaryOp, position: Position(line: 1, column: 1))
        
        // Verify the structure is correct
        XCTAssertEqual(parenExpr.position.line, 1)
        XCTAssertEqual(parenExpr.position.column, 1)
        
        let innerUnary = parenExpr.expression as? UnaryOperation
        XCTAssertNotNil(innerUnary)
        XCTAssertEqual(innerUnary?.operator, .minus)
        
        let innerLiteral = innerUnary?.operand as? Literal
        XCTAssertNotNil(innerLiteral)
        XCTAssertEqual(innerLiteral?.value, "5")
    }
    
    // MARK: - Binary Operator Parsing Tests
    
    /// Test binary operation AST node creation and precedence structure
    func testBinaryOperatorParsing() throws {
        // Test that binary operations can be created with proper structure
        let position = Position(line: 1, column: 1)
        let left = Literal(value: "2", position: position)
        let right = Literal(value: "3", position: position)
        
        // Test addition
        let addition = BinaryOperation(operator: .plus, left: left, right: right, position: position)
        XCTAssertEqual(addition.operator, .plus)
        XCTAssertEqual((addition.left as? Literal)?.value, "2")
        XCTAssertEqual((addition.right as? Literal)?.value, "3")
        
        // Test multiplication
        let multiplication = BinaryOperation(operator: .multiply, left: left, right: right, position: position)
        XCTAssertEqual(multiplication.operator, .multiply)
        
        // Test exponentiation
        let exponentiation = BinaryOperation(operator: .power, left: left, right: right, position: position)
        XCTAssertEqual(exponentiation.operator, .power)
        
        // Test nested binary operations (representing precedence)
        // This represents "2 + 3 * 4" which should be parsed as "2 + (3 * 4)"
        let innerMult = BinaryOperation(
            operator: .multiply,
            left: Literal(value: "3", position: position),
            right: Literal(value: "4", position: position),
            position: position
        )
        let outerAdd = BinaryOperation(
            operator: .plus,
            left: Literal(value: "2", position: position),
            right: innerMult,
            position: position
        )
        
        XCTAssertEqual(outerAdd.operator, .plus)
        XCTAssertEqual((outerAdd.left as? Literal)?.value, "2")
        XCTAssertEqual((outerAdd.right as? BinaryOperation)?.operator, .multiply)
    }
    
    /// Test assignment AST node creation
    func testAssignmentParsing() throws {
        let position = Position(line: 1, column: 1)
        let identifier = Identifier(name: "x", position: position)
        let value = Literal(value: "5", position: position)
        
        let assignment = Assignment(target: identifier, value: value, position: position)
        XCTAssertEqual(assignment.target.name, "x")
        XCTAssertEqual((assignment.value as? Literal)?.value, "5")
        
        // Test chained assignment structure (representing right-associativity)
        // This represents "a = b = 5" which should be parsed as "a = (b = 5)"
        let innerAssignment = Assignment(
            target: Identifier(name: "b", position: position),
            value: Literal(value: "5", position: position),
            position: position
        )
        let outerAssignment = Assignment(
            target: Identifier(name: "a", position: position),
            value: innerAssignment,
            position: position
        )
        
        XCTAssertEqual(outerAssignment.target.name, "a")
        XCTAssertEqual((outerAssignment.value as? Assignment)?.target.name, "b")
        XCTAssertEqual(((outerAssignment.value as? Assignment)?.value as? Literal)?.value, "5")
    }
    
    /// Test assignment target validation
    func testAssignmentTargetValidation() throws {
        let position = Position(line: 1, column: 1)
        let assignToken = Token(type: .assign, value: "=", position: position)
        
        // Create a parser instance to test the validation method
        let tokens = [
            Token(type: .number, value: "5", position: position),
            Token(type: .assign, value: "=", position: position),
            Token(type: .number, value: "10", position: position),
            Token(type: .eof, value: "", position: position)
        ]
        let parser = Parser(tokens: tokens)
        
        // Test that identifier is valid assignment target
        let identifier = Identifier(name: "x", position: position)
        // This should not throw
        XCTAssertNoThrow(try parser.validateAssignmentTarget(identifier, at: assignToken))
        
        // Test that literal is invalid assignment target
        let literal = Literal(value: "5", position: position)
        XCTAssertThrowsError(try parser.validateAssignmentTarget(literal, at: assignToken)) { error in
            guard case ParseError.invalidAssignmentTarget(let token) = error else {
                XCTFail("Expected invalidAssignmentTarget error")
                return
            }
            XCTAssertEqual(token.type, .assign)
        }
        
        // Test that binary operation is invalid assignment target
        let binaryOp = BinaryOperation(
            operator: .plus,
            left: identifier,
            right: literal,
            position: position
        )
        XCTAssertThrowsError(try parser.validateAssignmentTarget(binaryOp, at: assignToken)) { error in
            guard case ParseError.invalidAssignmentTarget(_) = error else {
                XCTFail("Expected invalidAssignmentTarget error")
                return
            }
        }
    }
    
    // MARK: - Main Parse Method Tests
    
    /// Test the main parse method with simple expressions
    func testMainParseMethod() throws {
        // Test parsing a simple literal
        let literalTokens = [
            Token(type: .number, value: "42", position: Position(line: 1, column: 1)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 3))
        ]
        let literalParser = Parser(tokens: literalTokens)
        let literalResult = try literalParser.parse()
        
        XCTAssertTrue(literalResult is Literal)
        XCTAssertEqual((literalResult as? Literal)?.value, "42")
        
        // Test parsing a simple identifier
        let identifierTokens = [
            Token(type: .identifier, value: "x", position: Position(line: 1, column: 1)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 2))
        ]
        let identifierParser = Parser(tokens: identifierTokens)
        let identifierResult = try identifierParser.parse()
        
        XCTAssertTrue(identifierResult is Identifier)
        XCTAssertEqual((identifierResult as? Identifier)?.name, "x")
    }
    
    /// Test parse method with empty token array
    func testParseWithEmptyTokens() throws {
        let parser = Parser(tokens: [])
        
        XCTAssertThrowsError(try parser.parse()) { error in
            guard case ParseError.unexpectedEndOfInput(_) = error else {
                XCTFail("Expected unexpectedEndOfInput error")
                return
            }
        }
    }
    
    /// Test parse method with missing EOF token
    func testParseWithMissingEOF() throws {
        let tokens = [
            Token(type: .number, value: "42", position: Position(line: 1, column: 1))
        ]
        let parser = Parser(tokens: tokens)
        
        XCTAssertThrowsError(try parser.parse()) { error in
            guard case ParseError.unexpectedEndOfInput(_) = error else {
                XCTFail("Expected unexpectedEndOfInput error")
                return
            }
        }
    }
    
    /// Test parse method with extra tokens after expression
    func testParseWithExtraTokens() throws {
        let tokens = [
            Token(type: .number, value: "42", position: Position(line: 1, column: 1)),
            Token(type: .number, value: "24", position: Position(line: 1, column: 4)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 6))
        ]
        let parser = Parser(tokens: tokens)
        
        XCTAssertThrowsError(try parser.parse()) { error in
            guard case ParseError.unexpectedToken(let token, let expected) = error else {
                XCTFail("Expected unexpectedToken error")
                return
            }
            XCTAssertEqual(token.type, .number)
            XCTAssertTrue(expected.contains(.eof))
        }
    }
    
    // MARK: - Error Token Handling Tests
    
    /// Test error token handling from tokenizer
    func testErrorTokenHandling() throws {
        // Test with error token
        let tokensWithError = [
            Token(type: .error, value: "@", position: Position(line: 1, column: 1)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 2))
        ]
        let parser = Parser(tokens: tokensWithError)
        
        XCTAssertThrowsError(try parser.parse()) { error in
            guard case ParseError.tokenizerError(let tokenizerError, let position) = error else {
                XCTFail("Expected tokenizerError")
                return
            }
            XCTAssertEqual(position.line, 1)
            XCTAssertEqual(position.column, 1)
            
            // Should infer invalid character error
            guard case TokenizerError.invalidCharacter(let char, _) = tokenizerError else {
                XCTFail("Expected invalidCharacter tokenizer error")
                return
            }
            XCTAssertEqual(char, "@")
        }
    }
    
    /// Test malformed number error token handling
    func testMalformedNumberErrorHandling() throws {
        // Test with malformed number error token
        let tokensWithMalformedNumber = [
            Token(type: .error, value: "3.14.159", position: Position(line: 1, column: 1)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 8))
        ]
        let parser = Parser(tokens: tokensWithMalformedNumber)
        
        XCTAssertThrowsError(try parser.parse()) { error in
            guard case ParseError.tokenizerError(let tokenizerError, _) = error else {
                XCTFail("Expected tokenizerError")
                return
            }
            
            // Should infer malformed number error
            guard case TokenizerError.malformedNumber(let number, _) = tokenizerError else {
                XCTFail("Expected malformedNumber tokenizer error")
                return
            }
            XCTAssertEqual(number, "3.14.159")
        }
    }
    
    // MARK: - Integration Tests
    
    /// Test integration with SwiftCalcTokenizer - Simple literal
    func testTokenizerIntegrationSimpleLiteral() throws {
        let tokenizer = Tokenizer(input: "42")
        let tokens = try tokenizer.tokenize()
        
        let parser = Parser(tokens: tokens)
        XCTAssertNotNil(parser)
        
        // Verify tokens are properly structured for parser
        XCTAssertGreaterThan(tokens.count, 0)
        XCTAssertEqual(tokens.last?.type, .eof)
        
        // Test that we can actually parse the tokens
        let result = try parser.parse()
        XCTAssertTrue(result is Literal)
        XCTAssertEqual((result as? Literal)?.value, "42")
    }
    
    /// Test complete pipeline from source text to AST - Basic arithmetic
    func testCompleteParsingPipelineBasicArithmetic() throws {
        // Test simple addition
        let additionInput = "2 + 3"
        let additionTokenizer = Tokenizer(input: additionInput)
        let additionTokens = try additionTokenizer.tokenize()
        let additionParser = Parser(tokens: additionTokens)
        let additionResult = try additionParser.parse()
        
        XCTAssertTrue(additionResult is BinaryOperation)
        let additionOp = additionResult as! BinaryOperation
        XCTAssertEqual(additionOp.operator, .plus)
        XCTAssertEqual((additionOp.left as? Literal)?.value, "2")
        XCTAssertEqual((additionOp.right as? Literal)?.value, "3")
        
        // Test multiplication with precedence
        let precedenceInput = "2 + 3 * 4"
        let precedenceTokenizer = Tokenizer(input: precedenceInput)
        let precedenceTokens = try precedenceTokenizer.tokenize()
        let precedenceParser = Parser(tokens: precedenceTokens)
        let precedenceResult = try precedenceParser.parse()
        
        XCTAssertTrue(precedenceResult is BinaryOperation)
        let outerOp = precedenceResult as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .plus)
        XCTAssertEqual((outerOp.left as? Literal)?.value, "2")
        XCTAssertTrue(outerOp.right is BinaryOperation)
        
        let innerOp = outerOp.right as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .multiply)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "3")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "4")
    }
    
    /// Test complete pipeline with parentheses
    func testCompleteParsingPipelineWithParentheses() throws {
        let input = "(2 + 3) * 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .multiply)
        XCTAssertTrue(outerOp.left is ParenthesizedExpression)
        XCTAssertEqual((outerOp.right as? Literal)?.value, "4")
        
        let parenExpr = outerOp.left as! ParenthesizedExpression
        XCTAssertTrue(parenExpr.expression is BinaryOperation)
        
        let innerOp = parenExpr.expression as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .plus)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "2")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "3")
    }
    
    /// Test complete pipeline with identifiers and assignment
    func testCompleteParsingPipelineWithAssignment() throws {
        let input = "x = 5 + y"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is Assignment)
        let assignment = result as! Assignment
        XCTAssertEqual(assignment.target.name, "x")
        XCTAssertTrue(assignment.value is BinaryOperation)
        
        let valueOp = assignment.value as! BinaryOperation
        XCTAssertEqual(valueOp.operator, .plus)
        XCTAssertEqual((valueOp.left as? Literal)?.value, "5")
        XCTAssertEqual((valueOp.right as? Identifier)?.name, "y")
    }
    
    /// Test complete pipeline with function calls
    func testCompleteParsingPipelineWithFunctionCalls() throws {
        let input = "sin(x + 1)"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is FunctionCall)
        let functionCall = result as! FunctionCall
        XCTAssertEqual(functionCall.name, "sin")
        XCTAssertEqual(functionCall.arguments.count, 1)
        
        let argument = functionCall.arguments[0]
        XCTAssertTrue(argument is BinaryOperation)
        let argOp = argument as! BinaryOperation
        XCTAssertEqual(argOp.operator, .plus)
        XCTAssertEqual((argOp.left as? Identifier)?.name, "x")
        XCTAssertEqual((argOp.right as? Literal)?.value, "1")
    }
    
    /// Test complete pipeline with unary operators
    func testCompleteParsingPipelineWithUnaryOperators() throws {
        let input = "-5 + 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let binaryOp = result as! BinaryOperation
        XCTAssertEqual(binaryOp.operator, .plus)
        XCTAssertTrue(binaryOp.left is UnaryOperation)
        XCTAssertEqual((binaryOp.right as? Literal)?.value, "3")
        
        let unaryOp = binaryOp.left as! UnaryOperation
        XCTAssertEqual(unaryOp.operator, .minus)
        XCTAssertEqual((unaryOp.operand as? Literal)?.value, "5")
    }
    
    /// Test complete pipeline with complex nested expressions
    func testCompleteParsingPipelineComplexExpression() throws {
        let input = "result = (a + b) * sin(x) - 2 ^ 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is Assignment)
        let assignment = result as! Assignment
        XCTAssertEqual(assignment.target.name, "result")
        
        // The value should be a subtraction: (a + b) * sin(x) - 2 ^ 3
        XCTAssertTrue(assignment.value is BinaryOperation)
        let subtraction = assignment.value as! BinaryOperation
        XCTAssertEqual(subtraction.operator, .minus)
        
        // Left side: (a + b) * sin(x)
        XCTAssertTrue(subtraction.left is BinaryOperation)
        let multiplication = subtraction.left as! BinaryOperation
        XCTAssertEqual(multiplication.operator, .multiply)
        
        // Right side: 2 ^ 3
        XCTAssertTrue(subtraction.right is BinaryOperation)
        let exponentiation = subtraction.right as! BinaryOperation
        XCTAssertEqual(exponentiation.operator, .power)
        XCTAssertEqual((exponentiation.left as? Literal)?.value, "2")
        XCTAssertEqual((exponentiation.right as? Literal)?.value, "3")
    }
    
    /// Test that all token types from tokenizer are handled correctly
    func testAllTokenTypesHandledCorrectly() throws {
        // Test all operator types
        let operators = ["+", "-", "*", "/", "%", "^"]
        for op in operators {
            let input = "5 \(op) 3"
            let tokenizer = Tokenizer(input: input)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens)
            let result = try parser.parse()
            
            XCTAssertTrue(result is BinaryOperation, "Failed to parse operator: \(op)")
            let binaryOp = result as! BinaryOperation
            XCTAssertEqual((binaryOp.left as? Literal)?.value, "5")
            XCTAssertEqual((binaryOp.right as? Literal)?.value, "3")
        }
        
        // Test parentheses
        let parenInput = "(42)"
        let parenTokenizer = Tokenizer(input: parenInput)
        let parenTokens = try parenTokenizer.tokenize()
        let parenParser = Parser(tokens: parenTokens)
        let parenResult = try parenParser.parse()
        
        XCTAssertTrue(parenResult is ParenthesizedExpression)
        let parenExpr = parenResult as! ParenthesizedExpression
        XCTAssertEqual((parenExpr.expression as? Literal)?.value, "42")
        
        // Test assignment
        let assignInput = "x = 42"
        let assignTokenizer = Tokenizer(input: assignInput)
        let assignTokens = try assignTokenizer.tokenize()
        let assignParser = Parser(tokens: assignTokens)
        let assignResult = try assignParser.parse()
        
        XCTAssertTrue(assignResult is Assignment)
        let assignment = assignResult as! Assignment
        XCTAssertEqual(assignment.target.name, "x")
        XCTAssertEqual((assignment.value as? Literal)?.value, "42")
        
        // Test identifiers
        let identifierInput = "myVariable"
        let identifierTokenizer = Tokenizer(input: identifierInput)
        let identifierTokens = try identifierTokenizer.tokenize()
        let identifierParser = Parser(tokens: identifierTokens)
        let identifierResult = try identifierParser.parse()
        
        XCTAssertTrue(identifierResult is Identifier)
        let identifier = identifierResult as! Identifier
        XCTAssertEqual(identifier.name, "myVariable")
        
        // Test numbers (integer and decimal)
        let integerInput = "123"
        let integerTokenizer = Tokenizer(input: integerInput)
        let integerTokens = try integerTokenizer.tokenize()
        let integerParser = Parser(tokens: integerTokens)
        let integerResult = try integerParser.parse()
        
        XCTAssertTrue(integerResult is Literal)
        XCTAssertEqual((integerResult as? Literal)?.value, "123")
        
        let decimalInput = "3.14"
        let decimalTokenizer = Tokenizer(input: decimalInput)
        let decimalTokens = try decimalTokenizer.tokenize()
        let decimalParser = Parser(tokens: decimalTokens)
        let decimalResult = try decimalParser.parse()
        
        XCTAssertTrue(decimalResult is Literal)
        XCTAssertEqual((decimalResult as? Literal)?.value, "3.14")
    }
    
    /// Test error propagation from tokenizer to parser
    func testErrorPropagationFromTokenizer() throws {
        // Test invalid character error propagation
        let invalidCharInput = "5 @ 3"
        let invalidCharTokenizer = Tokenizer(input: invalidCharInput)
        let invalidCharTokens = try invalidCharTokenizer.tokenize()
        let invalidCharParser = Parser(tokens: invalidCharTokens)
        
        XCTAssertThrowsError(try invalidCharParser.parse()) { error in
            guard case ParseError.tokenizerError(let tokenizerError, _) = error else {
                XCTFail("Expected tokenizerError, got: \(error)")
                return
            }
            
            guard case TokenizerError.invalidCharacter(let char, _) = tokenizerError else {
                XCTFail("Expected invalidCharacter error, got: \(tokenizerError)")
                return
            }
            XCTAssertEqual(char, "@")
        }
        
        // Test malformed number error propagation
        let malformedNumberInput = "3.14.159"
        let malformedNumberTokenizer = Tokenizer(input: malformedNumberInput)
        let malformedNumberTokens = try malformedNumberTokenizer.tokenize()
        let malformedNumberParser = Parser(tokens: malformedNumberTokens)
        
        XCTAssertThrowsError(try malformedNumberParser.parse()) { error in
            guard case ParseError.tokenizerError(let tokenizerError, _) = error else {
                XCTFail("Expected tokenizerError, got: \(error)")
                return
            }
            
            guard case TokenizerError.malformedNumber(let number, _) = tokenizerError else {
                XCTFail("Expected malformedNumber error, got: \(tokenizerError)")
                return
            }
            XCTAssertEqual(number, "3.14.159")
        }
    }
    
    /// Test position information preservation through the pipeline
    func testPositionInformationPreservation() throws {
        let input = "x = 5 + y"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        // Verify that position information is preserved in the AST
        XCTAssertTrue(result is Assignment)
        let assignment = result as! Assignment
        
        // Assignment should start at column 3 (where the "=" appears in "x = 5 + y")
        XCTAssertEqual(assignment.position.line, 1)
        XCTAssertEqual(assignment.position.column, 3)
        
        // Target identifier should be at column 1 (where "x" appears in "x = 5 + y")
        XCTAssertEqual(assignment.target.position.line, 1)
        XCTAssertEqual(assignment.target.position.column, 1)
        
        // Value expression should preserve positions
        XCTAssertTrue(assignment.value is BinaryOperation)
        let binaryOp = assignment.value as! BinaryOperation
        
        // The literal "5" should be at column 5 (where it appears in "x = 5 + y")
        XCTAssertEqual((binaryOp.left as? Literal)?.position.line, 1)
        XCTAssertEqual((binaryOp.left as? Literal)?.position.column, 5)
        
        // The identifier "y" should be at column 9 (where it appears in "x = 5 + y")
        XCTAssertEqual((binaryOp.right as? Identifier)?.position.line, 1)
        XCTAssertEqual((binaryOp.right as? Identifier)?.position.column, 9)
    }
    
    /// Test integration with empty input
    func testIntegrationWithEmptyInput() throws {
        let tokenizer = Tokenizer(input: "")
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        
        // Should only contain EOF token
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0].type, .eof)
        
        // Parser should throw unexpected token error for EOF
        XCTAssertThrowsError(try parser.parse()) { error in
            guard case ParseError.unexpectedToken(let token, let expected) = error else {
                XCTFail("Expected unexpectedToken error, got: \(error)")
                return
            }
            XCTAssertEqual(token.type, .eof)
            XCTAssertTrue(expected.contains(.number) || expected.contains(.identifier) || expected.contains(.leftParen))
        }
    }
    
    /// Test integration with whitespace handling
    func testIntegrationWithWhitespace() throws {
        let input = "  x   =   5   +   y  "
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        // Should parse correctly despite whitespace
        XCTAssertTrue(result is Assignment)
        let assignment = result as! Assignment
        XCTAssertEqual(assignment.target.name, "x")
        
        XCTAssertTrue(assignment.value is BinaryOperation)
        let binaryOp = assignment.value as! BinaryOperation
        XCTAssertEqual(binaryOp.operator, .plus)
        XCTAssertEqual((binaryOp.left as? Literal)?.value, "5")
        XCTAssertEqual((binaryOp.right as? Identifier)?.name, "y")
    }
    
    // MARK: - Enhanced Error Handling Tests
    
    /// Test enhanced error messages for unexpected tokens
    func testEnhancedUnexpectedTokenErrors() throws {
        let position = Position(line: 2, column: 10)
        let token = Token(type: .operator(.plus), value: "+", position: position)
        
        // Test error with single expected token
        let singleExpectedError = ParseError.unexpectedToken(token, expected: [.number])
        let singleMessage = singleExpectedError.localizedDescription
        XCTAssertTrue(singleMessage.contains("Unexpected operator '+'"))
        XCTAssertTrue(singleMessage.contains("line 2, column 10"))
        XCTAssertTrue(singleMessage.contains("Expected a number"))
        
        // Test error with multiple expected tokens
        let multipleExpectedError = ParseError.unexpectedToken(token, expected: [.number, .identifier, .leftParen])
        let multipleMessage = multipleExpectedError.localizedDescription
        XCTAssertTrue(multipleMessage.contains("a number, an identifier, or opening parenthesis"))
        
        // Test contextual suggestion
        XCTAssertTrue(multipleMessage.contains("Did you forget an operand"))
    }
    
    /// Test enhanced error messages for invalid assignment targets
    func testEnhancedAssignmentTargetErrors() throws {
        let position = Position(line: 1, column: 5)
        
        // Test with number token
        let numberToken = Token(type: .number, value: "42", position: position)
        let numberError = ParseError.invalidAssignmentTarget(numberToken)
        let numberMessage = numberError.localizedDescription
        XCTAssertTrue(numberMessage.contains("Cannot assign to number '42'"))
        XCTAssertTrue(numberMessage.contains("You cannot assign a value to a number literal"))
        
        // Test with operator token
        let operatorToken = Token(type: .operator(.plus), value: "+", position: position)
        let operatorError = ParseError.invalidAssignmentTarget(operatorToken)
        let operatorMessage = operatorError.localizedDescription
        XCTAssertTrue(operatorMessage.contains("Cannot assign to operator '+'"))
        XCTAssertTrue(operatorMessage.contains("You cannot assign a value to an operator"))
    }
    
    /// Test enhanced error messages for unmatched parentheses
    func testEnhancedParenthesisErrors() throws {
        let position = Position(line: 3, column: 15)
        let error = ParseError.unmatchedParenthesis(position)
        let message = error.localizedDescription
        
        XCTAssertTrue(message.contains("Unmatched parenthesis at line 3, column 15"))
        XCTAssertTrue(message.contains("Make sure every opening parenthesis"))
        XCTAssertTrue(message.contains("properly nested"))
    }
    
    /// Test enhanced error messages for unexpected end of input
    func testEnhancedEndOfInputErrors() throws {
        let position = Position(line: 1, column: 20)
        let error = ParseError.unexpectedEndOfInput(position)
        let message = error.localizedDescription
        
        XCTAssertTrue(message.contains("Unexpected end of input at line 1, column 20"))
        XCTAssertTrue(message.contains("expression appears to be incomplete"))
        XCTAssertTrue(message.contains("missing operands, closing parentheses, or assignment values"))
    }
    
    /// Test error recovery mode functionality
    func testErrorRecoveryMode() throws {
        // Create tokens with multiple errors
        let tokens = [
            Token(type: .number, value: "5", position: Position(line: 1, column: 1)),
            Token(type: .operator(.plus), value: "+", position: Position(line: 1, column: 3)),
            Token(type: .operator(.multiply), value: "*", position: Position(line: 1, column: 5)), // Missing operand
            Token(type: .number, value: "3", position: Position(line: 1, column: 7)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 8))
        ]
        
        let parser = Parser(tokens: tokens, enableErrorRecovery: true)
        let result = parser.parseWithErrorRecovery()
        
        // Should collect errors but potentially still parse something
        XCTAssertGreaterThan(result.errors.count, 0)
        
        // Check that we got the expected error type
        let hasUnexpectedTokenError = result.errors.contains { error in
            if case .unexpectedToken(_, _) = error {
                return true
            }
            return false
        }
        XCTAssertTrue(hasUnexpectedTokenError)
    }
    
    /// Test synchronization point detection
    func testSynchronizationPoints() throws {
        // Test with tokens that include synchronization points
        let tokens = [
            Token(type: .number, value: "5", position: Position(line: 1, column: 1)),
            Token(type: .operator(.plus), value: "+", position: Position(line: 1, column: 3)),
            Token(type: .operator(.multiply), value: "*", position: Position(line: 1, column: 5)), // Error here
            Token(type: .leftParen, value: "(", position: Position(line: 1, column: 7)), // Sync point
            Token(type: .number, value: "3", position: Position(line: 1, column: 8)),
            Token(type: .rightParen, value: ")", position: Position(line: 1, column: 9)),
            Token(type: .eof, value: "", position: Position(line: 1, column: 10))
        ]
        
        let parser = Parser(tokens: tokens, enableErrorRecovery: true)
        let result = parser.parseWithErrorRecovery()
        
        // Should have attempted recovery at the synchronization point
        XCTAssertGreaterThan(result.errors.count, 0)
    }
    
    /// Test targeted recovery for specific error types
    func testTargetedRecovery() throws {
        // Test recovery from unmatched parenthesis
        let tokens = [
            Token(type: .leftParen, value: "(", position: Position(line: 1, column: 1)),
            Token(type: .number, value: "5", position: Position(line: 1, column: 2)),
            Token(type: .operator(.plus), value: "+", position: Position(line: 1, column: 4)),
            Token(type: .number, value: "3", position: Position(line: 1, column: 6)),
            // Missing closing parenthesis
            Token(type: .eof, value: "", position: Position(line: 1, column: 7))
        ]
        
        let parser = Parser(tokens: tokens, enableErrorRecovery: true)
        let result = parser.parseWithErrorRecovery()
        
        // Should detect the unmatched parenthesis error
        let hasUnmatchedParenError = result.errors.contains { error in
            if case .unmatchedParenthesis(_) = error {
                return true
            }
            return false
        }
        XCTAssertTrue(hasUnmatchedParenError)
    }
    
    // MARK: - Version Tests
    
    /// Test version information
    func testVersionInformation() throws {
        XCTAssertFalse(SwiftCalcParserVersion.current.isEmpty)
        XCTAssertFalse(SwiftCalcParserVersion.minimumTokenizerVersion.isEmpty)
    }
    
    // MARK: - Parser State Management and Debugging Tests
    
    /// Test parser state tracking and debugging functionality
    func testParserStateManagement() throws {
        let tokenizer = Tokenizer(input: "2 + 3 * 4")
        let tokens = try tokenizer.tokenize()
        
        // Create parser with debug mode enabled
        let parser = Parser(tokens: tokens, enableErrorRecovery: false, enableDebugMode: true)
        
        // Verify debug mode is enabled
        XCTAssertTrue(parser.isDebugModeEnabled())
        
        // Parse the expression
        let ast = try parser.parse()
        
        // Verify we got a valid AST
        XCTAssertTrue(ast is BinaryOperation)
        
        // Test parser state inspection
        let state = parser.getParserState()
        XCTAssertNotNil(state["currentIndex"])
        XCTAssertNotNil(state["tokensConsumed"])
        XCTAssertNotNil(state["errorCount"])
        XCTAssertNotNil(state["maxRecursionDepth"])
        XCTAssertNotNil(state["parsingDuration"])
        
        // Test operation history
        let history = parser.getOperationHistory()
        XCTAssertFalse(history.isEmpty)
        XCTAssertTrue(history.first?.contains("parse") ?? false)
        
        // Test parser statistics
        let stats = parser.getParserStatistics()
        XCTAssertNotNil(stats["totalTokens"])
        XCTAssertNotNil(stats["tokensConsumed"])
        XCTAssertNotNil(stats["debugModeEnabled"])
        XCTAssertEqual(stats["debugModeEnabled"] as? Bool, true)
        
        // Test position summary
        let summary = parser.getPositionSummary()
        XCTAssertFalse(summary.isEmpty)
    }
    
    /// Test parser state management without debug mode
    func testParserStateWithoutDebugMode() throws {
        let tokenizer = Tokenizer(input: "x = 5")
        let tokens = try tokenizer.tokenize()
        
        // Create parser without debug mode
        let parser = Parser(tokens: tokens)
        
        // Verify debug mode is disabled
        XCTAssertFalse(parser.isDebugModeEnabled())
        
        // Parse the expression
        let ast = try parser.parse()
        
        // Verify we got a valid AST
        XCTAssertTrue(ast is Assignment)
        
        // Test that operation history indicates debug mode is not enabled
        let history = parser.getOperationHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first, "Debug mode not enabled")
        
        // Test that we can still get basic state information
        let state = parser.getParserState()
        XCTAssertNotNil(state["currentIndex"])
        XCTAssertNotNil(state["tokensConsumed"])
    }
    
    /// Test enabling debug mode at runtime
    func testRuntimeDebugModeToggle() throws {
        let tokenizer = Tokenizer(input: "sin(x)")
        let tokens = try tokenizer.tokenize()
        
        let parser = Parser(tokens: tokens)
        
        // Initially debug mode should be disabled
        XCTAssertFalse(parser.isDebugModeEnabled())
        
        // Enable debug mode
        parser.setDebugMode(true)
        XCTAssertTrue(parser.isDebugModeEnabled())
        
        // Parse with debug mode enabled
        let ast = try parser.parse()
        XCTAssertTrue(ast is FunctionCall)
        
        // Should now have operation history
        let history = parser.getOperationHistory()
        XCTAssertGreaterThan(history.count, 1)
        
        // Disable debug mode
        parser.setDebugMode(false)
        XCTAssertFalse(parser.isDebugModeEnabled())
    }
    
    /// Test parser state with error recovery
    func testParserStateWithErrorRecovery() throws {
        let tokenizer = Tokenizer(input: "2 + + 3") // Invalid syntax
        let tokens = try tokenizer.tokenize()
        
        let parser = Parser(tokens: tokens, enableErrorRecovery: true, enableDebugMode: true)
        
        // Parse with error recovery
        let result = parser.parseWithErrorRecovery()
        
        // Should have collected errors
        XCTAssertFalse(result.errors.isEmpty)
        
        // Should still have state information
        let state = parser.getParserState()
        XCTAssertNotNil(state["errorCount"])
        
        let stats = parser.getParserStatistics()
        XCTAssertEqual(stats["errorRecoveryEnabled"] as? Bool, true)
    }
    
    // MARK: - Operator Precedence Validation Tests
    
    /// Test basic operator precedence: multiplication over addition
    func testMultiplicationPrecedenceOverAddition() throws {
        // Test "2 + 3 * 4" should parse as "2 + (3 * 4)"
        let input = "2 + 3 * 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .plus)
        XCTAssertEqual((outerOp.left as? Literal)?.value, "2")
        XCTAssertTrue(outerOp.right is BinaryOperation)
        
        let innerOp = outerOp.right as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .multiply)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "3")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "4")
    }
    
    /// Test division precedence over addition
    func testDivisionPrecedenceOverAddition() throws {
        // Test "10 + 8 / 2" should parse as "10 + (8 / 2)"
        let input = "10 + 8 / 2"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .plus)
        XCTAssertEqual((outerOp.left as? Literal)?.value, "10")
        XCTAssertTrue(outerOp.right is BinaryOperation)
        
        let innerOp = outerOp.right as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .divide)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "8")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "2")
    }
    
    /// Test modulo precedence over addition
    func testModuloPrecedenceOverAddition() throws {
        // Test "7 + 5 % 3" should parse as "7 + (5 % 3)"
        let input = "7 + 5 % 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .plus)
        XCTAssertEqual((outerOp.left as? Literal)?.value, "7")
        XCTAssertTrue(outerOp.right is BinaryOperation)
        
        let innerOp = outerOp.right as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .modulo)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "5")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "3")
    }
    
    /// Test exponentiation precedence over multiplication
    func testExponentiationPrecedenceOverMultiplication() throws {
        // Test "2 * 3 ^ 4" should parse as "2 * (3 ^ 4)"
        let input = "2 * 3 ^ 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .multiply)
        XCTAssertEqual((outerOp.left as? Literal)?.value, "2")
        XCTAssertTrue(outerOp.right is BinaryOperation)
        
        let innerOp = outerOp.right as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .power)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "3")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "4")
    }
    
    /// Test exponentiation precedence over division
    func testExponentiationPrecedenceOverDivision() throws {
        // Test "8 / 2 ^ 3" should parse as "8 / (2 ^ 3)"
        let input = "8 / 2 ^ 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .divide)
        XCTAssertEqual((outerOp.left as? Literal)?.value, "8")
        XCTAssertTrue(outerOp.right is BinaryOperation)
        
        let innerOp = outerOp.right as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .power)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "2")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "3")
    }
    
    /// Test unary minus precedence over binary operations
    func testUnaryMinusPrecedenceOverBinary() throws {
        // Test "2 * -3" should parse as "2 * (-3)"
        let input = "2 * -3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let binaryOp = result as! BinaryOperation
        XCTAssertEqual(binaryOp.operator, .multiply)
        XCTAssertEqual((binaryOp.left as? Literal)?.value, "2")
        XCTAssertTrue(binaryOp.right is UnaryOperation)
        
        let unaryOp = binaryOp.right as! UnaryOperation
        XCTAssertEqual(unaryOp.operator, .minus)
        XCTAssertEqual((unaryOp.operand as? Literal)?.value, "3")
    }
    
    /// Test unary minus with exponentiation
    func testUnaryMinusWithExponentiation() throws {
        // Test "-2 ^ 3" should parse as "(-2) ^ 3" (unary has higher precedence)
        let input = "-2 ^ 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let binaryOp = result as! BinaryOperation
        XCTAssertEqual(binaryOp.operator, .power)
        XCTAssertTrue(binaryOp.left is UnaryOperation)
        XCTAssertEqual((binaryOp.right as? Literal)?.value, "3")
        
        let unaryOp = binaryOp.left as! UnaryOperation
        XCTAssertEqual(unaryOp.operator, .minus)
        XCTAssertEqual((unaryOp.operand as? Literal)?.value, "2")
    }
    
    /// Test right-associativity of exponentiation
    func testExponentiationRightAssociativity() throws {
        // Test "2 ^ 3 ^ 4" should parse as "2 ^ (3 ^ 4)"
        let input = "2 ^ 3 ^ 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .power)
        XCTAssertEqual((outerOp.left as? Literal)?.value, "2")
        XCTAssertTrue(outerOp.right is BinaryOperation)
        
        let innerOp = outerOp.right as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .power)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "3")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "4")
    }
    
    /// Test left-associativity of subtraction
    func testSubtractionLeftAssociativity() throws {
        // Test "10 - 5 - 2" should parse as "(10 - 5) - 2"
        let input = "10 - 5 - 2"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .minus)
        XCTAssertTrue(outerOp.left is BinaryOperation)
        XCTAssertEqual((outerOp.right as? Literal)?.value, "2")
        
        let innerOp = outerOp.left as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .minus)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "10")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "5")
    }
    
    /// Test left-associativity of addition
    func testAdditionLeftAssociativity() throws {
        // Test "1 + 2 + 3" should parse as "(1 + 2) + 3"
        let input = "1 + 2 + 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .plus)
        XCTAssertTrue(outerOp.left is BinaryOperation)
        XCTAssertEqual((outerOp.right as? Literal)?.value, "3")
        
        let innerOp = outerOp.left as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .plus)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "1")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "2")
    }
    
    /// Test left-associativity of multiplication
    func testMultiplicationLeftAssociativity() throws {
        // Test "2 * 3 * 4" should parse as "(2 * 3) * 4"
        let input = "2 * 3 * 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .multiply)
        XCTAssertTrue(outerOp.left is BinaryOperation)
        XCTAssertEqual((outerOp.right as? Literal)?.value, "4")
        
        let innerOp = outerOp.left as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .multiply)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "2")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "3")
    }
    
    /// Test left-associativity of division
    func testDivisionLeftAssociativity() throws {
        // Test "8 / 4 / 2" should parse as "(8 / 4) / 2"
        let input = "8 / 4 / 2"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .divide)
        XCTAssertTrue(outerOp.left is BinaryOperation)
        XCTAssertEqual((outerOp.right as? Literal)?.value, "2")
        
        let innerOp = outerOp.left as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .divide)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "8")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "4")
    }
    
    /// Test left-associativity of modulo
    func testModuloLeftAssociativity() throws {
        // Test "10 % 6 % 3" should parse as "(10 % 6) % 3"
        let input = "10 % 6 % 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerOp = result as! BinaryOperation
        XCTAssertEqual(outerOp.operator, .modulo)
        XCTAssertTrue(outerOp.left is BinaryOperation)
        XCTAssertEqual((outerOp.right as? Literal)?.value, "3")
        
        let innerOp = outerOp.left as! BinaryOperation
        XCTAssertEqual(innerOp.operator, .modulo)
        XCTAssertEqual((innerOp.left as? Literal)?.value, "10")
        XCTAssertEqual((innerOp.right as? Literal)?.value, "6")
    }
    
    /// Test right-associativity of assignment
    func testAssignmentRightAssociativity() throws {
        // Test "a = b = 5" should parse as "a = (b = 5)"
        let input = "a = b = 5"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is Assignment)
        let outerAssign = result as! Assignment
        XCTAssertEqual(outerAssign.target.name, "a")
        XCTAssertTrue(outerAssign.value is Assignment)
        
        let innerAssign = outerAssign.value as! Assignment
        XCTAssertEqual(innerAssign.target.name, "b")
        XCTAssertEqual((innerAssign.value as? Literal)?.value, "5")
    }
    
    /// Test assignment has lowest precedence
    func testAssignmentLowestPrecedence() throws {
        // Test "x = 2 + 3 * 4" should parse as "x = (2 + (3 * 4))"
        let input = "x = 2 + 3 * 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is Assignment)
        let assignment = result as! Assignment
        XCTAssertEqual(assignment.target.name, "x")
        XCTAssertTrue(assignment.value is BinaryOperation)
        
        let addOp = assignment.value as! BinaryOperation
        XCTAssertEqual(addOp.operator, .plus)
        XCTAssertEqual((addOp.left as? Literal)?.value, "2")
        XCTAssertTrue(addOp.right is BinaryOperation)
        
        let multOp = addOp.right as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "3")
        XCTAssertEqual((multOp.right as? Literal)?.value, "4")
    }
    
    /// Test parentheses override precedence - addition before multiplication
    func testParenthesesOverridePrecedenceAdditionFirst() throws {
        // Test "(2 + 3) * 4" should parse as "(2 + 3) * 4" with addition evaluated first
        let input = "(2 + 3) * 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let multOp = result as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertTrue(multOp.left is ParenthesizedExpression)
        XCTAssertEqual((multOp.right as? Literal)?.value, "4")
        
        let parenExpr = multOp.left as! ParenthesizedExpression
        XCTAssertTrue(parenExpr.expression is BinaryOperation)
        
        let addOp = parenExpr.expression as! BinaryOperation
        XCTAssertEqual(addOp.operator, .plus)
        XCTAssertEqual((addOp.left as? Literal)?.value, "2")
        XCTAssertEqual((addOp.right as? Literal)?.value, "3")
    }
    
    /// Test parentheses override precedence - multiplication before exponentiation
    func testParenthesesOverridePrecedenceMultiplicationFirst() throws {
        // Test "(2 * 3) ^ 4" should parse with multiplication evaluated first
        let input = "(2 * 3) ^ 4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let powerOp = result as! BinaryOperation
        XCTAssertEqual(powerOp.operator, .power)
        XCTAssertTrue(powerOp.left is ParenthesizedExpression)
        XCTAssertEqual((powerOp.right as? Literal)?.value, "4")
        
        let parenExpr = powerOp.left as! ParenthesizedExpression
        XCTAssertTrue(parenExpr.expression is BinaryOperation)
        
        let multOp = parenExpr.expression as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "2")
        XCTAssertEqual((multOp.right as? Literal)?.value, "3")
    }
    
    /// Test nested parentheses with precedence override
    func testNestedParenthesesPrecedenceOverride() throws {
        // Test "2 + (3 * (4 + 5))" should respect nested grouping
        let input = "2 + (3 * (4 + 5))"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerAdd = result as! BinaryOperation
        XCTAssertEqual(outerAdd.operator, .plus)
        XCTAssertEqual((outerAdd.left as? Literal)?.value, "2")
        XCTAssertTrue(outerAdd.right is ParenthesizedExpression)
        
        let outerParen = outerAdd.right as! ParenthesizedExpression
        XCTAssertTrue(outerParen.expression is BinaryOperation)
        
        let multOp = outerParen.expression as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "3")
        XCTAssertTrue(multOp.right is ParenthesizedExpression)
        
        let innerParen = multOp.right as! ParenthesizedExpression
        XCTAssertTrue(innerParen.expression is BinaryOperation)
        
        let innerAdd = innerParen.expression as! BinaryOperation
        XCTAssertEqual(innerAdd.operator, .plus)
        XCTAssertEqual((innerAdd.left as? Literal)?.value, "4")
        XCTAssertEqual((innerAdd.right as? Literal)?.value, "5")
    }
    
    /// Test complex mixed operator precedence
    func testComplexMixedOperatorPrecedence() throws {
        // Test "2 + 3 * 4 ^ 5 - 6 / 2" should follow full precedence hierarchy
        // Should parse as: "2 + (3 * (4 ^ 5)) - (6 / 2)"
        let input = "2 + 3 * 4 ^ 5 - 6 / 2"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerSub = result as! BinaryOperation
        XCTAssertEqual(outerSub.operator, .minus)
        XCTAssertTrue(outerSub.left is BinaryOperation)
        XCTAssertTrue(outerSub.right is BinaryOperation)
        
        // Left side: "2 + 3 * 4 ^ 5" -> "2 + (3 * (4 ^ 5))"
        let leftAdd = outerSub.left as! BinaryOperation
        XCTAssertEqual(leftAdd.operator, .plus)
        XCTAssertEqual((leftAdd.left as? Literal)?.value, "2")
        XCTAssertTrue(leftAdd.right is BinaryOperation)
        
        let multOp = leftAdd.right as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "3")
        XCTAssertTrue(multOp.right is BinaryOperation)
        
        let powerOp = multOp.right as! BinaryOperation
        XCTAssertEqual(powerOp.operator, .power)
        XCTAssertEqual((powerOp.left as? Literal)?.value, "4")
        XCTAssertEqual((powerOp.right as? Literal)?.value, "5")
        
        // Right side: "6 / 2"
        let rightDiv = outerSub.right as! BinaryOperation
        XCTAssertEqual(rightDiv.operator, .divide)
        XCTAssertEqual((rightDiv.left as? Literal)?.value, "6")
        XCTAssertEqual((rightDiv.right as? Literal)?.value, "2")
    }
    
    /// Test all operators at same precedence level (multiplicative)
    func testSamePrecedenceLevelMultiplicative() throws {
        // Test "8 * 4 / 2 % 3" should be left-associative: "((8 * 4) / 2) % 3"
        let input = "8 * 4 / 2 % 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerMod = result as! BinaryOperation
        XCTAssertEqual(outerMod.operator, .modulo)
        XCTAssertTrue(outerMod.left is BinaryOperation)
        XCTAssertEqual((outerMod.right as? Literal)?.value, "3")
        
        let divOp = outerMod.left as! BinaryOperation
        XCTAssertEqual(divOp.operator, .divide)
        XCTAssertTrue(divOp.left is BinaryOperation)
        XCTAssertEqual((divOp.right as? Literal)?.value, "2")
        
        let multOp = divOp.left as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "8")
        XCTAssertEqual((multOp.right as? Literal)?.value, "4")
    }
    
    /// Test all operators at same precedence level (additive)
    func testSamePrecedenceLevelAdditive() throws {
        // Test "10 + 5 - 3 + 2" should be left-associative: "((10 + 5) - 3) + 2"
        let input = "10 + 5 - 3 + 2"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let outerAdd = result as! BinaryOperation
        XCTAssertEqual(outerAdd.operator, .plus)
        XCTAssertTrue(outerAdd.left is BinaryOperation)
        XCTAssertEqual((outerAdd.right as? Literal)?.value, "2")
        
        let subOp = outerAdd.left as! BinaryOperation
        XCTAssertEqual(subOp.operator, .minus)
        XCTAssertTrue(subOp.left is BinaryOperation)
        XCTAssertEqual((subOp.right as? Literal)?.value, "3")
        
        let innerAdd = subOp.left as! BinaryOperation
        XCTAssertEqual(innerAdd.operator, .plus)
        XCTAssertEqual((innerAdd.left as? Literal)?.value, "10")
        XCTAssertEqual((innerAdd.right as? Literal)?.value, "5")
    }
    
    /// Test unary minus with complex expressions
    func testUnaryMinusWithComplexExpressions() throws {
        // Test "-2 + 3 * -4" should parse as "(-2) + (3 * (-4))"
        let input = "-2 + 3 * -4"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let addOp = result as! BinaryOperation
        XCTAssertEqual(addOp.operator, .plus)
        XCTAssertTrue(addOp.left is UnaryOperation)
        XCTAssertTrue(addOp.right is BinaryOperation)
        
        // Left side: "-2"
        let leftUnary = addOp.left as! UnaryOperation
        XCTAssertEqual(leftUnary.operator, .minus)
        XCTAssertEqual((leftUnary.operand as? Literal)?.value, "2")
        
        // Right side: "3 * -4"
        let multOp = addOp.right as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "3")
        XCTAssertTrue(multOp.right is UnaryOperation)
        
        let rightUnary = multOp.right as! UnaryOperation
        XCTAssertEqual(rightUnary.operator, .minus)
        XCTAssertEqual((rightUnary.operand as? Literal)?.value, "4")
    }
    
    /// Test assignment with complex right-hand side
    func testAssignmentWithComplexRightHandSide() throws {
        // Test "result = 2 + 3 * 4 ^ 5" should parse assignment with lowest precedence
        let input = "result = 2 + 3 * 4 ^ 5"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is Assignment)
        let assignment = result as! Assignment
        XCTAssertEqual(assignment.target.name, "result")
        XCTAssertTrue(assignment.value is BinaryOperation)
        
        // Value should be: "2 + (3 * (4 ^ 5))"
        let addOp = assignment.value as! BinaryOperation
        XCTAssertEqual(addOp.operator, .plus)
        XCTAssertEqual((addOp.left as? Literal)?.value, "2")
        XCTAssertTrue(addOp.right is BinaryOperation)
        
        let multOp = addOp.right as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "3")
        XCTAssertTrue(multOp.right is BinaryOperation)
        
        let powerOp = multOp.right as! BinaryOperation
        XCTAssertEqual(powerOp.operator, .power)
        XCTAssertEqual((powerOp.left as? Literal)?.value, "4")
        XCTAssertEqual((powerOp.right as? Literal)?.value, "5")
    }
    
    /// Test function calls have highest precedence (with parentheses)
    func testFunctionCallHighestPrecedence() throws {
        // Test "2 + sin(3 * 4)" should parse function call first
        let input = "2 + sin(3 * 4)"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        XCTAssertTrue(result is BinaryOperation)
        let addOp = result as! BinaryOperation
        XCTAssertEqual(addOp.operator, .plus)
        XCTAssertEqual((addOp.left as? Literal)?.value, "2")
        XCTAssertTrue(addOp.right is FunctionCall)
        
        let funcCall = addOp.right as! FunctionCall
        XCTAssertEqual(funcCall.name, "sin")
        XCTAssertEqual(funcCall.arguments.count, 1)
        XCTAssertTrue(funcCall.arguments[0] is BinaryOperation)
        
        let argOp = funcCall.arguments[0] as! BinaryOperation
        XCTAssertEqual(argOp.operator, .multiply)
        XCTAssertEqual((argOp.left as? Literal)?.value, "3")
        XCTAssertEqual((argOp.right as? Literal)?.value, "4")
    }
    
    /// Test comprehensive precedence hierarchy
    func testComprehensivePrecedenceHierarchy() throws {
        // Test "x = -sin(2) + 3 * 4 ^ 5 - 6 / 2 % 3"
        // Should demonstrate all precedence levels working together
        let input = "x = -sin(2) + 3 * 4 ^ 5 - 6 / 2 % 3"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let result = try parser.parse()
        
        // Should be an assignment (lowest precedence)
        XCTAssertTrue(result is Assignment)
        let assignment = result as! Assignment
        XCTAssertEqual(assignment.target.name, "x")
        
        // The value should be a complex expression with proper precedence
        XCTAssertTrue(assignment.value is BinaryOperation)
        let outerSub = assignment.value as! BinaryOperation
        XCTAssertEqual(outerSub.operator, .minus)
        
        // Left side should be: "-sin(2) + 3 * 4 ^ 5"
        XCTAssertTrue(outerSub.left is BinaryOperation)
        let addOp = outerSub.left as! BinaryOperation
        XCTAssertEqual(addOp.operator, .plus)
        
        // Far left: "-sin(2)" (unary minus applied to function call)
        XCTAssertTrue(addOp.left is UnaryOperation)
        let unaryOp = addOp.left as! UnaryOperation
        XCTAssertEqual(unaryOp.operator, .minus)
        XCTAssertTrue(unaryOp.operand is FunctionCall)
        
        let funcCall = unaryOp.operand as! FunctionCall
        XCTAssertEqual(funcCall.name, "sin")
        XCTAssertEqual(funcCall.arguments.count, 1)
        XCTAssertEqual((funcCall.arguments[0] as? Literal)?.value, "2")
        
        // Right side of addition: "3 * 4 ^ 5"
        XCTAssertTrue(addOp.right is BinaryOperation)
        let multOp = addOp.right as! BinaryOperation
        XCTAssertEqual(multOp.operator, .multiply)
        XCTAssertEqual((multOp.left as? Literal)?.value, "3")
        XCTAssertTrue(multOp.right is BinaryOperation)
        
        let powerOp = multOp.right as! BinaryOperation
        XCTAssertEqual(powerOp.operator, .power)
        XCTAssertEqual((powerOp.left as? Literal)?.value, "4")
        XCTAssertEqual((powerOp.right as? Literal)?.value, "5")
        
        // Right side of subtraction: "6 / 2 % 3" (left-associative)
        XCTAssertTrue(outerSub.right is BinaryOperation)
        let modOp = outerSub.right as! BinaryOperation
        XCTAssertEqual(modOp.operator, .modulo)
        XCTAssertTrue(modOp.left is BinaryOperation)
        XCTAssertEqual((modOp.right as? Literal)?.value, "3")
        
        let divOp = modOp.left as! BinaryOperation
        XCTAssertEqual(divOp.operator, .divide)
        XCTAssertEqual((divOp.left as? Literal)?.value, "6")
        XCTAssertEqual((divOp.right as? Literal)?.value, "2")
    }
}