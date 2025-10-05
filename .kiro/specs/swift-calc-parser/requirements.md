# Requirements Document

## Introduction

This document specifies the requirements for a Swift calculator parser module that processes tokens from SwiftCalcTokenizer and constructs an Abstract Syntax Tree (AST). The parser will implement proper operator precedence and associativity rules to correctly represent mathematical expressions and assignments in a tree structure suitable for evaluation or further analysis.

The parser serves as the second stage in a calculator language processing pipeline: source text → tokenizer → parser → AST → evaluator. It bridges the gap between lexical analysis (tokenization) and semantic analysis (evaluation) by providing a structured representation of the parsed expressions.

## Requirements

### Requirement 1

**User Story:** As a developer using the calculator language, I want the parser to correctly handle operator precedence so that mathematical expressions are evaluated in the proper order.

#### Acceptance Criteria

1. WHEN the parser processes tokens for "2 + 3 * 4" THEN the system SHALL create an AST where multiplication has higher precedence than addition
2. WHEN the parser processes tokens for "2 ^ 3 ^ 4" THEN the system SHALL create an AST with right-associative exponentiation (equivalent to "2 ^ (3 ^ 4)")
3. WHEN the parser processes tokens for "10 - 5 - 2" THEN the system SHALL create an AST with left-associative subtraction (equivalent to "(10 - 5) - 2")
4. WHEN the parser processes tokens for "a = b = 5" THEN the system SHALL create an AST with right-associative assignment (equivalent to "a = (b = 5)")
5. WHEN the parser processes tokens containing mixed operators THEN the system SHALL follow the precedence order: parentheses, exponentiation, multiplication/division/modulo, addition/subtraction, assignment

### Requirement 2

**User Story:** As a developer, I want the parser to support parentheses for explicit grouping so that I can override default operator precedence.

#### Acceptance Criteria

1. WHEN the parser processes tokens for "(2 + 3) * 4" THEN the system SHALL create an AST where addition is evaluated before multiplication
2. WHEN the parser processes tokens for "2 * (3 + 4)" THEN the system SHALL create an AST where addition is evaluated before multiplication
3. WHEN the parser processes tokens for nested parentheses like "((2 + 3) * 4)" THEN the system SHALL correctly handle multiple levels of grouping
4. WHEN the parser processes tokens for "2 + (3 * (4 + 5))" THEN the system SHALL create an AST respecting nested grouping precedence
5. WHEN the parser encounters unmatched parentheses THEN the system SHALL report a syntax error with position information

### Requirement 3

**User Story:** As a developer, I want the parser to create a strongly-typed AST so that I can safely traverse and analyze the parsed expressions.

#### Acceptance Criteria

1. WHEN designing the AST node create a node attribute to track whether an identifier or number is a decimal or an integer.
2. WHEN the parser processes any valid expression THEN the system SHALL create an AST with type-safe nodes
3. WHEN the parser creates binary operation nodes THEN the system SHALL include the operator type, left operand, and right operand
4. WHEN the parser creates literal nodes THEN the system SHALL preserve the original token value and position information
5. WHEN the parser creates identifier nodes THEN the system SHALL preserve the variable name and position information
6. WHEN the parser creates assignment nodes THEN the system SHALL distinguish between the target identifier and the assigned expression
7. WHEN the parser creates any AST node THEN the system SHALL include position information for error reporting

### Requirement 4

**User Story:** As a developer, I want the parser to handle syntax errors gracefully so that I can provide meaningful error messages to users.

#### Acceptance Criteria

1. WHEN the parser encounters unexpected tokens THEN the system SHALL report a syntax error with the token position and expected token types
2. WHEN the parser encounters incomplete expressions THEN the system SHALL report an error indicating what was expected
3. WHEN the parser encounters invalid assignment targets THEN the system SHALL report an error explaining that only identifiers can be assigned to
4. WHEN the parser encounters error tokens from the tokenizer THEN the system SHALL report parsing errors that reference the original tokenization errors
5. WHEN the parser reports any error THEN the system SHALL include line and column position information from the original source

### Requirement 5

**User Story:** As a developer, I want the parser to support unary operators so that I can handle negative numbers and other unary expressions.

#### Acceptance Criteria

1. WHEN the parser processes tokens for "-5" THEN the system SHALL create an AST with a unary minus node containing the literal 5
2. WHEN the parser processes tokens for "-(2 + 3)" THEN the system SHALL create an AST with a unary minus node containing the addition expression
3. WHEN the parser processes tokens for "x = -y" THEN the system SHALL create an AST where the assignment value is a unary minus applied to identifier y
4. WHEN the parser processes tokens for "--5" THEN the system SHALL create an AST with nested unary minus operations
5. WHEN the parser processes tokens for "2 * -3" THEN the system SHALL correctly handle the unary minus with proper precedence

### Requirement 6

**User Story:** As a developer, I want the parser to provide a clean API that integrates seamlessly with SwiftCalcTokenizer so that I can easily build a complete language processor.

#### Acceptance Criteria

1. WHEN I create a parser instance THEN the system SHALL accept an array of tokens from SwiftCalcTokenizer
2. WHEN I call the parse method THEN the system SHALL return either a successful AST or a detailed error
3. WHEN the parser succeeds THEN the system SHALL consume all tokens except the EOF token
4. WHEN the parser is used with SwiftCalcTokenizer THEN the system SHALL handle all token types produced by the tokenizer
5. WHEN the parser API is used THEN the system SHALL follow Swift naming conventions and provide comprehensive documentation

### Requirement 7

**User Story:** As a developer, I want the parser to support function call syntax so that the AST can represent function invocations for future extension.

#### Acceptance Criteria

1. WHEN the parser processes tokens for "sin(x)" THEN the system SHALL create an AST with a function call node containing the function name and argument
2. WHEN the parser processes tokens for "max(a, b)" THEN the system SHALL create an AST with a function call node containing multiple arguments
3. WHEN the parser processes tokens for "f()" THEN the system SHALL create an AST with a function call node with no arguments
4. WHEN the parser processes tokens for nested function calls like "sin(cos(x))" THEN the system SHALL create an AST with properly nested function call nodes
5. WHEN the parser encounters malformed function calls THEN the system SHALL report appropriate syntax errors

### Requirement 8

**User Story:** As a developer, I want the AST to be traversable and serializable so that I can implement visitors, evaluators, and debugging tools.

#### Acceptance Criteria

1. WHEN I traverse an AST THEN the system SHALL provide a visitor pattern or similar mechanism for tree traversal
2. WHEN I need to debug parsing results THEN the system SHALL provide a readable string representation of the AST
3. WHEN I serialize an AST THEN the system SHALL preserve all structural and positional information
4. WHEN I implement an evaluator THEN the system SHALL provide clear interfaces for accessing node data
5. WHEN I analyze an AST THEN the system SHALL provide methods to identify node types and extract relevant information