# SwiftCalc - Calculator Language Tokenizer and Parser

A comprehensive Swift package for tokenizing and parsing calculator expressions. This package provides both a tokenizer that converts source text into tokens and a parser that builds Abstract Syntax Trees (ASTs) from those tokens. It supports multi-line programs, comments, and comprehensive mathematical expressions.

Test git access.

## Features

### Tokenizer (SwiftCalcTokenizer)
- **Comprehensive Token Support**: Numbers (integers and decimals), mathematical operators, identifiers, parentheses, assignment, and comments
- **Position Tracking**: Detailed line and column information for error reporting and debugging
- **Error Handling**: Graceful handling of invalid characters and malformed syntax with detailed error information
- **Comment Support**: Single-line comments starting with `//`
- **Swift-Idiomatic API**: Clean, type-safe interface following Swift conventions
- **Iterator Support**: Full support for Swift's `Sequence` and `IteratorProtocol` for easy iteration
- **Performance**: Efficient single-pass tokenization with O(n) time complexity

### Parser (SwiftCalcParser)
- **Multi-Statement Programs**: Parse files containing multiple calculator expressions
- **Comprehensive AST**: Strongly-typed Abstract Syntax Tree with full position information
- **Operator Precedence**: Correct handling of mathematical operator precedence and associativity
- **Function Calls**: Support for mathematical functions like `sin()`, `cos()`, `log()`, etc.
- **Error Recovery**: Advanced error recovery mechanisms for better error reporting
- **Visitor Pattern**: Extensible visitor pattern for AST analysis and transformation
- **AST Pass System**: Modular analysis passes for semantic analysis and optimization
- **Type Analysis**: Number type analysis and variable type inference with promotion rules
- **Performance Benchmarks**: Built-in performance testing and analysis tools

### Demo Application
- **Command Line Tool**: Complete demo application showing tokenizer and parser usage
- **Multi-Line File Support**: Process calculator programs from text files
- **Visual AST Display**: Beautiful tree visualization of parsed expressions
- **Comprehensive Analysis**: Detailed analysis of parsed expressions including complexity metrics
- **AST Pass Analysis**: Demonstrates number type analysis and variable type inference
- **Annotated AST Visualization**: Shows type information directly in the AST tree structure

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/SwiftCalc.git", from: "1.0.0")
]
```

The package provides three products:
- `SwiftCalcTokenizer`: The tokenizer library
- `SwiftCalcParser`: The parser library (depends on SwiftCalcTokenizer)
- `swift-calc-demo`: Command line demo application

## Quick Start

### Using the Demo Application

```bash
# Build the project
swift build

# Run the demo with a calculator file
swift run swift-calc-demo Sources/SwiftCalcDemo/simple_example.calc
```

### Basic Tokenization

```swift
import SwiftCalcTokenizer

// Basic tokenization
let tokenizer = Tokenizer(input: "3.14 + x * 2")
let tokens = try tokenizer.tokenize()

for token in tokens {
    print(token) // NUMBER('3.14') at 1:1, OPERATOR(+) at 1:6, etc.
}
```

### Basic Parsing

```swift
import SwiftCalcTokenizer
import SwiftCalcParser

// Parse a single expression
let input = "result = (a + b) * sin(x) - 2 ^ 3"
let tokenizer = Tokenizer(input: input)
let tokens = try tokenizer.tokenize()
let parser = Parser(tokens: tokens)
let ast = try parser.parse()

// Parse a multi-line program
let program = """
// Calculator program
x = 5
y = 3
result = (x + y) * 2
"""
let programTokenizer = Tokenizer(input: program)
let programTokens = try programTokenizer.tokenize()
let programParser = Parser(tokens: programTokens)
let programAST = try programParser.parseProgram()
```

### AST Pass System

The parser includes a sophisticated pass system for semantic analysis and optimization:

```swift
import SwiftCalcParser
import SwiftCalcTokenizer

// Parse an expression with variables
let input = """
x = 10
y = 3.14
result = x + y
"""
let tokenizer = Tokenizer(input: input)
let tokens = try tokenizer.tokenize()
let parser = Parser(tokens: tokens)
let ast = try parser.parseProgram()

// Run analysis passes
let passManager = ASTPassManager.withStandardAnalysis()
let results = try passManager.runPasses(on: ast)

