import Testing
@testable import SwiftCalcTokenizer

@Test func testPositionCreation() {
    let position = Position(line: 1, column: 5)
    #expect(position.line == 1)
    #expect(position.column == 5)
    #expect(position.description == "1:5")
}

@Test func testTokenCreation() {
    let position = Position(line: 1, column: 1)
    let token = Token(type: .number, value: "42", position: position)
    
    #expect(token.type == .number)
    #expect(token.value == "42")
    #expect(token.position == position)
}

@Test func testOperatorTypeDescription() {
    #expect(OperatorType.plus.description == "+")
    #expect(OperatorType.minus.description == "-")
    #expect(OperatorType.multiply.description == "*")
    #expect(OperatorType.divide.description == "/")
    #expect(OperatorType.modulo.description == "%")
    #expect(OperatorType.power.description == "^")
}

@Test func testTokenTypeDescription() {
    #expect(TokenType.number.description == "NUMBER")
    #expect(TokenType.identifier.description == "IDENTIFIER")
    #expect(TokenType.operator(.plus).description == "OPERATOR(+)")
    #expect(TokenType.leftParen.description == "LPAREN")
    #expect(TokenType.rightParen.description == "RPAREN")
    #expect(TokenType.assign.description == "ASSIGN")
    #expect(TokenType.eof.description == "EOF")
    #expect(TokenType.error.description == "ERROR")
}

@Test func testTokenizerErrorDescription() {
    let position = Position(line: 1, column: 5)
    
    let invalidCharError = TokenizerError.invalidCharacter("@", position)
    #expect(invalidCharError.description == "Invalid character '@' at 1:5")
    
    let malformedNumberError = TokenizerError.malformedNumber("3.14.15", position)
    #expect(malformedNumberError.description == "Malformed number '3.14.15' at 1:5")
    
    let unexpectedEndError = TokenizerError.unexpectedEndOfInput(position)
    #expect(unexpectedEndError.description == "Unexpected end of input at 1:5")
}

// MARK: - Number Tokenization Tests

@Test func testIntegerParsing() throws {
    // Test single digit
    var tokenizer = Tokenizer(input: "0")
    var token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "0")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test multi-digit positive number
    tokenizer = Tokenizer(input: "123")
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "123")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test large number
    tokenizer = Tokenizer(input: "999999")
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "999999")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testDecimalParsing() throws {
    // Test simple decimal
    var tokenizer = Tokenizer(input: "3.14")
    var token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "3.14")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test decimal starting with zero
    tokenizer = Tokenizer(input: "0.5")
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "0.5")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test decimal ending with zero
    tokenizer = Tokenizer(input: "123.0")
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "123.0")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test multiple decimal places
    tokenizer = Tokenizer(input: "3.14159")
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "3.14159")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testNumberWithTrailingDot() throws {
    // Test number followed by dot without digits (should not consume the dot)
    let tokenizer = Tokenizer(input: "3.")
    let token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "3")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testMalformedNumberErrorCases() throws {
    // Test multiple decimal points
    var tokenizer = Tokenizer(input: "3.14.15")
    var token = try tokenizer.nextToken()
    #expect(token.type == .error)
    #expect(token.value == "3.14.15")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test multiple decimal points with more digits
    tokenizer = Tokenizer(input: "1.2.3.4")
    token = try tokenizer.nextToken()
    #expect(token.type == .error)
    #expect(token.value == "1.2.3.4")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testNumbersWithWhitespace() throws {
    // Test number with leading whitespace
    var tokenizer = Tokenizer(input: "   42")
    var token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "42")
    #expect(token.position == Position(line: 1, column: 4))
    
    // Test number with trailing whitespace
    tokenizer = Tokenizer(input: "3.14   ")
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "3.14")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Next token should be EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testMultipleNumbers() throws {
    let tokenizer = Tokenizer(input: "123 45.67 0")
    
    // First number
    var token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "123")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Second number
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "45.67")
    #expect(token.position == Position(line: 1, column: 5))
    
    // Third number
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "0")
    #expect(token.position == Position(line: 1, column: 11))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testNumbersAcrossLines() throws {
    let tokenizer = Tokenizer(input: "123\n45.67")
    
    // First number
    var token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "123")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Second number on new line
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "45.67")
    #expect(token.position == Position(line: 2, column: 1))
}

// MARK: - Operator and Delimiter Tokenization Tests

