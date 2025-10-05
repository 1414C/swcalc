# Requirements Document

## Introduction

This feature involves building a tokenizer module in Swift for a simple calculator programming language. The tokenizer will be responsible for breaking down source code text into meaningful tokens that can be processed by a parser. It will handle numbers, operators, parentheses, identifiers, and whitespace, providing the foundation for a calculator language interpreter.

## Requirements

### Requirement 1

**User Story:** As a developer building a calculator language interpreter, I want a tokenizer that can identify and categorize different types of tokens, so that I can parse mathematical expressions and variable assignments.

#### Acceptance Criteria

1. WHEN the tokenizer receives input text THEN it SHALL identify and return a sequence of tokens
2. WHEN the tokenizer encounters a number (integer or decimal) THEN it SHALL create a NUMBER token with the numeric value
3. WHEN the tokenizer encounters an operator (+, -, *, /, %, ^) THEN it SHALL create an OPERATOR token with the operator type
4. WHEN the tokenizer encounters parentheses THEN it SHALL create LPAREN or RPAREN tokens accordingly
5. WHEN the tokenizer encounters an identifier (variable name) THEN it SHALL create an IDENTIFIER token with the name
6. WHEN the tokenizer encounters whitespace THEN it SHALL skip it and continue processing

### Requirement 2

**User Story:** As a developer using the tokenizer, I want clear token types and position information, so that I can provide meaningful error messages and debug parsing issues.

#### Acceptance Criteria

1. WHEN a token is created THEN it SHALL include the token type, value, and position information (line and column)
2. WHEN the tokenizer encounters an invalid character THEN it SHALL create an ERROR token with position information
3. WHEN the tokenizer reaches the end of input THEN it SHALL create an EOF (end of file) token
4. IF the tokenizer encounters a malformed number THEN it SHALL create an ERROR token with descriptive information

### Requirement 3

**User Story:** As a developer integrating the tokenizer, I want a clean Swift API that follows language conventions, so that it's easy to use and maintain.

#### Acceptance Criteria

1. WHEN using the tokenizer THEN it SHALL provide a Swift-idiomatic interface with proper naming conventions
2. WHEN initializing the tokenizer THEN it SHALL accept a string input and provide methods to retrieve tokens
3. WHEN iterating through tokens THEN it SHALL support both sequential access and iterator patterns
4. WHEN handling errors THEN it SHALL use Swift's error handling mechanisms appropriately

### Requirement 4

**User Story:** As a developer working with calculator expressions, I want the tokenizer to handle common mathematical syntax, so that users can write natural mathematical expressions.

#### Acceptance Criteria

1. WHEN the tokenizer processes "3.14 + 2 * (x - 1)" THEN it SHALL correctly identify all tokens in sequence
2. WHEN the tokenizer encounters assignment syntax like "x = 5" THEN it SHALL create appropriate IDENTIFIER, ASSIGN, and NUMBER tokens
3. WHEN the tokenizer processes negative numbers like "-42" THEN it SHALL handle the context appropriately
4. WHEN the tokenizer encounters function calls like "sin(x)" THEN it SHALL tokenize the identifier and parentheses correctly
5. Use the Swift Testing framework in a separate source file to conduct both positive and negative tests on the tokenizer via it's API.