// Get number type analysis
if let numberAnalysis = results.getNumberTypeAnalysis() {
    print("Found \(numberAnalysis.totalCount) numbers:")
    print("  Integers: \(numberAnalysis.integerCount)")
    print("  Floats: \(numberAnalysis.floatCount)")
}

// Get variable type inference
if let variableAnalysis = results.getVariableTypeInference() {
    print("Found \(variableAnalysis.totalVariableCount) variables:")
    for variable in variableAnalysis.variables {
        print("  \(variable.name): \(variable.inferredType)")
    }
}

// Generate annotated AST visualization
let annotatedAST = try AnnotatedASTVisualizer.visualize(ast, with: results)
print(annotatedAST)
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

## Calculator Language Syntax

The calculator language supports mathematical expressions with the following syntax:

### Basic Expressions
```
x = 42
y = 3.14
result = x + y * 2
```

### Mathematical Operations
```
addition = a + b
subtraction = a - b
multiplication = a * b
division = a / b
modulo = a % b
exponentiation = a ^ b
```

### Function Calls
```
trigonometry = sin(x) + cos(y) - tan(z)
logarithms = log(a) + exp(b) + sqrt(c)
```

### Complex Expressions
```
complex = (a + b) * (c - d) / (e + 1)
nested = ((x * 2) + (y * 3)) ^ 2
```

### Multi-Line Programs
```
// This is a comment
x = 5
y = 3
result = (x + y) * sin(x) - 2 ^ 3
final = result * y + cos(x)
```

## Supported Tokens

### Numbers
- Integers: `42`, `0`, `123`
- Decimals: `3.14`, `0.5`, `123.456`

### Operators
- Addition: `+`
- Subtraction: `-` (binary and unary)
- Multiplication: `*`
- Division: `/`
- Modulo: `%`
- Exponentiation: `^`

### Identifiers
- Variable names: `x`, `result`, `myVariable`
- Function names: `sin`, `cos`, `sqrt`, `log`, `exp`, `tan`, `floor`, `ceil`, `abs`
- Must start with letter or underscore, can contain letters, digits, and underscores

### Delimiters
- Left parenthesis: `(`
- Right parenthesis: `)`
- Assignment: `=`

### Comments
- Single-line comments: `// This is a comment`

### Special Tokens
- End of file: `EOF`
- Error tokens for invalid input

## AST Pass System

The parser includes a modular pass system for semantic analysis and code optimization. Passes analyze the AST to extract information, perform type checking, and enable advanced features.

### Available Passes

#### NumberTypeAnalysisPass
Analyzes numeric literals in the AST to determine their types (integer vs float).

**Features:**
- Identifies all numeric literals in expressions
- Classifies numbers as integers (`42`, `0`) or floats (`3.14`, `2.0`)
- Provides position information for each number
- Calculates type distribution statistics

**Example:**
```swift
let pass = NumberTypeAnalysisPass()
let result = try pass.run(on: ast)

print("Total numbers: \(result.totalCount)")
print("Integers: \(result.integerCount)")
print("Floats: \(result.floatCount)")

for number in result.numbers {
    print("\(number.value): \(number.type) at \(number.position)")
}
```

#### VariableTypeInferencePass
Infers variable types based on assignments and expressions using type promotion rules.

**Type Promotion Rules:**
- `integer op integer = integer`
- `integer op float = float`
- `float op float = float`

**Features:**
- Analyzes variable assignments to infer optimal types
- Handles type promotion when mixing integers and floats
- Tracks confidence levels for type inference decisions
- Provides detailed reasoning for each type decision
- Detects and reports type promotions

**Example:**
```swift
// First run number analysis (required dependency)
let numberPass = NumberTypeAnalysisPass()
let numberResult = try numberPass.run(on: ast)

// Then run variable type inference
let typePass = VariableTypeInferencePass()
let typeResult = try typePass.run(on: ast, with: numberResult)

for variable in typeResult.variables {
    print("\(variable.name): \(variable.inferredType)")
    print("  Confidence: \(variable.confidence * 100)%")
    print("  Reason: \(variable.reason)")
}
```

### Pass Manager

The `ASTPassManager` coordinates multiple passes and manages dependencies:

```swift
// Create manager with standard analysis passes
let manager = ASTPassManager.withStandardAnalysis()

// Or create custom manager
let customManager = ASTPassManager()
customManager.addPass(NumberTypeAnalysisPass())
customManager.addPass(VariableTypeInferencePass())

// Run all passes
let results = try manager.runPasses(on: ast)

// Access specific results
let numberAnalysis = results.getNumberTypeAnalysis()
let variableAnalysis = results.getVariableTypeInference()
```

### Annotated AST Visualization

The pass system includes enhanced AST visualization that shows analysis results:

```swift
// Run passes and get results
let results = try passManager.runPasses(on: ast)

// Generate annotated visualization
let annotatedAST = try AnnotatedASTVisualizer.visualize(ast, with: results)
print(annotatedAST)
```

**Example Output:**
```
└── Program: (3 statements) [@1:1]
    ├── Assignment: = [@1:3]
    │   ├── Identifier: x [@1:1, 🔢 var:integer]
    │   └── Literal: 10 [@1:5, 🔢 integer, val: 10.0]
    ├── Assignment: = [@2:3]
    │   ├── Identifier: y [@2:1, 🔣 var:float]
    │   └── Literal: 3.14 [@2:5, 🔣 float, val: 3.14]
    └── Assignment: = [@3:8]
        ├── Identifier: result [@3:1, 🔣 var:float]
        └── BinaryOp: + [@3:10]
            ├── Identifier: x [@3:8, 🔢 var:integer]
            └── Identifier: y [@3:12, 🔣 var:float]
```

**Legend:**
- `🔢` Integer literal/variable
- `🔣` Float literal/variable
- `@line:col` Position in source
- `val:` Parsed numeric value
- `var:type` Variable type inference

### Type Promotion Example

```swift
// Calculator program with type promotion
let program = """
x = 5        // x starts as integer
x = 3.14     // x promoted to float
y = 10       // y is integer
z = y + 2.5  // z becomes float (integer + float = float)
"""

let ast = try parseProgram(program)
let results = try passManager.runPasses(on: ast)
let variables = results.getVariableTypeInference()?.variables ?? []

for variable in variables {
    if variable.confidence < 1.0 {
        print("Type promotion detected:")
        print("  \(variable.name): \(variable.reason)")
    }
}
```

## Demo Application

The package includes a comprehensive command-line demo application that showcases the tokenizer and parser capabilities.

### Usage

```bash
# Build the project
swift build

# Run with a calculator file
swift run swift-calc-demo <input-file>

# Try the included examples
swift run swift-calc-demo Sources/SwiftCalcDemo/simple_example.calc
swift run swift-calc-demo Sources/SwiftCalcDemo/complex_example.calc
```

### Example Output