@Test func testMathematicalOperators() throws {
    // Test plus operator
    var tokenizer = Tokenizer(input: "+")
    var token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test minus operator
    tokenizer = Tokenizer(input: "-")
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.minus))
    #expect(token.value == "-")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test multiply operator
    tokenizer = Tokenizer(input: "*")
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.multiply))
    #expect(token.value == "*")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test divide operator
    tokenizer = Tokenizer(input: "/")
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.divide))
    #expect(token.value == "/")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test modulo operator
    tokenizer = Tokenizer(input: "%")
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.modulo))
    #expect(token.value == "%")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test power operator
    tokenizer = Tokenizer(input: "^")
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.power))
    #expect(token.value == "^")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testParentheses() throws {
    // Test left parenthesis
    var tokenizer = Tokenizer(input: "(")
    var token = try tokenizer.nextToken()
    #expect(token.type == .leftParen)
    #expect(token.value == "(")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test right parenthesis
    tokenizer = Tokenizer(input: ")")
    token = try tokenizer.nextToken()
    #expect(token.type == .rightParen)
    #expect(token.value == ")")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test both parentheses together
    tokenizer = Tokenizer(input: "()")
    token = try tokenizer.nextToken()
    #expect(token.type == .leftParen)
    #expect(token.value == "(")
    #expect(token.position == Position(line: 1, column: 1))
    
    token = try tokenizer.nextToken()
    #expect(token.type == .rightParen)
    #expect(token.value == ")")
    #expect(token.position == Position(line: 1, column: 2))
}

@Test func testAssignmentOperator() throws {
    // Test assignment operator
    let tokenizer = Tokenizer(input: "=")
    let token = try tokenizer.nextToken()
    #expect(token.type == .assign)
    #expect(token.value == "=")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testOperatorsWithWhitespace() throws {
    // Test operators with leading whitespace
    var tokenizer = Tokenizer(input: "   +")
    var token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 4))
    
    // Test operators with trailing whitespace
    tokenizer = Tokenizer(input: "*   ")
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.multiply))
    #expect(token.value == "*")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Next token should be EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testMultipleOperators() throws {
    let tokenizer = Tokenizer(input: "+ - * / % ^")
    
    // Plus
    var token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Minus
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.minus))
    #expect(token.value == "-")
    #expect(token.position == Position(line: 1, column: 3))
    
    // Multiply
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.multiply))
    #expect(token.value == "*")
    #expect(token.position == Position(line: 1, column: 5))
    
    // Divide
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.divide))
    #expect(token.value == "/")
    #expect(token.position == Position(line: 1, column: 7))
    
    // Modulo
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.modulo))
    #expect(token.value == "%")
    #expect(token.position == Position(line: 1, column: 9))
    
    // Power
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.power))
    #expect(token.value == "^")
    #expect(token.position == Position(line: 1, column: 11))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testOperatorsAndParenthesesMixed() throws {
    let tokenizer = Tokenizer(input: "(+)")
    
    // Left paren
    var token = try tokenizer.nextToken()
    #expect(token.type == .leftParen)
    #expect(token.value == "(")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Plus operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 2))
    
    // Right paren
    token = try tokenizer.nextToken()
    #expect(token.type == .rightParen)
    #expect(token.value == ")")
    #expect(token.position == Position(line: 1, column: 3))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testAssignmentWithOperators() throws {
    let tokenizer = Tokenizer(input: "= + - =")
    
    // Assignment
    var token = try tokenizer.nextToken()
    #expect(token.type == .assign)
    #expect(token.value == "=")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Plus
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 3))
    
    // Minus
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.minus))
    #expect(token.value == "-")
    #expect(token.position == Position(line: 1, column: 5))
    
    // Assignment again
    token = try tokenizer.nextToken()
    #expect(token.type == .assign)
    #expect(token.value == "=")
    #expect(token.position == Position(line: 1, column: 7))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testOperatorsAcrossLines() throws {
    let tokenizer = Tokenizer(input: "+\n-\n*")
    
    // Plus on line 1
    var token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Minus on line 2
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.minus))
    #expect(token.value == "-")
    #expect(token.position == Position(line: 2, column: 1))
    
    // Multiply on line 3
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.multiply))
    #expect(token.value == "*")
    #expect(token.position == Position(line: 3, column: 1))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testComplexExpression() throws {
    let tokenizer = Tokenizer(input: "3 + 4 * (2 - 1)")
    
    // Number 3
    var token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "3")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Plus operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 3))
    
    // Number 4
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "4")
    #expect(token.position == Position(line: 1, column: 5))
    
    // Multiply operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.multiply))
    #expect(token.value == "*")
    #expect(token.position == Position(line: 1, column: 7))
    
    // Left paren
    token = try tokenizer.nextToken()
    #expect(token.type == .leftParen)
    #expect(token.value == "(")
    #expect(token.position == Position(line: 1, column: 9))
    
    // Number 2
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "2")
    #expect(token.position == Position(line: 1, column: 10))
    
    // Minus operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.minus))
    #expect(token.value == "-")
    #expect(token.position == Position(line: 1, column: 12))
    
    // Number 1
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "1")
    #expect(token.position == Position(line: 1, column: 14))
    
    // Right paren
    token = try tokenizer.nextToken()
    #expect(token.type == .rightParen)
    #expect(token.value == ")")
    #expect(token.position == Position(line: 1, column: 15))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testAssignmentExpression() throws {
    let tokenizer = Tokenizer(input: "x = 5 + 3")
    
    // Identifier 'x'
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "x")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Assignment operator
    token = try tokenizer.nextToken()
    #expect(token.type == .assign)
    #expect(token.value == "=")
    #expect(token.position == Position(line: 1, column: 3))
    
    // Number 5
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "5")
    #expect(token.position == Position(line: 1, column: 5))
    
    // Plus operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 7))
    
    // Number 3
    token = try tokenizer.nextToken()
    #expect(token.type == .number)
    #expect(token.value == "3")
    #expect(token.position == Position(line: 1, column: 9))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

