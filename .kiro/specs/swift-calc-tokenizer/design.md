# Design Document

## Overview

The Swift calculator tokenizer will be implemented as a lightweight, efficient module that converts source text into a stream of tokens. The design follows Swift best practices with value types, error handling, and iterator patterns. The tokenizer uses a finite state machine approach for robust character processing and provides detailed position tracking for error reporting.

## Architecture

The tokenizer follows a single-pass, character-by-character scanning approach with lookahead capabilities. The main components are:

- **Token**: A value type representing individual lexical units
- **TokenType**: An enumeration of all possible token types
- **Position**: A structure tracking line and column information
- **Tokenizer**: The main tokenizer class with scanning logic
- **TokenizerError**: Custom error types for tokenization failures

## Components and Interfaces

### Token Structure
```swift
struct Token {
    let type: TokenType
    let value: String
    let position: Position
}
```

### TokenType Enumeration
```swift
enum TokenType {
    case number
    case identifier
    case operator(OperatorType)
    case leftParen
    case rightParen
    case assign
    case eof
    case error
}

enum OperatorType {
    case plus, minus, multiply, divide, modulo, power
}
```

### Position Tracking
```swift
struct Position {
    let line: Int
    let column: Int
}
```

### Main Tokenizer Class
```swift
class Tokenizer {
    private let input: String
    private var currentIndex: String.Index
    private var position: Position
    
    init(input: String)
    func nextToken() throws -> Token
    func tokenize() throws -> [Token]
}
```

### Iterator Support
The tokenizer will conform to `IteratorProtocol` and `Sequence` to enable Swift's for-in loops and functional programming patterns.

## Data Models

### Character Classification
The tokenizer categorizes characters into:
- **Digits**: 0-9 for number parsing
- **Letters**: a-z, A-Z, _ for identifiers
- **Operators**: +, -, *, /, %, ^ for mathematical operations
- **Delimiters**: (, ) for grouping
- **Whitespace**: spaces, tabs, newlines (ignored)
- **Special**: = for assignment

### Number Parsing
Numbers support both integer and floating-point formats:
- Integer: sequence of digits (123, 0, 999)
- Decimal: digits with single decimal point (3.14, 0.5, 123.0)
- Scientific notation is not supported in this simple implementation

### Identifier Rules
Identifiers follow standard programming language conventions:
- Must start with letter or underscore
- Can contain letters, digits, and underscores
- Case-sensitive
- No reserved keywords in this simple calculator

## Error Handling

### TokenizerError Types
```swift
enum TokenizerError: Error {
    case invalidCharacter(Character, Position)
    case malformedNumber(String, Position)
    case unexpectedEndOfInput(Position)
}
```

### Error Recovery
- Invalid characters generate ERROR tokens with position information
- Malformed numbers are reported with the problematic substring
- The tokenizer continues processing after errors when possible

## Testing Strategy

### Unit Testing Approach
1. **Token Type Recognition**: Test each token type individually
2. **Position Tracking**: Verify accurate line/column reporting
3. **Error Conditions**: Test invalid input handling
4. **Edge Cases**: Empty input, single characters, boundary conditions
5. **Integration**: Test complete expressions end-to-end

### Test Categories
- **Basic Tokens**: Numbers, operators, identifiers, parentheses
- **Complex Numbers**: Decimals, leading zeros, edge cases
- **Whitespace Handling**: Spaces, tabs, newlines
- **Error Cases**: Invalid characters, malformed numbers
- **Position Accuracy**: Multi-line input, column tracking
- **Iterator Behavior**: Sequence conformance, multiple iterations

### Performance Considerations
- Single-pass scanning for O(n) time complexity
- Minimal memory allocation during tokenization
- Efficient string indexing using Swift's String.Index
- Lazy evaluation where appropriate for large inputs