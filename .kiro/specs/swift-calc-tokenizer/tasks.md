# Implementation Plan

- [x] 1. Set up project structure and core types
  - Create Swift package structure with proper module organization
  - Define the foundational data types and enumerations
  - _Requirements: 3.1, 3.2_

- [x] 1.1 Create Position and Token data structures
  - Implement Position struct with line and column tracking
  - Implement Token struct with type, value, and position
  - _Requirements: 2.1, 2.2_

- [x] 1.2 Define TokenType and OperatorType enumerations
  - Create comprehensive TokenType enum covering all token categories
  - Implement OperatorType enum for mathematical operators
  - _Requirements: 1.2, 1.3, 4.2_

- [x] 1.3 Create TokenizerError enumeration
  - Define error cases for invalid characters and malformed numbers
  - Include position information in error cases
  - _Requirements: 2.2, 2.4, 3.4_

- [x] 2. Implement core tokenizer class structure
  - Create main Tokenizer class with initialization and basic scanning setup
  - Implement character navigation and position tracking
  - _Requirements: 3.1, 3.2_

- [x] 2.1 Implement Tokenizer initialization and basic properties
  - Create initializer accepting string input
  - Set up internal state for current position and character tracking
  - _Requirements: 3.2_

- [x] 2.2 Add character navigation and position tracking methods
  - Implement methods to advance through input string
  - Update line and column position tracking
  - _Requirements: 2.1_

- [x] 3. Implement number tokenization
  - Add logic to recognize and parse numeric literals including integers and decimals
  - Handle edge cases and malformed number detection
  - _Requirements: 1.2, 2.4_

- [x] 3.1 Create number recognition and parsing logic
  - Implement digit sequence scanning
  - Add decimal point handling for floating-point numbers
  - _Requirements: 1.2, 4.1_

- [x] 3.2 Add number validation and error handling
  - Detect malformed numbers (multiple decimal points, etc.)
  - Generate appropriate error tokens for invalid number formats
  - _Requirements: 2.4_

- [x] 3.3 Write unit tests for number tokenization
  - Test integer parsing (positive numbers, zero, multi-digit)
  - Test decimal parsing (various decimal formats)
  - Test malformed number error cases
  - _Requirements: 1.2, 2.4_

- [x] 4. Implement operator and delimiter tokenization
  - Add recognition for mathematical operators and parentheses
  - Handle assignment operator
  - _Requirements: 1.3, 1.4, 4.2_

- [x] 4.1 Create operator recognition logic
  - Implement single-character operator detection (+, -, *, /, %, ^)
  - Add parentheses recognition
  - _Requirements: 1.3, 1.4_

- [x] 4.2 Add assignment operator handling
  - Implement equals sign recognition for variable assignment
  - _Requirements: 4.2_

- [x] 4.3 Write unit tests for operators and delimiters
  - Test all mathematical operator recognition
  - Test parentheses tokenization
  - Test assignment operator
  - _Requirements: 1.3, 1.4, 4.2_

- [x] 5. Implement identifier tokenization
  - Add logic to recognize variable names and function identifiers
  - Handle identifier naming rules and validation
  - _Requirements: 1.5, 4.4_

- [x] 5.1 Create identifier recognition and parsing
  - Implement letter/underscore start detection
  - Add alphanumeric continuation logic
  - _Requirements: 1.5, 4.4_

- [x] 5.2 Write unit tests for identifier tokenization
  - Test valid identifier formats
  - Test identifier edge cases (single character, with numbers)
  - _Requirements: 1.5, 4.4_

- [x] 6. Implement whitespace handling and main tokenization loop
  - Add whitespace skipping logic
  - Create the main nextToken() method that orchestrates all token recognition
  - _Requirements: 1.6, 3.3_

- [x] 6.1 Add whitespace detection and skipping
  - Implement space, tab, and newline recognition
  - Update position tracking for newlines
  - _Requirements: 1.6_

- [x] 6.2 Create main nextToken() method
  - Implement the primary tokenization logic that delegates to specific token parsers
  - Add EOF token generation
  - Handle invalid characters with error tokens
  - _Requirements: 1.1, 2.2, 2.3_

- [x] 7. Add iterator support and convenience methods
  - Implement Sequence and IteratorProtocol conformance
  - Add tokenize() method for complete tokenization
  - _Requirements: 3.3_

- [x] 7.1 Implement Sequence and IteratorProtocol conformance
  - Add iterator support for for-in loops
  - Ensure proper iteration behavior and state management
  - _Requirements: 3.3_

- [x] 7.2 Create tokenize() convenience method
  - Implement method to return complete array of tokens
  - Handle errors appropriately in batch processing
  - _Requirements: 3.3_

- [x] 8. Write comprehensive integration tests
  - Test complete mathematical expressions from requirements
  - Test error handling and position reporting
  - Test iterator behavior and edge cases
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 9. Add example usage and documentation
  - Create example code demonstrating tokenizer usage
  - Add inline documentation for public APIs
  - _Requirements: 3.1_

- [x] 9.1 Create usage examples
  - Write example code showing basic tokenization
  - Demonstrate error handling patterns
  - _Requirements: 3.1_

- [x] 9.2 Add API documentation
  - Document public methods and types with Swift documentation comments
  - Include usage examples in documentation
  - _Requirements: 3.1_