// MARK: - Identifier Tokenization Tests

@Test func testBasicIdentifiers() throws {
    // Test single letter identifier
    var tokenizer = Tokenizer(input: "x")
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "x")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test multi-letter identifier
    tokenizer = Tokenizer(input: "variable")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "variable")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier starting with uppercase
    tokenizer = Tokenizer(input: "Variable")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "Variable")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier with mixed case
    tokenizer = Tokenizer(input: "myVariable")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "myVariable")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testIdentifiersWithUnderscore() throws {
    // Test identifier starting with underscore
    var tokenizer = Tokenizer(input: "_variable")
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "_variable")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier with underscore in middle
    tokenizer = Tokenizer(input: "my_variable")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "my_variable")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier ending with underscore
    tokenizer = Tokenizer(input: "variable_")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "variable_")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier with multiple underscores
    tokenizer = Tokenizer(input: "__private__")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "__private__")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test single underscore
    tokenizer = Tokenizer(input: "_")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "_")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testIdentifiersWithNumbers() throws {
    // Test identifier with number at end
    var tokenizer = Tokenizer(input: "var1")
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var1")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier with number in middle
    tokenizer = Tokenizer(input: "var2name")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var2name")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier with multiple numbers
    tokenizer = Tokenizer(input: "var123test456")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var123test456")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier with underscore and numbers
    tokenizer = Tokenizer(input: "my_var_123")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "my_var_123")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testIdentifierEdgeCases() throws {
    // Test very long identifier
    var tokenizer = Tokenizer(input: "thisIsAVeryLongIdentifierNameThatShouldStillWork")
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "thisIsAVeryLongIdentifierNameThatShouldStillWork")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Test identifier followed by operator (no space)
    tokenizer = Tokenizer(input: "x+")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "x")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Next token should be plus operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 2))
    
    // Test identifier followed by number (no space)
    tokenizer = Tokenizer(input: "var123")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var123")
    #expect(token.position == Position(line: 1, column: 1))
}

@Test func testIdentifiersWithWhitespace() throws {
    // Test identifier with leading whitespace
    var tokenizer = Tokenizer(input: "   variable")
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "variable")
    #expect(token.position == Position(line: 1, column: 4))
    
    // Test identifier with trailing whitespace
    tokenizer = Tokenizer(input: "variable   ")
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "variable")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Next token should be EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testMultipleIdentifiers() throws {
    let tokenizer = Tokenizer(input: "var1 var2 _private myFunc")
    
    // First identifier
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var1")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Second identifier
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var2")
    #expect(token.position == Position(line: 1, column: 6))
    
    // Third identifier
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "_private")
    #expect(token.position == Position(line: 1, column: 11))
    
    // Fourth identifier
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "myFunc")
    #expect(token.position == Position(line: 1, column: 20))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testIdentifiersAcrossLines() throws {
    let tokenizer = Tokenizer(input: "var1\nvar2\n_test")
    
    // First identifier on line 1
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var1")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Second identifier on line 2
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "var2")
    #expect(token.position == Position(line: 2, column: 1))
    
    // Third identifier on line 3
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "_test")
    #expect(token.position == Position(line: 3, column: 1))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testFunctionCallSyntax() throws {
    let tokenizer = Tokenizer(input: "sin(x)")
    
    // Function name identifier
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "sin")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Left parenthesis
    token = try tokenizer.nextToken()
    #expect(token.type == .leftParen)
    #expect(token.value == "(")
    #expect(token.position == Position(line: 1, column: 4))
    
    // Parameter identifier
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "x")
    #expect(token.position == Position(line: 1, column: 5))
    
    // Right parenthesis
    token = try tokenizer.nextToken()
    #expect(token.type == .rightParen)
    #expect(token.value == ")")
    #expect(token.position == Position(line: 1, column: 6))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

