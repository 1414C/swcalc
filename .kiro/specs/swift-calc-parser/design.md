# Design Document

## Overview

The Swift Calculator Parser is a recursive descent parser that transforms a sequence of tokens from SwiftCalcTokenizer into an Abstract Syntax Tree (AST). The parser implements operator precedence parsing using the precedence climbing algorithm, ensuring mathematical expressions are correctly structured according to standard precedence and associativity rules.

The parser follows a modular design with separate concerns for AST node definitions, parsing logic, error handling, and tree traversal. It integrates seamlessly with SwiftCalcTokenizer and provides a foundation for expression evaluation, code generation, or other language processing tasks.

## Architecture

### Core Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Token Array   │───▶│     Parser       │───▶│   AST Nodes     │
│ (from Tokenizer)│    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Error Handling  │    │ Tree Traversal  │
                       │                  │    │   (Visitor)     │
                       └──────────────────┘    └─────────────────┘
```

### Parser Architecture

The parser uses a recursive descent approach with precedence climbing for binary operators:

1. **Lexical Interface**: Consumes tokens from SwiftCalcTokenizer
2. **Precedence Engine**: Handles operator precedence and associativity
3. **AST Builder**: Constructs type-safe AST nodes
4. **Error Reporter**: Provides detailed syntax error information
5. **Position Tracker**: Maintains source position information throughout parsing

### Precedence Levels

The parser implements the following precedence hierarchy (highest to lowest):

```
Level 6: Parentheses, Function calls     ()
Level 5: Unary operators                 - (unary minus)
Level 4: Exponentiation                  ^ (right-associative)
Level 3: Multiplicative                  * / % (left-associative)
Level 2: Additive                        + - (left-associative)
Level 1: Assignment                      = (right-associative)
```

## Components and Interfaces

### AST Node Hierarchy

```swift
// Base protocol for all AST nodes
public protocol ASTNode {
    var position: Position { get }
    func accept<V: ASTVisitor>(_ visitor: V) throws -> V.Result
}

// Expression nodes (can be evaluated to values)
public protocol Expression: ASTNode {}

// Statement nodes (perform actions, may not return values)
public protocol Statement: ASTNode {}
```

### Core AST Node Types

#### Binary Operation Node
```swift
public struct BinaryOperation: Expression {
    public let operator: OperatorType
    public let left: Expression
    public let right: Expression
    public let position: Position
}
```

#### Unary Operation Node
```swift
public struct UnaryOperation: Expression {
    public enum UnaryOperator {
        case minus  // -
    }
    
    public let operator: UnaryOperator
    public let operand: Expression
    public let position: Position
}
```

#### Literal Node
```swift
public struct Literal: Expression {
    public let value: String  // Preserve original token value
    public let position: Position
}
```

#### Identifier Node
```swift
public struct Identifier: Expression {
    public let name: String
    public let position: Position
}
```

#### Assignment Node
```swift
public struct Assignment: Expression {
    public let target: Identifier
    public let value: Expression
    public let position: Position
}
```

#### Function Call Node
```swift
public struct FunctionCall: Expression {
    public let name: String
    public let arguments: [Expression]
    public let position: Position
}
```

#### Parenthesized Expression Node
```swift
public struct ParenthesizedExpression: Expression {
    public let expression: Expression
    public let position: Position
}
```

### Parser Interface

```swift
public class Parser {
    public init(tokens: [Token])
    public func parse() throws -> Expression
    public func parseStatement() throws -> Statement
}
```

### Error Types

```swift
public enum ParseError: Error {
    case unexpectedToken(Token, expected: [TokenType])
    case unexpectedEndOfInput(Position)
    case invalidAssignmentTarget(Token)
    case unmatchedParenthesis(Position)
    case tokenizerError(TokenizerError, Position)
}
```

## Data Models

### Operator Precedence Table

```swift
struct OperatorInfo {
    let precedence: Int
    let associativity: Associativity
}

enum Associativity {
    case left
    case right
}