```
📖 Reading input file: Sources/SwiftCalcDemo/variable_example.calc
📄 File content:
──────────────────────────────────────────────────
x = 10
y = 3.14
intResult = x + 5
floatResult = y * 2.0
mixedResult = x + y
functionResult = sin(x)
──────────────────────────────────────────────────

🔍 Tokenizing...
🔤 Tokens (28):
────────────────────────────────────────────────────────────
  1: [1:1]    IDENTIFIER      →   'x'
  2: [1:3]    ASSIGN          →   '='
  3: [1:5]    NUMBER          →   '10'
  4: [2:1]    IDENTIFIER      →   'y'
  5: [2:3]    ASSIGN          →   '='
  6: [2:5]    NUMBER          →   '3.14'
  ...

🌳 Parsing...
✅ Parsed as multi-statement program
🌳 Abstract Syntax Tree:
────────────────────────────────────────────────────────────
└── Program: (6 statements)
    ├── Assignment: =
    │   ├── Identifier: x
    │   └── Literal: 10
    ├── Assignment: =
    │   ├── Identifier: y
    │   └── Literal: 3.14
    ├── Assignment: =
    │   ├── Identifier: intResult
    │   └── BinaryOp: +
    │       ├── Identifier: x
    │       └── Literal: 5
    └── Assignment: =
        ├── Identifier: functionResult
        └── FunctionCall: sin(1)
            └── Identifier: x

📊 AST Analysis:
────────────────────────────────────────
Total nodes: 26
Tree depth: 4
Complexity score: 34
────────────────────────────────────────

🔬 AST Pass Analysis:
────────────────────────────────────────
Number Type Analysis:
  Total numbers: 4
  Integers: 2
  Floats: 2
  Number details:
    🔢 10 (integer) at 1:5
    🔣 3.14 (float) at 2:5
    🔢 5 (integer) at 3:17
    🔣 2.0 (float) at 4:19

Variable Type Inference:
  Total variables: 6
  Integer variables: 2
  Float variables: 4
  Variable details:
    🔢 x: integer (100.0% confidence)
      Reason: Inferred from assignment of integer expression
      First assigned at: 1:3
    🔣 y: float (100.0% confidence)
      Reason: Inferred from assignment of float expression
      First assigned at: 2:3
    🔣 mixedResult: float (100.0% confidence)
      Reason: Inferred from assignment of float expression
      First assigned at: 5:13
    🔣 functionResult: float (100.0% confidence)
      Reason: Inferred from assignment of float expression
      First assigned at: 6:16

🎨 Annotated AST (with pass results):
────────────────────────────────────────────────────────────
└── Program: (6 statements) [@1:1]
    ├── Assignment: = [@1:3]
    │   ├── Identifier: x [@1:1, 🔢 var:integer]
    │   └── Literal: 10 [@1:5, 🔢 integer, val: 10.0]
    ├── Assignment: = [@2:3]
    │   ├── Identifier: y [@2:1, 🔣 var:float]
    │   └── Literal: 3.14 [@2:5, 🔣 float, val: 3.14]
    ├── Assignment: = [@5:13]
    │   ├── Identifier: mixedResult [@5:1, 🔣 var:float]
    │   └── BinaryOp: + [@5:17]
    │       ├── Identifier: x [@5:15, 🔢 var:integer]
    │       └── Identifier: y [@5:19, 🔣 var:float]
    └── Assignment: = [@6:16]
        ├── Identifier: functionResult [@6:1, 🔣 var:float]
        └── FunctionCall: sin(1) [@6:18]
            └── Identifier: x [@6:22, 🔢 var:integer]

🎯 Final Analysis Summary:
────────────────────────────────────────
📊 Type Distribution:
  Total numeric literals: 4
  Total variables: 6
  🔢 Integer types: 4 (40.0%)
  🔣 Float types: 6 (60.0%)
────────────────────────────────────────
```

### Creating Calculator Files

Create `.calc` files with calculator language syntax:

```
// my_program.calc
// Calculate the area of a circle
radius = 5
pi = 3.14159
area = pi * radius ^ 2
circumference = 2 * pi * radius

// More complex calculations
hypotenuse = sqrt(a ^ 2 + b ^ 2)
angle = sin(x) + cos(y)
```

### Type Promotion Example

Create a file showing type promotion:

```
// type_promotion_example.calc
x = 5        // x starts as integer
x = 3.14     // x promoted to float
y = 10       // y remains integer
z = y + 2.5  // z becomes float (integer + float = float)
result = sin(x) + cos(y)  // result is float (function calls return float)
```

When run with the demo, this shows:

```
⚡ Type Promotions Detected:
  • x: Type promotion from integer to float due to assignment of float
```

## API Reference

### Tokenizer Types

#### `Tokenizer`
The main tokenizer class that processes input text and produces tokens.

```swift
public class Tokenizer: Sequence, IteratorProtocol {
    public init(input: String)
    public func nextToken() throws -> Token
    public func tokenize() throws -> [Token]
}
```

### Parser Types

#### `Parser`
The main parser class that transforms tokens into Abstract Syntax Trees.

```swift
public class Parser {
    public init(tokens: [Token])
    public func parse() throws -> Expression
    public func parseProgram() throws -> Program
    public func parseWithErrorRecovery() -> (expression: Expression?, errors: [ParseError])
}
```

#### `Program`
Represents a multi-statement calculator program.

```swift
public struct Program: ASTNode, Expression {
    public let statements: [Expression]
    public let position: Position
}
```

#### `Expression`
Protocol for all expression nodes in the AST.

```swift
public protocol Expression: ASTNode {
    func accept<V: ASTVisitor>(_ visitor: V) throws -> V.Result
}
```

### AST Node Types

The parser creates various AST node types:

- `Literal`: Numeric literals (`42`, `3.14`)
- `Identifier`: Variable and function names (`x`, `sin`)
- `BinaryOperation`: Binary operations (`+`, `-`, `*`, `/`, `%`, `^`)
- `UnaryOperation`: Unary operations (`-x`)
- `Assignment`: Variable assignments (`x = 5`)
- `FunctionCall`: Function calls (`sin(x)`)
- `ParenthesizedExpression`: Grouped expressions (`(a + b)`)
- `Program`: Multi-statement programs

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
    case comment
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

#### `ParseError`
Error types for parsing failures.

```swift
public enum ParseError: Error {
    case unexpectedToken(Token, expected: [TokenType])
    case unexpectedEndOfInput(Position)
    case invalidAssignmentTarget(Token)
    case unmatchedParenthesis(Position)
    case tokenizerError(TokenizerError, Position)
}
```

### Visitor Pattern

The parser supports the visitor pattern for AST analysis:

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
    func visitProgram(_ node: Program) throws -> Result
}
```

Built-in visitors include:
- `ASTStringVisitor`: Convert AST back to string representation
- `ASTDebugVisitor`: Create detailed debug output
- `ASTTreeVisualizer`: Generate visual tree representations
- `ASTSerializationVisitor`: Serialize AST to JSON
- `ASTDepthVisitor`: Calculate AST depth
- `ASTNodeCountVisitor`: Count total nodes

### AST Pass Types

#### `ASTPassManager`
Coordinates multiple AST passes and manages dependencies.

```swift
public class ASTPassManager {
    public init(debugMode: Bool = false)
    public static func withStandardAnalysis(debugMode: Bool = false) -> ASTPassManager
    public func addPass<T: BaseASTPass<R>, R>(_ pass: T)
    public func addStandardAnalysisPasses()
    public func runPasses(on node: Expression) throws -> ASTPassResults
}
```

#### `NumberTypeAnalysisPass`
Analyzes numeric literals to determine their types.

```swift
public class NumberTypeAnalysisPass: BaseASTPass<NumberTypeAnalysisResult> {
    public init(debugMode: Bool = false)
    public func run(on node: Expression) throws -> NumberTypeAnalysisResult
}
```

#### `VariableTypeInferencePass`
Infers variable types based on usage and type promotion rules.

```swift
public class VariableTypeInferencePass: BaseASTPass<VariableTypeInferenceResult> {
    public init(debugMode: Bool = false)
    public func run(on node: Expression, with numberAnalysis: NumberTypeAnalysisResult) throws -> VariableTypeInferenceResult
}
```

#### `NumberTypeAnalysisResult`
Contains results from number type analysis.

```swift
public struct NumberTypeAnalysisResult {
    public let numbers: [NumberTypeInfo]
    public var totalCount: Int
    public var integerCount: Int
    public var floatCount: Int
    
    public func numbers(ofType type: NumberType) -> [NumberTypeInfo]
}
```

#### `VariableTypeInferenceResult`
Contains results from variable type inference.

```swift
public struct VariableTypeInferenceResult {
    public let variables: [VariableTypeInfo]
    public var totalVariableCount: Int
    public var integerVariableCount: Int
    public var floatVariableCount: Int
    
    public func variables(ofType type: NumberType) -> [VariableTypeInfo]
    public func typeInfo(for name: String) -> VariableTypeInfo?
}
```

#### `VariableTypeInfo`
Information about an inferred variable type.

```swift
public struct VariableTypeInfo {
    public let name: String
    public let inferredType: NumberType
    public let firstAssignmentPosition: Position
    public let confidence: Double  // 0.0 to 1.0
    public let reason: String
}
```

#### `AnnotatedASTVisualizer`
Creates enhanced AST visualizations with pass results.

```swift
public class AnnotatedASTVisualizer {
    public static func visualize(_ node: Expression, with results: ASTPassResults) throws -> String
}
```

## Examples

### Tokenizer Examples

The package includes comprehensive examples in `Sources/SwiftCalcTokenizer/Examples.swift`:

```swift
import SwiftCalcTokenizer

// Run all examples
TokenizerExamples.runAllExamples()

// Or run specific examples
TokenizerExamples.basicTokenization()
TokenizerExamples.errorHandling()
TokenizerExamples.positionTracking()
```

### Parser Examples

The parser includes examples in `Sources/SwiftCalcParser/Examples.swift`:

```swift
import SwiftCalcParser
import SwiftCalcTokenizer