@Test func testComplexExpressionWithIdentifiers() throws {
    let tokenizer = Tokenizer(input: "result = x + y * sin(angle)")
    
    // Identifier 'result'
    var token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "result")
    #expect(token.position == Position(line: 1, column: 1))
    
    // Assignment operator
    token = try tokenizer.nextToken()
    #expect(token.type == .assign)
    #expect(token.value == "=")
    #expect(token.position == Position(line: 1, column: 8))
    
    // Identifier 'x'
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "x")
    #expect(token.position == Position(line: 1, column: 10))
    
    // Plus operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.plus))
    #expect(token.value == "+")
    #expect(token.position == Position(line: 1, column: 12))
    
    // Identifier 'y'
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "y")
    #expect(token.position == Position(line: 1, column: 14))
    
    // Multiply operator
    token = try tokenizer.nextToken()
    #expect(token.type == .operator(.multiply))
    #expect(token.value == "*")
    #expect(token.position == Position(line: 1, column: 16))
    
    // Function name 'sin'
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "sin")
    #expect(token.position == Position(line: 1, column: 18))
    
    // Left parenthesis
    token = try tokenizer.nextToken()
    #expect(token.type == .leftParen)
    #expect(token.value == "(")
    #expect(token.position == Position(line: 1, column: 21))
    
    // Parameter 'angle'
    token = try tokenizer.nextToken()
    #expect(token.type == .identifier)
    #expect(token.value == "angle")
    #expect(token.position == Position(line: 1, column: 22))
    
    // Right parenthesis
    token = try tokenizer.nextToken()
    #expect(token.type == .rightParen)
    #expect(token.value == ")")
    #expect(token.position == Position(line: 1, column: 27))
    
    // EOF
    token = try tokenizer.nextToken()
    #expect(token.type == .eof)
}

// MARK: - Iterator and Sequence Tests

@Test func testIteratorProtocolConformance() throws {
    let tokenizer = Tokenizer(input: "3 + x")
    
    // Test that we can iterate using next() method
    var token = tokenizer.next()
    #expect(token?.type == .number)
    #expect(token?.value == "3")
    
    token = tokenizer.next()
    #expect(token?.type == .operator(.plus))
    #expect(token?.value == "+")
    
    token = tokenizer.next()
    #expect(token?.type == .identifier)
    #expect(token?.value == "x")
    
    // Should return nil when reaching EOF
    token = tokenizer.next()
    #expect(token == nil)
    
    // Subsequent calls should continue to return nil
    token = tokenizer.next()
    #expect(token == nil)
}

@Test func testSequenceConformanceWithForInLoop() throws {
    let tokenizer = Tokenizer(input: "42 * y")
    var collectedTokens: [Token] = []
    
    // Test for-in loop iteration
    for token in tokenizer {
        collectedTokens.append(token)
    }
    
    // Verify we got the expected tokens (EOF is not included in iteration)
    #expect(collectedTokens.count == 3)
    
    #expect(collectedTokens[0].type == .number)
    #expect(collectedTokens[0].value == "42")
    
    #expect(collectedTokens[1].type == .operator(.multiply))
    #expect(collectedTokens[1].value == "*")
    
    #expect(collectedTokens[2].type == .identifier)
    #expect(collectedTokens[2].value == "y")
}

@Test func testSequenceConformanceWithMap() throws {
    let tokenizer = Tokenizer(input: "1 + 2")
    
    // Test using map function on the sequence
    let tokenValues = tokenizer.map { $0.value }
    
    #expect(tokenValues.count == 3)
    #expect(tokenValues[0] == "1")
    #expect(tokenValues[1] == "+")
    #expect(tokenValues[2] == "2")
}