static let operatorTable: [OperatorType: OperatorInfo] = [
    .power:    OperatorInfo(precedence: 4, associativity: .right),
    .multiply: OperatorInfo(precedence: 3, associativity: .left),
    .divide:   OperatorInfo(precedence: 3, associativity: .left),
    .modulo:   OperatorInfo(precedence: 3, associativity: .left),
    .plus:     OperatorInfo(precedence: 2, associativity: .left),
    .minus:    OperatorInfo(precedence: 2, associativity: .left)
]
```

### Parser State

```swift
private struct ParserState {
    var tokens: [Token]
    var currentIndex: Int
    var currentToken: Token? { 
        currentIndex < tokens.count ? tokens[currentIndex] : nil 
    }
}
```

## Error Handling

### Error Recovery Strategy

The parser implements a panic-mode error recovery strategy:

1. **Detection**: Identify syntax errors at the earliest possible point
2. **Reporting**: Provide detailed error messages with position information
3. **Recovery**: Skip tokens until a synchronization point is found
4. **Continuation**: Resume parsing from a stable state

### Synchronization Points

- Statement boundaries (assignment operators)
- Expression boundaries (operators at current precedence level)
- Structural boundaries (parentheses, function calls)

### Error Message Format

```swift
// Example error messages:
"Unexpected token '+' at line 2, column 5. Expected number or identifier."
"Unmatched closing parenthesis ')' at line 1, column 15."
"Invalid assignment target at line 3, column 8. Only identifiers can be assigned to."
```

## Testing Strategy

### Unit Testing Approach

1. **Parser Component Tests**
   - Test each parsing method in isolation
   - Mock token sequences for specific scenarios
   - Verify AST structure and node properties

2. **Integration Tests**
   - Test complete parsing pipeline with SwiftCalcTokenizer
   - Verify end-to-end functionality with real expressions
   - Test error propagation from tokenizer to parser

3. **Precedence Tests**
   - Comprehensive test suite for operator precedence
   - Test all operator combinations and associativity rules
   - Verify parentheses override precedence correctly

4. **Error Handling Tests**
   - Test all error conditions and recovery scenarios
   - Verify error message accuracy and position information
   - Test malformed input handling

### Test Categories

#### Precedence and Associativity Tests
```swift
// Test cases for precedence verification
"2 + 3 * 4"     → Addition(2, Multiplication(3, 4))
"2 ^ 3 ^ 4"     → Exponentiation(2, Exponentiation(3, 4))
"10 - 5 - 2"    → Subtraction(Subtraction(10, 5), 2)
"a = b = 5"     → Assignment(a, Assignment(b, 5))
```

#### Parentheses Tests
```swift
"(2 + 3) * 4"   → Multiplication(Addition(2, 3), 4)
"2 * (3 + 4)"   → Multiplication(2, Addition(3, 4))
"((2 + 3))"     → ParenthesizedExpression(Addition(2, 3))
```

#### Function Call Tests
```swift
"sin(x)"        → FunctionCall("sin", [Identifier("x")])
"max(a, b)"     → FunctionCall("max", [Identifier("a"), Identifier("b")])
"f(g(x))"       → FunctionCall("f", [FunctionCall("g", [Identifier("x")])])
```

#### Error Condition Tests
```swift
"2 + + 3"       → ParseError.unexpectedToken
"(2 + 3"        → ParseError.unmatchedParenthesis
"5 = x"         → ParseError.invalidAssignmentTarget
```

### Performance Testing

- **Large Expression Parsing**: Test parser performance with deeply nested expressions
- **Memory Usage**: Verify AST memory footprint for complex trees
- **Error Recovery**: Measure performance impact of error handling

## Implementation Notes

### Recursive Descent Structure

The parser follows a standard recursive descent pattern:

```swift
// Grammar production rules map to parsing methods
parseExpression()     // Handles assignment (lowest precedence)
parseAdditive()       // Handles + and -
parseMultiplicative() // Handles *, /, %
parseExponentiation() // Handles ^ (right-associative)
parseUnary()          // Handles unary -
parsePrimary()        // Handles literals, identifiers, parentheses, function calls
```

### Precedence Climbing Algorithm

For binary operators, the parser uses precedence climbing to handle precedence and associativity efficiently:

```swift
func parseExpression(minPrecedence: Int = 0) throws -> Expression {
    var left = try parseUnary()
    
    while let op = currentOperator, 
          precedence(of: op) >= minPrecedence {
        advance() // consume operator
        
        let nextMinPrec = precedence(of: op) + 
                         (isLeftAssociative(op) ? 1 : 0)
        let right = try parseExpression(minPrecedence: nextMinPrec)
        
        left = BinaryOperation(operator: op, left: left, right: right, position: position)
    }
    
    return left
}
```

### AST Visitor Pattern

The AST supports the visitor pattern for tree traversal:

```swift
public protocol ASTVisitor {
    associatedtype Result
    
    func visit(_ node: BinaryOperation) throws -> Result
    func visit(_ node: UnaryOperation) throws -> Result
    func visit(_ node: Literal) throws -> Result
    func visit(_ node: Identifier) throws -> Result
    func visit(_ node: Assignment) throws -> Result
    func visit(_ node: FunctionCall) throws -> Result
    func visit(_ node: ParenthesizedExpression) throws -> Result
}
```

This design enables clean separation of concerns and supports multiple AST processing operations (evaluation, code generation, optimization, etc.) without modifying the AST node definitions.