// Run all parser examples
ParserExamples.runAllExamples()

// Or run specific examples
ParserExamples.basicParsing()
ParserExamples.astAnalysis()
ParserExamples.visitorPattern()
```

### AST Analysis

```swift
import SwiftCalcParser
import SwiftCalcTokenizer

let input = "result = (a + b) * sin(x) - 2 ^ 3"
let tokenizer = Tokenizer(input: input)
let tokens = try tokenizer.tokenize()
let parser = Parser(tokens: tokens)
let ast = try parser.parse()

// Basic AST analysis
let nodeCount = try ASTAnalysis.countNodes(in: ast)
let depth = try ASTAnalysis.calculateDepth(of: ast)
let identifiers = ASTAnalysis.extractIdentifiers(from: ast)
let complexity = try ASTAnalysis.calculateComplexity(of: ast)

print("Nodes: \(nodeCount), Depth: \(depth), Complexity: \(complexity)")
print("Variables: \(identifiers.joined(separator: ", "))")
```

### AST Pass Analysis

```swift
import SwiftCalcParser
import SwiftCalcTokenizer

// Parse a program with variables and type mixing
let program = """
x = 10
y = 3.14
result = x + y
funcResult = sin(x)
"""

let tokenizer = Tokenizer(input: program)
let tokens = try tokenizer.tokenize()
let parser = Parser(tokens: tokens)
let ast = try parser.parseProgram()

// Run AST passes
let passManager = ASTPassManager.withStandardAnalysis()
let results = try passManager.runPasses(on: ast)

// Analyze number types
if let numberAnalysis = results.getNumberTypeAnalysis() {
    print("Number Analysis:")
    print("  Total: \(numberAnalysis.totalCount)")
    print("  Integers: \(numberAnalysis.integerCount)")
    print("  Floats: \(numberAnalysis.floatCount)")
    
    for number in numberAnalysis.numbers {
        print("  \(number.value): \(number.type)")
    }
}

// Analyze variable types
if let variableAnalysis = results.getVariableTypeInference() {
    print("\nVariable Analysis:")
    print("  Total: \(variableAnalysis.totalVariableCount)")
    
    for variable in variableAnalysis.variables {
        let confidence = String(format: "%.0f", variable.confidence * 100)
        print("  \(variable.name): \(variable.inferredType) (\(confidence)%)")
        
        if variable.confidence < 1.0 {
            print("    → \(variable.reason)")
        }
    }
}

// Generate annotated AST
let annotatedAST = try AnnotatedASTVisualizer.visualize(ast, with: results)
print("\nAnnotated AST:")
print(annotatedAST)
```

## Testing

The package includes comprehensive test suites for both tokenizer and parser:

### Tokenizer Tests
- Basic token recognition
- Error handling and recovery
- Position tracking accuracy
- Iterator behavior
- Edge cases and malformed input
- Performance characteristics

### Parser Tests
- Expression parsing with correct precedence
- AST node creation and structure
- Error handling and recovery
- Visitor pattern functionality
- Multi-statement program parsing
- AST pass system functionality
- Number type analysis accuracy
- Variable type inference and promotion rules
- Performance benchmarks

### Performance Benchmarks
The parser includes detailed performance benchmarks:
- Large expression parsing speed
- Memory usage analysis
- Scalability testing
- Error recovery performance

Run all tests with:

```bash
swift test
```

Run specific test suites:

```bash
# Run only tokenizer tests
swift test --filter SwiftCalcTokenizerTests

# Run only parser tests  
swift test --filter SwiftCalcParserTests

# Run performance benchmarks
swift test --filter PerformanceBenchmarkTests
```

## Performance

Both the tokenizer and parser are designed for efficiency:

### Tokenizer Performance
- **Time Complexity**: O(n) single-pass scanning
- **Memory Usage**: Minimal allocation during tokenization
- **Throughput**: Processes thousands of tokens per second

### Parser Performance
- **Time Complexity**: O(n) for most expressions, O(n log n) for deeply nested expressions
- **Memory Usage**: Efficient AST representation with minimal overhead
- **Scalability**: Handles expressions with thousands of operands
- **Benchmarks**: Built-in performance tests show:
  - 5000 operands parsed in ~0.03 seconds
  - Memory usage scales linearly with expression size
  - Deep nesting (1000+ levels) handled gracefully

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