@Test func testIteratorWithErrorTokens() throws {
    let tokenizer = Tokenizer(input: "3 @ 4")
    
    var token = tokenizer.next()
    #expect(token?.type == .number)
    #expect(token?.value == "3")
    
    token = tokenizer.next()
    #expect(token?.type == .error)
    #expect(token?.value == "@")
    
    token = tokenizer.next()
    #expect(token?.type == .number)
    #expect(token?.value == "4")
    
    // Should return nil after all tokens are consumed
    token = tokenizer.next()
    #expect(token == nil)
}

// MARK: - Comprehensive Integration Tests

@Test func testCompleteExpressionFromRequirement41() throws {
    // Test requirement 4.1: "3.14 + 2 * (x - 1)"
    let tokenizer = Tokenizer(input: "3.14 + 2 * (x - 1)")
    let tokens = try tokenizer.tokenize()
    
    // Verify we have the expected number of tokens (including EOF)
    #expect(tokens.count == 10)
    
    // Verify each token in sequence
    #expect(tokens[0].type == .number)
    #expect(tokens[0].value == "3.14")
    #expect(tokens[0].position == Position(line: 1, column: 1))
    
    #expect(tokens[1].type == .operator(.plus))
    #expect(tokens[1].value == "+")
    #expect(tokens[1].position == Position(line: 1, column: 6))
    
    #expect(tokens[2].type == .number)
    #expect(tokens[2].value == "2")
    #expect(tokens[2].position == Position(line: 1, column: 8))
    
    #expect(tokens[3].type == .operator(.multiply))
    #expect(tokens[3].value == "*")
    #expect(tokens[3].position == Position(line: 1, column: 10))
    
    #expect(tokens[4].type == .leftParen)
    #expect(tokens[4].value == "(")
    #expect(tokens[4].position == Position(line: 1, column: 12))
    
    #expect(tokens[5].type == .identifier)
    #expect(tokens[5].value == "x")
    #expect(tokens[5].position == Position(line: 1, column: 13))
    
    #expect(tokens[6].type == .operator(.minus))
    #expect(tokens[6].value == "-")
    #expect(tokens[6].position == Position(line: 1, column: 15))
    
    #expect(tokens[7].type == .number)
    #expect(tokens[7].value == "1")
    #expect(tokens[7].position == Position(line: 1, column: 17))
    
    #expect(tokens[8].type == .rightParen)
    #expect(tokens[8].value == ")")
    #expect(tokens[8].position == Position(line: 1, column: 18))
    
    #expect(tokens[9].type == .eof)
}

@Test func testAssignmentSyntaxFromRequirement42() throws {
    // Test requirement 4.2: "x = 5"
    let tokenizer = Tokenizer(input: "x = 5")
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 4) // identifier, assign, number, EOF
    
    #expect(tokens[0].type == .identifier)
    #expect(tokens[0].value == "x")
    #expect(tokens[0].position == Position(line: 1, column: 1))
    
    #expect(tokens[1].type == .assign)
    #expect(tokens[1].value == "=")
    #expect(tokens[1].position == Position(line: 1, column: 3))
    
    #expect(tokens[2].type == .number)
    #expect(tokens[2].value == "5")
    #expect(tokens[2].position == Position(line: 1, column: 5))
    
    #expect(tokens[3].type == .eof)
}

@Test func testNegativeNumberContextFromRequirement43() throws {
    // Test requirement 4.3: "-42" - handling negative numbers appropriately
    let tokenizer = Tokenizer(input: "-42")
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 3) // minus operator, number, EOF
    
    #expect(tokens[0].type == .operator(.minus))
    #expect(tokens[0].value == "-")
    #expect(tokens[0].position == Position(line: 1, column: 1))
    
    #expect(tokens[1].type == .number)
    #expect(tokens[1].value == "42")
    #expect(tokens[1].position == Position(line: 1, column: 2))
    
    #expect(tokens[2].type == .eof)
}

@Test func testFunctionCallFromRequirement44() throws {
    // Test requirement 4.4: "sin(x)" - function call tokenization
    let tokenizer = Tokenizer(input: "sin(x)")
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 5) // identifier, lparen, identifier, rparen, EOF
    
    #expect(tokens[0].type == .identifier)
    #expect(tokens[0].value == "sin")
    #expect(tokens[0].position == Position(line: 1, column: 1))
    
    #expect(tokens[1].type == .leftParen)
    #expect(tokens[1].value == "(")
    #expect(tokens[1].position == Position(line: 1, column: 4))
    
    #expect(tokens[2].type == .identifier)
    #expect(tokens[2].value == "x")
    #expect(tokens[2].position == Position(line: 1, column: 5))
    
    #expect(tokens[3].type == .rightParen)
    #expect(tokens[3].value == ")")
    #expect(tokens[3].position == Position(line: 1, column: 6))
    
    #expect(tokens[4].type == .eof)
}

