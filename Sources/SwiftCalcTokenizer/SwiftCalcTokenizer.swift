/// SwiftCalcTokenizer - A tokenizer for simple calculator expressions
/// 
/// This module provides tokenization capabilities for a simple calculator language,
/// supporting numbers, operators, identifiers, and basic syntax elements.
///
/// The main types provided by this module are:
/// - `Position`: Tracks line and column information
/// - `Token`: Represents a tokenized element with type, value, and position
/// - `TokenType`: Enumeration of all possible token types
/// - `OperatorType`: Enumeration of mathematical operators
/// - `TokenizerError`: Error types for tokenization failures

import Foundation

/// A tokenizer for simple calculator expressions
/// 
/// The Tokenizer class processes input text character by character and converts it into
/// a sequence of tokens that can be consumed by a parser. It tracks position information
/// for error reporting and supports both sequential token access and iterator patterns.
///
/// Example usage:
/// ```swift
/// let tokenizer = Tokenizer(input: "3.14 + x")
/// let token = try tokenizer.nextToken() // Returns NUMBER token for "3.14"
/// 
/// // Using iterator support
/// for token in tokenizer {
///     print(token)
/// }
/// ```
public class Tokenizer: Sequence, IteratorProtocol {
    // MARK: - Private Properties
    
    /// The input string being tokenized
    private let input: String
    
    /// Current position in the input string
    private var currentIndex: String.Index
    
    /// Current line and column position for error reporting
    private var position: Position
    
    /// The current character being processed (nil if at end of input)
    private var currentCharacter: Character? {
        guard currentIndex < input.endIndex else { return nil }
        return input[currentIndex]
    }
    
    // MARK: - Initialization
    
    /// Creates a new tokenizer with the specified input string
    /// - Parameter input: The string to tokenize
    public init(input: String) {
        self.input = input
        self.currentIndex = input.startIndex
        self.position = Position(line: 1, column: 1)
    }
    
    // MARK: - Character Navigation
    
    /// Advances to the next character in the input string
    /// Updates position tracking for line and column numbers
    private func advance() {
        guard currentIndex < input.endIndex else { return }
        
        // Check if current character is a newline before advancing
        if input[currentIndex] == "\n" {
            position = Position(line: position.line + 1, column: 1)
        } else {
            position = Position(line: position.line, column: position.column + 1)
        }
        
        currentIndex = input.index(after: currentIndex)
    }
    
    /// Peeks at the next character without advancing the current position
    /// - Returns: The next character, or nil if at end of input
    private func peek() -> Character? {
        let nextIndex = input.index(after: currentIndex)
        guard nextIndex < input.endIndex else { return nil }
        return input[nextIndex]
    }
    
    /// Checks if the current position is at the end of the input
    /// - Returns: true if at end of input, false otherwise
    private func isAtEnd() -> Bool {
        return currentIndex >= input.endIndex
    }
    
    // MARK: - Whitespace Handling
    
    /// Checks if a character is whitespace (space, tab, newline, etc.)
    /// - Parameter char: The character to check
    /// - Returns: true if the character is whitespace, false otherwise
    private func isWhitespace(_ char: Character) -> Bool {
        return char.isWhitespace
    }
    
    /// Skips all whitespace characters from the current position
    /// Updates position tracking appropriately for newlines
    private func skipWhitespace() {
        while let char = currentCharacter, isWhitespace(char) {
            advance()
        }
    }
    
    // MARK: - Character Classification
    
    /// Checks if a character is a digit (0-9)
    /// - Parameter char: The character to check
    /// - Returns: true if the character is a digit, false otherwise
    private func isDigit(_ char: Character) -> Bool {
        return char.isNumber
    }
    
    /// Checks if a character is a letter (a-z, A-Z) or underscore
    /// - Parameter char: The character to check
    /// - Returns: true if the character is a letter or underscore, false otherwise
    private func isLetter(_ char: Character) -> Bool {
        return char.isLetter || char == "_"
    }
    
