# SwiftCalcTokenizer

A Swift package for tokenizing simple calculator expressions. This tokenizer converts source text into a stream of tokens that can be processed by a parser, supporting numbers, operators, identifiers, and basic syntax elements.

## Features

- **Comprehensive Token Support**: Numbers (integers and decimals), mathematical operators, identifiers, parentheses, and assignment
- **Position Tracking**: Detailed line and column information for error reporting and debugging
- **Error Handling**: Graceful handling of invalid characters and malformed syntax with detailed error information
- **Swift-Idiomatic API**: Clean, type-safe interface following Swift conventions
- **Iterator Support**: Full support for Swift's `Sequence` and `IteratorProtocol` for easy iteration
- **Performance**: Efficient single-pass tokenization with O(n) time complexity

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/SwiftCalcTokenizer.git", from: "1.0.0")
]
```

## Quick Start

```swift
import SwiftCalcTokenizer

// Basic tokenization
let tokenizer = Tokenizer(input: "3.14 + x * 2")
let tokens = try tokenizer.tokenize()

for token in tokens {
    print(token) // NUMBER('3.14') at 1:1, OPERATOR(+) at 1:6, etc.
}
```

## Usage Examples

### Basic Tokenization

```swift
import SwiftCalcTokenizer

let input = "result = (a + b) / 2"
let tokenizer = Tokenizer(input: input)

// Method 1: Get all tokens at once
do {
    let tokens = try tokenizer.tokenize()
    for token in tokens {
        print(token)
    }
} catch {
    print("Tokenization error: \(error)")
}

// Method 2: Process tokens sequentially
let tokenizer2 = Tokenizer(input: input)
do {
    while true {
        let token = try tokenizer2.nextToken()
        print(token)
        if case .eof = token.type { break }
    }
} catch {
    print("Error: \(error)")
}

// Method 3: Use iterator support
let tokenizer3 = Tokenizer(input: input)
for token in tokenizer3 {
    print(token)
}
```

### Error Handling

```swift
let input = "3.14.159 + @"  // Contains malformed number and invalid character
let tokenizer = Tokenizer(input: input)

do {
    let tokens = try tokenizer.tokenize()
    for token in tokens {
        switch token.type {
        case .error:
            print("❌ Error token: \(token)")
        default:
            print("✅ Valid token: \(token)")
        }
    }
} catch {
    print("Tokenization failed: \(error)")
}
```

### Position Tracking

```swift
let input = """
x = 3.14
y = x + @
result = x * y
"""

let tokenizer = Tokenizer(input: input)
let tokens = try tokenizer.tokenize()

for token in tokens {
    if case .error = token.type {
        print("Error at line \(token.position.line), column \(token.position.column): \(token.value)")
    }
}
```

## Supported Tokens

### Numbers
- Integers: `42`, `0`, `123`
- Decimals: `3.14`, `0.5`, `123.456`

### Operators
- Addition: `+`
- Subtraction: `-`
- Multiplication: `*`
- Division: `/`
- Modulo: `%`
- Exponentiation: `^`

### Identifiers
- Variable names: `x`, `result`, `myVariable`
- Function names: `sin`, `cos`, `sqrt`
- Must start with letter or underscore, can contain letters, digits, and underscores

### Delimiters
- Left parenthesis: `(`
- Right parenthesis: `)`
- Assignment: `=`

### Special Tokens
- End of file: `EOF`
- Error tokens for invalid input

## API Reference

### Core Types

#### `Tokenizer`
The main tokenizer class that processes input text and produces tokens.

```swift
public class Tokenizer: Sequence, IteratorProtocol {
    public init(input: String)
    public func nextToken() throws -> Token
    public func tokenize() throws -> [Token]
}
```

#### `Token`
Represents a single token with type, value, and position information.

```swift
public struct Token {
    public let type: TokenType
    public let value: String
    public let position: Position
}
```

#### `TokenType`
Enumeration of all possible token types.

```swift
public enum TokenType {
    case number
    case identifier
    case operator(OperatorType)
    case leftParen
    case rightParen
    case assign
    case eof
    case error
}
```

#### `Position`
Tracks line and column information for tokens.

```swift
public struct Position {
    public let line: Int    // 1-based
    public let column: Int  // 1-based
}
```

#### `TokenizerError`
Error types for tokenization failures.

```swift
public enum TokenizerError: Error {
    case invalidCharacter(Character, Position)
    case malformedNumber(String, Position)
    case unexpectedEndOfInput(Position)
}
```

## Examples

The package includes comprehensive examples in `Sources/SwiftCalcTokenizer/Examples.swift`. Run them with:

```swift
import SwiftCalcTokenizer

// Run all examples
TokenizerExamples.runAllExamples()

// Or run specific examples
TokenizerExamples.basicTokenization()
TokenizerExamples.errorHandling()
TokenizerExamples.positionTracking()
```

## Testing

The package includes comprehensive tests covering:

- Basic token recognition
- Error handling
- Position tracking
- Iterator behavior
- Edge cases and malformed input

Run tests with:

```bash
swift test
```

## Performance

The tokenizer is designed for efficiency:

- **Time Complexity**: O(n) single-pass scanning
- **Memory Usage**: Minimal allocation during tokenization
- **Throughput**: Processes thousands of tokens per second

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Requirements

- Swift 5.0+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+