@Test func testComplexMathematicalExpression() throws {
    // Test a complex expression combining all elements
    let tokenizer = Tokenizer(input: "result = (a + b) * sin(theta) / 2.5 - offset^2")
    let tokens = try tokenizer.tokenize()
    

    
    // Verify we get all expected tokens
    #expect(tokens.count == 19) // All tokens plus EOF
    
    // Verify key tokens to ensure proper parsing
    #expect(tokens[0].type == .identifier)
    #expect(tokens[0].value == "result")
    
    #expect(tokens[1].type == .assign)
    #expect(tokens[1].value == "=")
    
    #expect(tokens[2].type == .leftParen)
    #expect(tokens[3].type == .identifier)
    #expect(tokens[3].value == "a")
    
    #expect(tokens[4].type == .operator(.plus))
    #expect(tokens[5].type == .identifier)
    #expect(tokens[5].value == "b")
    
    #expect(tokens[6].type == .rightParen)
    #expect(tokens[7].type == .operator(.multiply))
    
    #expect(tokens[8].type == .identifier)
    #expect(tokens[8].value == "sin")
    
    #expect(tokens[9].type == .leftParen)
    #expect(tokens[10].type == .identifier)
    #expect(tokens[10].value == "theta")
    
    #expect(tokens[11].type == .rightParen)
    #expect(tokens[12].type == .operator(.divide))
    
    #expect(tokens[13].type == .number)
    #expect(tokens[13].value == "2.5")
    
    #expect(tokens[14].type == .operator(.minus))
    #expect(tokens[15].type == .identifier)
    #expect(tokens[15].value == "offset")
    
    #expect(tokens[16].type == .operator(.power))
    #expect(tokens[17].type == .number)
    #expect(tokens[17].value == "2")
    
    #expect(tokens[18].type == .eof)
}

@Test func testMultiLineExpression() throws {
    // Test expression spanning multiple lines
    let input = """
    x = 10
    y = x + 5
    result = x * y
    """
    
    let tokenizer = Tokenizer(input: input)
    let tokens = try tokenizer.tokenize()
    
    // Verify position tracking across lines
    var lineOneTokens = tokens.filter { $0.position.line == 1 }
    var lineTwoTokens = tokens.filter { $0.position.line == 2 }
    var lineThreeTokens = tokens.filter { $0.position.line == 3 }
    
    // Remove EOF token for easier counting
    lineOneTokens = lineOneTokens.filter { $0.type != .eof }
    lineTwoTokens = lineTwoTokens.filter { $0.type != .eof }
    lineThreeTokens = lineThreeTokens.filter { $0.type != .eof }
    
    #expect(lineOneTokens.count == 3) // x, =, 10
    #expect(lineTwoTokens.count == 5) // y, =, x, +, 5
    #expect(lineThreeTokens.count == 5) // result, =, x, *, y
    
    // Verify specific positions
    #expect(lineOneTokens[0].position == Position(line: 1, column: 1))
    #expect(lineTwoTokens[0].position == Position(line: 2, column: 1))
    #expect(lineThreeTokens[0].position == Position(line: 3, column: 1))
}

@Test func testErrorHandlingAndPositionReporting() throws {
    // Test comprehensive error handling with position information
    let tokenizer = Tokenizer(input: "3.14.15 @ x $ 2.3.4.5")
    let tokens = try tokenizer.tokenize()
    
    // Should have: malformed number, error(@), identifier, error($), malformed number, EOF
    #expect(tokens.count == 6)
    
    // First token: malformed number
    #expect(tokens[0].type == .error)
    #expect(tokens[0].value == "3.14.15")
    #expect(tokens[0].position == Position(line: 1, column: 1))
    
    // Second token: invalid character @
    #expect(tokens[1].type == .error)
    #expect(tokens[1].value == "@")
    #expect(tokens[1].position == Position(line: 1, column: 9))
    
    // Third token: valid identifier
    #expect(tokens[2].type == .identifier)
    #expect(tokens[2].value == "x")
    #expect(tokens[2].position == Position(line: 1, column: 11))
    
    // Fourth token: invalid character $
    #expect(tokens[3].type == .error)
    #expect(tokens[3].value == "$")
    #expect(tokens[3].position == Position(line: 1, column: 13))
    
    // Fifth token: another malformed number
    #expect(tokens[4].type == .error)
    #expect(tokens[4].value == "2.3.4.5")
    #expect(tokens[4].position == Position(line: 1, column: 15))
    
    // Sixth token: EOF
    #expect(tokens[5].type == .eof)
}