    /// Checks if a character is alphanumeric (letter, digit, or underscore)
    /// - Parameter char: The character to check
    /// - Returns: true if the character is alphanumeric or underscore, false otherwise
    private func isAlphanumeric(_ char: Character) -> Bool {
        return isLetter(char) || isDigit(char)
    }
    
    // MARK: - Number Tokenization
    
    /// Scans and parses a number token (integer or decimal)
    /// - Returns: A number token with the parsed value
    /// - Throws: TokenizerError.malformedNumber if the number format is invalid
    private func scanNumber() throws -> Token {
        let startPosition = position
        var numberString = ""
        
        // Scan digits before decimal point
        while let char = currentCharacter, isDigit(char) {
            numberString.append(char)
            advance()
        }
        
        // Check for decimal point
        if let char = currentCharacter, char == "." {
            // Look ahead to ensure there's at least one digit after the decimal point
            if let nextChar = peek(), isDigit(nextChar) {
                numberString.append(char)
                advance()
                
                // Scan digits after decimal point
                while let char = currentCharacter, isDigit(char) {
                    numberString.append(char)
                    advance()
                }
                
                // Check for additional decimal points (malformed number)
                if let char = currentCharacter, char == "." {
                    // Scan the rest of the malformed number for error reporting
                    var malformedString = numberString
                    while let char = currentCharacter, (isDigit(char) || char == ".") {
                        malformedString.append(char)
                        advance()
                    }
                    throw TokenizerError.malformedNumber(malformedString, startPosition)
                }
            }
            // If there's no digit after the decimal point, we don't consume the decimal point
            // This allows "3." to be tokenized as "3" followed by whatever comes after the dot
        }
        
        // Validate that we have a valid number
        if numberString.isEmpty {
            throw TokenizerError.malformedNumber("", startPosition)
        }
        
        return Token(type: .number, value: numberString, position: startPosition)
    }
    
    // MARK: - Identifier Tokenization
    
    /// Scans and parses an identifier token (variable names, function names)
    /// - Returns: An identifier token with the parsed name
    private func scanIdentifier() -> Token {
        let startPosition = position
        var identifierString = ""
        
        // First character must be a letter or underscore
        if let char = currentCharacter, isLetter(char) {
            identifierString.append(char)
            advance()
        }
        
        // Continue with alphanumeric characters and underscores
        while let char = currentCharacter, isAlphanumeric(char) {
            identifierString.append(char)
            advance()
        }
        
        return Token(type: .identifier, value: identifierString, position: startPosition)
    }
    
    /// Scans a comment starting with //
    /// 
    /// This method processes single-line comments that start with // and continue
    /// to the end of the line. The comment text (excluding the //) is captured
    /// as the token value.
    /// 
    /// - Parameter startPosition: The position where the comment starts
    /// - Returns: A comment token containing the comment text
    private func scanComment(startPosition: Position) -> Token {
        var commentString = "//"
        
        // Consume the second '/'
        advance()
        
        // Scan until end of line or end of input
        while let char = currentCharacter, char != "\n" {
            commentString.append(char)
            advance()
        }
        
        return Token(type: .comment, value: commentString, position: startPosition)
    }
    
    /// Creates an error token for malformed numbers and invalid characters
    /// - Parameters:
    ///   - error: The tokenizer error that occurred
    ///   - value: The string value to include in the error token
    /// - Returns: An error token with the specified information
    private func createErrorToken(for error: TokenizerError, value: String) -> Token {
        let position: Position
        switch error {
        case .invalidCharacter(_, let pos), .malformedNumber(_, let pos), .unexpectedEndOfInput(let pos):
            position = pos
        }
        return Token(type: .error, value: value, position: position)
    }
    
    // MARK: - Public Methods
    
    /// Returns the next token from the input stream
    /// 
    /// This is the main tokenization method that orchestrates all token recognition.
    /// It delegates to specific token parsers based on the current character and
    /// handles error cases by returning error tokens rather than throwing exceptions.
    /// 
    /// - Returns: The next token, or EOF if at end of input
    /// - Throws: TokenizerError for malformed input (converted to error tokens)
    public func nextToken() throws -> Token {
        // Skip all whitespace characters
        skipWhitespace()
        
        // Check for end of input - return EOF token
        guard let char = currentCharacter else {
            return Token(type: .eof, value: "", position: position)
        }
        
        // Delegate to number parser for digits
        if isDigit(char) {
            do {
                return try scanNumber()
            } catch let error as TokenizerError {
                // Convert tokenization errors to error tokens for graceful handling
                let errorValue: String
                switch error {
                case .malformedNumber(let value, _):
                    errorValue = value
                default:
                    errorValue = String(char)
                }
                return createErrorToken(for: error, value: errorValue)
            }
        }
        
        // Delegate to identifier parser for letters and underscores
        if isLetter(char) {
            return scanIdentifier()
        }
        
        // Handle single-character operators and delimiters
        let tokenPosition = position
        advance()
        
        switch char {
        case "+":
            return Token(type: .operator(.plus), value: "+", position: tokenPosition)
        case "-":
            return Token(type: .operator(.minus), value: "-", position: tokenPosition)
        case "*":
            return Token(type: .operator(.multiply), value: "*", position: tokenPosition)
        case "/":
            // Check if this is a comment (//) or division operator
            if let nextChar = currentCharacter, nextChar == "/" {
                // This is a comment, scan to end of line
                return scanComment(startPosition: tokenPosition)
            } else {
                // This is a division operator
                return Token(type: .operator(.divide), value: "/", position: tokenPosition)
            }
        case "%":
            return Token(type: .operator(.modulo), value: "%", position: tokenPosition)
        case "^":
            return Token(type: .operator(.power), value: "^", position: tokenPosition)
        case "(":
            return Token(type: .leftParen, value: "(", position: tokenPosition)
        case ")":
            return Token(type: .rightParen, value: ")", position: tokenPosition)
        case "=":
            return Token(type: .assign, value: "=", position: tokenPosition)
        default:
            // Handle invalid characters by creating error tokens
            return createErrorToken(for: .invalidCharacter(char, tokenPosition), value: String(char))
        }
    }
    
    // MARK: - Sequence and IteratorProtocol Conformance
    
    /// Returns the next token in the sequence for iterator protocol
    /// 
    /// This method enables the tokenizer to be used in for-in loops and other
    /// Swift iteration patterns. It returns nil when the EOF token is reached
    /// to signal the end of iteration.
    /// 
    /// - Returns: The next token, or nil if at end of input
    public func next() -> Token? {
        do {
            let token = try nextToken()
            // Return nil when we reach EOF to end iteration
            if case .eof = token.type {
                return nil
            }
            return token
        } catch {
            // If there's an error during tokenization, we still want to continue
            // iteration, so we return an error token instead of nil
            return Token(type: .error, value: "tokenization_error", position: position)
        }
    }
    
    /// Returns an iterator for the tokenizer sequence
    /// 
    /// Since Tokenizer itself conforms to IteratorProtocol, it returns itself.
    /// This enables the use of for-in loops and other sequence operations.
    /// 
    /// - Returns: Self as the iterator
    public func makeIterator() -> Tokenizer {
        return self
    }
    
    // MARK: - Convenience Methods
    
    /// Tokenizes the entire input and returns an array of all tokens
    /// 
    /// This convenience method processes the complete input string and returns
    /// all tokens including the final EOF token. It handles errors by including
    /// error tokens in the result rather than throwing exceptions.
    /// 
    /// Example usage:
    /// ```swift
    /// let tokenizer = Tokenizer(input: "3 + 4")
    /// let tokens = try tokenizer.tokenize()
    /// // Returns: [NUMBER("3"), OPERATOR(+), NUMBER("4"), EOF]
    /// ```
    /// 
    /// - Returns: An array containing all tokens from the input
    /// - Throws: TokenizerError if there are critical tokenization failures
    public func tokenize() throws -> [Token] {
        var tokens: [Token] = []
        
        while true {
            let token = try nextToken()
            tokens.append(token)
            
            // Stop when we reach EOF
            if case .eof = token.type {
                break
            }
        }
        
        return tokens
    }
}