@Test func testIteratorBehaviorWithComplexExpression() throws {
    // Test iterator behavior with a complex expression
    let tokenizer = Tokenizer(input: "a + b * c")
    var collectedTokens: [Token] = []
    
    // Test multiple iteration methods
    for token in tokenizer {
        collectedTokens.append(token)
    }
    
    #expect(collectedTokens.count == 5) // a, +, b, *, c (EOF not included in iteration)
    
    #expect(collectedTokens[0].type == .identifier)
    #expect(collectedTokens[0].value == "a")
    
    #expect(collectedTokens[1].type == .operator(.plus))
    #expect(collectedTokens[1].value == "+")
    
    #expect(collectedTokens[2].type == .identifier)
    #expect(collectedTokens[2].value == "b")
    
    #expect(collectedTokens[3].type == .operator(.multiply))
    #expect(collectedTokens[3].value == "*")
    
    #expect(collectedTokens[4].type == .identifier)
    #expect(collectedTokens[4].value == "c")
}

@Test func testIteratorWithErrorRecovery() throws {
    // Test that iterator continues after encountering errors
    let tokenizer = Tokenizer(input: "1 @ 2 # 3")
    var collectedTokens: [Token] = []
    
    for token in tokenizer {
        collectedTokens.append(token)
    }
    
    #expect(collectedTokens.count == 5) // 1, @(error), 2, #(error), 3
    
    #expect(collectedTokens[0].type == .number)
    #expect(collectedTokens[0].value == "1")
    
    #expect(collectedTokens[1].type == .error)
    #expect(collectedTokens[1].value == "@")
    
    #expect(collectedTokens[2].type == .number)
    #expect(collectedTokens[2].value == "2")
    
    #expect(collectedTokens[3].type == .error)
    #expect(collectedTokens[3].value == "#")
    
    #expect(collectedTokens[4].type == .number)
    #expect(collectedTokens[4].value == "3")
}

@Test func testIteratorEdgeCases() throws {
    // Test iterator with empty input
    var tokenizer = Tokenizer(input: "")
    var tokens: [Token] = []
    
    for token in tokenizer {
        tokens.append(token)
    }
    
    #expect(tokens.count == 0) // No tokens for empty input
    
    // Test iterator with only whitespace
    tokenizer = Tokenizer(input: "   \n\t  ")
    tokens = []
    
    for token in tokenizer {
        tokens.append(token)
    }
    
    #expect(tokens.count == 0) // No tokens for whitespace-only input
    
    // Test iterator with single token
    tokenizer = Tokenizer(input: "42")
    tokens = []
    
    for token in tokenizer {
        tokens.append(token)
    }
    
    #expect(tokens.count == 1)
    #expect(tokens[0].type == .number)
    #expect(tokens[0].value == "42")
}

@Test func testSequenceOperationsOnComplexExpression() throws {
    // Test various sequence operations
    let tokenizer = Tokenizer(input: "x + y - z")
    
    // Test map operation
    let tokenValues = tokenizer.map { $0.value }
    #expect(tokenValues == ["x", "+", "y", "-", "z"])
    
    // Create new tokenizer for filter test (since iterator is consumed)
    let tokenizer2 = Tokenizer(input: "x + y - z")
    let operatorTokens = tokenizer2.filter { 
        if case .operator = $0.type { return true }
        return false
    }
    #expect(operatorTokens.count == 2)
    #expect(operatorTokens[0].value == "+")
    #expect(operatorTokens[1].value == "-")
    
    // Create new tokenizer for reduce test
    let tokenizer3 = Tokenizer(input: "a b c")
    let concatenated = tokenizer3.reduce("") { result, token in
        result + token.value
    }
    #expect(concatenated == "abc")
}

@Test func testPositionTrackingAccuracy() throws {
    // Test precise position tracking in complex scenarios
    let input = """
    func(x, y)
      = x + y
    """
    
    let tokenizer = Tokenizer(input: input)
    let tokens = try tokenizer.tokenize()
    
    // Verify positions for tokens across lines with different indentation
    let funcToken = tokens.first { $0.value == "func" }!
    #expect(funcToken.position == Position(line: 1, column: 1))
    
    let xToken = tokens.first { $0.value == "x" }!
    #expect(xToken.position == Position(line: 1, column: 6))
    
    let yToken = tokens.first { $0.value == "y" }!
    #expect(yToken.position == Position(line: 1, column: 9))
    
    let assignToken = tokens.first { $0.value == "=" }!
    #expect(assignToken.position == Position(line: 2, column: 3))
    
    // Find the second x token (after the assignment)
    let xTokens = tokens.filter { $0.value == "x" }
    #expect(xTokens.count == 2)
    #expect(xTokens[1].position == Position(line: 2, column: 5))
    
    let plusToken = tokens.first { $0.value == "+" }!
    #expect(plusToken.position == Position(line: 2, column: 7))
    
    // Find the second y token
    let yTokens = tokens.filter { $0.value == "y" }
    #expect(yTokens.count == 2)
    #expect(yTokens[1].position == Position(line: 2, column: 9))
}

@Test func testTokenizeMethodWithComplexInput() throws {
    // Test the tokenize() convenience method with complex input
    let tokenizer = Tokenizer(input: "result = sqrt(x^2 + y^2)")
    let tokens = try tokenizer.tokenize()
    
    // Verify we get all tokens including EOF
    #expect(tokens.count == 13)
    
    // Verify the last token is EOF
    #expect(tokens.last?.type == .eof)
    
    // Verify some key tokens
    #expect(tokens[0].value == "result")
    #expect(tokens[1].value == "=")
    #expect(tokens[2].value == "sqrt")
    #expect(tokens[3].value == "(")
    #expect(tokens[4].value == "x")
    #expect(tokens[5].value == "^")
    #expect(tokens[6].value == "2")
    #expect(tokens[7].value == "+")
    #expect(tokens[8].value == "y")
    #expect(tokens[9].value == "^")
    #expect(tokens[10].value == "2")
    #expect(tokens[11].value == ")")
    #expect(tokens[12].type == .eof)
}

@Test func testTokenizeConvenienceMethod() throws {
    let tokenizer = Tokenizer(input: "x = 5")
    
    // Test tokenize() method returns all tokens including EOF
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 4) // identifier, assign, number, EOF
    
    #expect(tokens[0].type == .identifier)
    #expect(tokens[0].value == "x")
    
    #expect(tokens[1].type == .assign)
    #expect(tokens[1].value == "=")
    
    #expect(tokens[2].type == .number)
    #expect(tokens[2].value == "5")
    
    #expect(tokens[3].type == .eof)
    #expect(tokens[3].value == "")
}

@Test func testTokenizeWithComplexExpression() throws {
    let tokenizer = Tokenizer(input: "result = (a + b) * 2.5")
    
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 10) // All tokens plus EOF
    
    // Verify first few tokens
    #expect(tokens[0].type == .identifier)
    #expect(tokens[0].value == "result")
    
    #expect(tokens[1].type == .assign)
    #expect(tokens[1].value == "=")
    
    #expect(tokens[2].type == .leftParen)
    #expect(tokens[2].value == "(")
    
    #expect(tokens[3].type == .identifier)
    #expect(tokens[3].value == "a")
    
    // Verify last token is EOF
    #expect(tokens.last?.type == .eof)
}

@Test func testTokenizeWithErrorTokens() throws {
    let tokenizer = Tokenizer(input: "3.14.15 + x")
    
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 4) // error, operator, identifier, EOF
    
    #expect(tokens[0].type == .error)
    #expect(tokens[0].value == "3.14.15")
    
    #expect(tokens[1].type == .operator(.plus))
    #expect(tokens[1].value == "+")
    
    #expect(tokens[2].type == .identifier)
    #expect(tokens[2].value == "x")
    
    #expect(tokens[3].type == .eof)
}

@Test func testTokenizeEmptyInput() throws {
    let tokenizer = Tokenizer(input: "")
    
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 1) // Only EOF
    #expect(tokens[0].type == .eof)
}

@Test func testTokenizeWhitespaceOnly() throws {
    let tokenizer = Tokenizer(input: "   \n\t  ")
    
    let tokens = try tokenizer.tokenize()
    
    #expect(tokens.count == 1) // Only EOF (whitespace is skipped)
    #expect(tokens[0].type == .eof)
}

@Test func testIteratorStateManagement() throws {
    let tokenizer = Tokenizer(input: "a b c")
    
    // Test that iterator maintains proper state
    var token = tokenizer.next()
    #expect(token?.value == "a")
    
    token = tokenizer.next()
    #expect(token?.value == "b")
    
    // Create a new iterator from the same tokenizer
    let newIterator = tokenizer.makeIterator()
    
    // The new iterator should continue from where the original left off
    // since makeIterator() returns self
    token = newIterator.next()
    #expect(token?.value == "c")
    
    token = newIterator.next()
    #expect(token == nil)
}