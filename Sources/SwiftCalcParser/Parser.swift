import Foundation
import SwiftCalcTokenizer

/// A recursive descent parser that transforms tokens into an Abstract Syntax Tree
/// 
/// The Parser class implements a recursive descent parser with precedence climbing
/// for binary operators. It processes tokens produced by SwiftCalcTokenizer and
/// constructs a strongly-typed AST that represents the structure of mathematical
/// expressions and assignments.
/// 
/// Example usage:
/// ```swift
/// let tokenizer = SwiftCalcTokenizer(input: "2 + 3 * 4")
/// let tokens = try tokenizer.tokenize()
/// let parser = Parser(tokens: tokens)
/// let ast = try parser.parse()
/// ```
public class Parser {
    /// The array of tokens to parse
    private let tokens: [Token]
    
    /// Current position in the token array
    private var currentIndex: Int = 0
    
    /// The current token being processed
    private var currentToken: Token? {
        return currentIndex < tokens.count ? tokens[currentIndex] : nil
    }
    
    /// Array to collect multiple errors during parsing (for error recovery mode)
    private var collectedErrors: [ParseError] = []
    
    /// Flag to enable error recovery mode (collect multiple errors instead of stopping at first)
    private var errorRecoveryMode: Bool = false
    
    /// Parser state tracking for debugging and error recovery
    private var parserState: ParserState
    
    /// Flag to enable debug mode for detailed state tracking
    private var debugMode: Bool = false
    
    /// Creates a new parser with the given tokens
    /// 
    /// The parser expects a complete array of tokens including an EOF token
    /// at the end. The tokens should be produced by SwiftCalcTokenizer.
    /// 
    /// - Parameter tokens: Array of tokens to parse
    public init(tokens: [Token]) {
        self.tokens = tokens
        self.parserState = ParserState(tokenCount: tokens.count)
    }
    
    /// Creates a new parser with error recovery mode enabled
    /// 
    /// In error recovery mode, the parser will attempt to collect multiple
    /// errors instead of stopping at the first error. This is useful for
    /// providing comprehensive error reports.
    /// 
    /// - Parameters:
    ///   - tokens: Array of tokens to parse
    ///   - enableErrorRecovery: Whether to enable error recovery mode
    public init(tokens: [Token], enableErrorRecovery: Bool) {
        self.tokens = tokens
        self.errorRecoveryMode = enableErrorRecovery
        self.parserState = ParserState(tokenCount: tokens.count)
    }
    
    /// Creates a new parser with debug mode enabled
    /// 
    /// In debug mode, the parser will track detailed state information
    /// and parsing operations for debugging and analysis purposes.
    /// 
    /// - Parameters:
    ///   - tokens: Array of tokens to parse
    ///   - enableErrorRecovery: Whether to enable error recovery mode
    ///   - enableDebugMode: Whether to enable debug mode
    public init(tokens: [Token], enableErrorRecovery: Bool = false, enableDebugMode: Bool = false) {
        self.tokens = tokens
        self.errorRecoveryMode = enableErrorRecovery
        self.debugMode = enableDebugMode
        self.parserState = ParserState(tokenCount: tokens.count)
    }
    
    /// Parses the tokens and returns the root AST node
    /// 
    /// This is the main entry point for parsing. It processes all tokens
    /// and returns a complete AST representing the parsed expression.
    /// The method expects the token array to end with an EOF token and
    /// validates that all tokens are consumed during parsing.
    /// 
    /// - Returns: The root expression node of the AST
    /// - Throws: ParseError if syntax errors are encountered
    public func parse() throws -> Expression {
        // Reset parser state to beginning
        resetParserState()
        
        // Handle empty token array
        guard !tokens.isEmpty else {
            throw ParseError.unexpectedEndOfInput(Position(line: 1, column: 1))
        }
        
        // Check for error tokens from tokenizer before parsing
        try validateTokensForErrors()
        
        // Record start of parsing
        recordOperation("parse", context: "main")
        
        // Parse the main expression
        let expression = try parseExpression()
        
        // Validate that we've consumed all tokens except EOF
        try validateEndOfInput()
        
        // Record completion of parsing
        recordOperation("parse_complete", context: "main")
        
        return expression
    }
    
    /// Parses the tokens with error recovery and returns both result and errors
    /// 
    /// This method attempts to parse the tokens while collecting multiple errors.
    /// It returns a tuple containing the parsed expression (if any) and an array
    /// of all errors encountered during parsing.
    /// 
    /// - Returns: A tuple containing the optional parsed expression and array of errors
    public func parseWithErrorRecovery() -> (expression: Expression?, errors: [ParseError]) {
        // Enable error recovery mode
        errorRecoveryMode = true
        collectedErrors = []
        
        // Reset parser state
        resetParserState()
        
        var expression: Expression? = nil
        
        // Handle empty token array
        guard !tokens.isEmpty else {
            let error = ParseError.unexpectedEndOfInput(Position(line: 1, column: 1))
            collectedErrors.append(error)
            return (nil, collectedErrors)
        }
        
        do {
            // Check for error tokens from tokenizer before parsing
            try validateTokensForErrors()
            
            // Parse the main expression
            expression = try parseExpression()
            
            // Validate that we've consumed all tokens except EOF
            try validateEndOfInput()
            
        } catch let error as ParseError {
            collectedErrors.append(error)
        } catch {
            // Convert any other errors to ParseError
            let position = currentToken?.position ?? Position(line: 1, column: 1)
            let parseError = ParseError.unexpectedEndOfInput(position)
            collectedErrors.append(parseError)
        }
        
        return (expression, collectedErrors)
    }
    
    /// Parses multiple statements/expressions from the token stream
    /// 
    /// This method parses a sequence of expressions separated by newlines or semicolons,
    /// returning a Program node that contains all the parsed statements. This enables
    /// parsing of multi-line calculator programs.
    /// 
    /// - Returns: A Program node containing all parsed statements
    /// - Throws: ParseError if syntax errors are encountered
    public func parseProgram() throws -> Program {
        // Reset parser state to beginning
        resetParserState()
        
        // Handle empty token array
        guard !tokens.isEmpty else {
            throw ParseError.unexpectedEndOfInput(Position(line: 1, column: 1))
        }
        
        // Check for error tokens from tokenizer before parsing
        try validateTokensForErrors()
        
        // Record start of parsing
        recordOperation("parseProgram", context: "main")
        
        var statements: [Expression] = []
        let startPosition = currentToken?.position ?? Position(line: 1, column: 1)
        
        // Parse statements until we reach EOF
        while !isAtEnd() {
            // Skip any newlines or semicolons at the beginning
            skipStatementSeparators()
            
            // If we've reached EOF after skipping separators, we're done
            if isAtEnd() {
                break
            }
            
            // Parse the next expression/statement
            let statement = try parseExpression()
            statements.append(statement)
            
            // Skip trailing separators
            skipStatementSeparators()
        }
        
        // Validate that we've consumed all tokens
        try validateEndOfInput()
        
        // Record completion of parsing
        recordOperation("parseProgram_complete", context: "main")
        
        return Program(statements: statements, position: startPosition)
    }
    
    /// Skips comment tokens
    /// 
    /// This method advances the parser past any comment tokens, which should
    /// be ignored during parsing.
    private func skipComments() {
        while let token = currentToken, token.type == .comment {
            advance()
        }
    }
    
    /// Skips statement separators (newlines, semicolons) and comments
    /// 
    /// This method advances the parser past any newline, semicolon, or comment tokens
    /// that separate statements in a multi-statement program.
    private func skipStatementSeparators() {
        while let token = currentToken {
            if token.type == .eof {
                break
            }
            
            // Skip comment tokens
            if token.type == .comment {
                advance()
                continue
            }
            
            // If we encounter any actual content token, stop skipping
            switch token.type {
            case .number, .identifier, .leftParen, .operator(_), .assign:
                return
            default:
                // Skip unknown tokens that might be separators
                advance()
            }
        }
    }
    
    /// Parses a statement (for future extensibility)
    /// 
    /// This method is provided for future language extensions that may
    /// include statement-level constructs beyond expressions.
    /// 
    /// - Returns: The parsed statement node
    /// - Throws: ParseError if syntax errors are encountered
    public func parseStatement() throws -> Statement {
        // This will be implemented in later tasks if needed
        fatalError("Parser.parseStatement() not yet implemented")
    }
    
    // MARK: - Error Recovery Mechanisms
    
    /// Synchronization points for error recovery
    /// 
    /// These token types represent stable points in the grammar where
    /// parsing can safely resume after encountering an error. The points
    /// are organized by precedence level to enable more targeted recovery.
    private static let synchronizationPoints: Set<TokenType> = [
        .assign,            // Assignment operators are statement boundaries
        .leftParen,         // Parentheses are structural boundaries
        .rightParen,
        .eof                // End of file is always a synchronization point
    ]
    
    /// Additional synchronization points for specific parsing contexts
    /// 
    /// These are tokens that can serve as synchronization points in
    /// specific parsing contexts, allowing for more granular recovery.
    private static let contextualSynchronizationPoints: Set<TokenType> = [
        .operator(.plus),    // Binary operators can be sync points for operand errors
        .operator(.minus),
        .operator(.multiply),
        .operator(.divide),
        .operator(.modulo),
        .operator(.power)
    ]
    
    /// Determines if the current token is a synchronization point
    /// 
    /// Synchronization points are stable locations in the grammar where
    /// error recovery can safely resume parsing. This includes statement
    /// boundaries, structural boundaries, and expression separators.
    /// 
    /// - Parameter includeContextual: Whether to include contextual sync points
    /// - Returns: true if the current token is a synchronization point
    private func isAtSynchronizationPoint(includeContextual: Bool = false) -> Bool {
        guard let token = currentToken else { return true }
        
        if Self.synchronizationPoints.contains(token.type) {
            return true
        }
        
        if includeContextual && Self.contextualSynchronizationPoints.contains(token.type) {
            return true
        }
        
        return false
    }
    
    /// Implements panic-mode error recovery with enhanced synchronization
    /// 
    /// When a syntax error is encountered, this method skips tokens until
    /// a synchronization point is found. This allows the parser to recover
    /// from errors and continue parsing, potentially finding additional
    /// errors in the same input.
    /// 
    /// The recovery process:
    /// 1. Skip the current erroneous token
    /// 2. Continue skipping tokens until a synchronization point is reached
    /// 3. Position the parser at the synchronization point for resumed parsing
    /// 4. Attempt to validate the recovery point before continuing
    /// 
    /// - Parameter error: The original parse error that triggered recovery
    /// - Throws: The original parse error if recovery is not possible
    private func recoverFromError(_ error: ParseError) throws {
        // If we're already at EOF, we can't recover
        guard currentToken?.type != .eof else {
            throw error
        }
        
        let startPosition = currentIndex
        
        // Skip the current problematic token
        advance()
        
        // Continue skipping until we find a synchronization point
        while let token = currentToken, token.type != .eof {
            if isAtSynchronizationPoint(includeContextual: true) {
                // Found a synchronization point, validate it's a good recovery point
                if validateRecoveryPoint(from: startPosition) {
                    return
                }
                // If not a good recovery point, continue searching
            }
            advance()
        }
        
        // If we reached EOF without finding a synchronization point,
        // we still consider recovery successful as EOF is a valid stopping point
    }
    
    /// Validates that a recovery point is suitable for resuming parsing
    /// 
    /// This method performs additional checks to ensure that the recovery
    /// point is actually a good place to resume parsing, not just a token
    /// that happens to be in the synchronization set.
    /// 
    /// - Parameter startPosition: The position where error recovery began
    /// - Returns: true if the recovery point is valid
    private func validateRecoveryPoint(from startPosition: Int) -> Bool {
        guard let token = currentToken else { return true }
        
        // Always accept EOF as a valid recovery point
        if token.type == .eof {
            return true
        }
        
        // Don't recover if we haven't made any progress
        if currentIndex <= startPosition + 1 {
            return false
        }
        
        // Validate specific recovery points based on token type
        switch token.type {
        case .assign:
            // Assignment is a good recovery point if we're not in the middle of an expression
            return true
            
        case .leftParen:
            // Left parenthesis is good for starting a new sub-expression
            return true
            
        case .rightParen:
            // Right parenthesis is good if it might close an outer expression
            return true
            
        case .operator(_):
            // Binary operators are good recovery points if they can start a new operand
            return canStartNewOperand()
            
        default:
            return true
        }
    }
    
    /// Checks if the current position can start a new operand
    /// 
    /// This helper method determines if the current parsing context
    /// allows for starting a new operand, which is useful for validating
    /// recovery points at binary operators.
    /// 
    /// - Returns: true if a new operand can be started at the current position
    private func canStartNewOperand() -> Bool {
        // Look ahead to see if there's a valid operand following
        if let nextToken = peek() {
            switch nextToken.type {
            case .number, .identifier, .leftParen:
                return true
            case .operator(.minus):
                // Unary minus can start an operand
                return true
            default:
                return false
            }
        }
        return false
    }
    
    /// Attempts to recover from a specific type of parsing error
    /// 
    /// This method provides targeted recovery strategies based on the
    /// type of error encountered, allowing for more intelligent recovery
    /// than generic panic-mode recovery.
    /// 
    /// - Parameter error: The specific parse error to recover from
    /// - Returns: true if recovery was successful, false if generic recovery should be used
    private func attemptTargetedRecovery(from error: ParseError) -> Bool {
        switch error {
        case .unexpectedToken(let token, let expected):
            return attemptUnexpectedTokenRecovery(token: token, expected: expected)
            
        case .unmatchedParenthesis(let position):
            return attemptParenthesisRecovery(at: position)
            
        case .invalidAssignmentTarget(_):
            return attemptAssignmentRecovery()
            
        default:
            return false // Use generic recovery
        }
    }
    
    /// Attempts recovery from unexpected token errors
    /// 
    /// This method tries to recover from unexpected token errors by
    /// analyzing the expected tokens and current context.
    /// 
    /// - Parameters:
    ///   - token: The unexpected token
    ///   - expected: The tokens that were expected
    /// - Returns: true if recovery was successful
    private func attemptUnexpectedTokenRecovery(token: Token, expected: [TokenType]) -> Bool {
        // If we expected a closing parenthesis, skip to the next one
        if expected.contains(.rightParen) {
            return skipToToken(.rightParen)
        }
        
        // If we expected an operand, skip to the next potential operand
        if expected.contains(.number) || expected.contains(.identifier) {
            return skipToOperand()
        }
        
        // If we expected an operator, skip to the next operator
        if expected.contains(where: { if case .operator(_) = $0 { return true } else { return false } }) {
            return skipToOperator()
        }
        
        return false // Use generic recovery
    }
    
    /// Attempts recovery from unmatched parenthesis errors
    /// 
    /// This method tries to recover from parenthesis matching errors
    /// by finding the next balanced point in the expression.
    /// 
    /// - Parameter position: The position where the unmatched parenthesis was found
    /// - Returns: true if recovery was successful
    private func attemptParenthesisRecovery(at position: Position) -> Bool {
        // Try to find a matching closing parenthesis
        var parenCount = 1 // We're missing one closing paren
        
        while let token = currentToken, token.type != .eof {
            switch token.type {
            case .leftParen:
                parenCount += 1
            case .rightParen:
                parenCount -= 1
                if parenCount == 0 {
                    // Found the matching closing parenthesis
                    advance() // consume it
                    return true
                }
            default:
                break
            }
            advance()
        }
        
        return false // Couldn't find matching parenthesis
    }
    
    /// Attempts recovery from assignment target errors
    /// 
    /// This method tries to recover from invalid assignment target errors
    /// by skipping to the next assignment or statement boundary.
    /// 
    /// - Returns: true if recovery was successful
    private func attemptAssignmentRecovery() -> Bool {
        // Skip to the next assignment or statement boundary
        while let token = currentToken, token.type != .eof {
            if token.type == .assign || isAtSynchronizationPoint() {
                return true
            }
            advance()
        }
        return false
    }
    
    /// Skips tokens until a specific token type is found
    /// 
    /// - Parameter tokenType: The token type to search for
    /// - Returns: true if the token was found
    private func skipToToken(_ tokenType: TokenType) -> Bool {
        while let token = currentToken, token.type != .eof {
            if token.type == tokenType {
                return true
            }
            advance()
        }
        return false
    }
    
    /// Skips tokens until a potential operand is found
    /// 
    /// - Returns: true if an operand was found
    private func skipToOperand() -> Bool {
        while let token = currentToken, token.type != .eof {
            switch token.type {
            case .number, .identifier, .leftParen:
                return true
            case .operator(.minus):
                // Unary minus can start an operand
                return true
            default:
                break
            }
            advance()
        }
        return false
    }
    
    /// Skips tokens until a binary operator is found
    /// 
    /// - Returns: true if an operator was found
    private func skipToOperator() -> Bool {
        while let token = currentToken, token.type != .eof {
            if case .operator(_) = token.type {
                return true
            }
            if token.type == .assign {
                return true
            }
            advance()
        }
        return false
    }
    
    /// Advances to the next token
    /// 
    /// This method moves the parser to the next token in the sequence.
    /// It's used both for normal parsing progression and error recovery.
    /// The method also checks for error tokens and throws appropriate errors.
    /// 
    /// - Returns: The previous current token, or nil if already at the end
    /// - Throws: ParseError.tokenizerError if the next token is an error token
    @discardableResult
    private func advance() -> Token? {
        let previous = currentToken
        if currentIndex < tokens.count {
            currentIndex += 1
            parserState.currentIndex = currentIndex
            parserState.tokensConsumed += 1
            
            // Record the advance operation if in debug mode
            if debugMode {
                let tokenType = currentToken?.type.description ?? "EOF"
                recordOperation("advance", context: "token: \(tokenType)")
            }
        }
        return previous
    }
    
    /// Peeks at the next token without advancing the parser
    /// 
    /// This method allows looking ahead in the token stream without
    /// consuming the current token. Useful for making parsing decisions
    /// based on upcoming tokens.
    /// 
    /// - Parameter offset: How many tokens ahead to peek (default: 1)
    /// - Returns: The token at the specified offset, or nil if beyond the end
    private func peek(offset: Int = 1) -> Token? {
        let peekIndex = currentIndex + offset
        return peekIndex < tokens.count ? tokens[peekIndex] : nil
    }
    
    /// Checks if we're at the end of the token stream
    /// 
    /// This method determines if the parser has reached the end of input.
    /// It's useful for loop conditions and error checking.
    /// 
    /// - Returns: true if at EOF or beyond the end of tokens
    private func isAtEnd() -> Bool {
        return currentToken?.type == .eof || currentIndex >= tokens.count
    }
    
    /// Gets the current token, throwing an error if at end of input
    /// 
    /// This method provides safe access to the current token with
    /// automatic error handling for unexpected end of input and error tokens.
    /// 
    /// - Returns: The current token
    /// - Throws: ParseError.unexpectedEndOfInput if no current token
    /// - Throws: ParseError.tokenizerError if current token is an error token
    private func getCurrentToken() throws -> Token {
        guard let token = currentToken else {
            let position = tokens.last?.position ?? Position(line: 1, column: 1)
            throw ParseError.unexpectedEndOfInput(position)
        }
        
        // Check if this is an error token from the tokenizer
        if token.type == .error {
            let tokenizerError = inferTokenizerError(from: token)
            throw ParseError.tokenizerError(tokenizerError, token.position)
        }
        
        return token
    }
    
    /// Checks if the current token matches the expected type
    /// 
    /// This is a utility method for token type checking that's commonly
    /// used throughout the parsing process.
    /// 
    /// - Parameter type: The expected token type
    /// - Returns: true if the current token matches the expected type
    private func check(_ type: TokenType) -> Bool {
        guard let token = currentToken else { return false }
        return token.type == type
    }
    
    /// Consumes a token of the expected type or throws an error
    /// 
    /// This method is used when the parser expects a specific token type.
    /// If the current token doesn't match, it throws an appropriate error
    /// and attempts error recovery.
    /// 
    /// - Parameter expectedType: The token type that is expected
    /// - Returns: The consumed token
    /// - Throws: ParseError.unexpectedToken if the token doesn't match
    private func consume(_ expectedType: TokenType) throws -> Token {
        return try consumeAny([expectedType])
    }
    
    /// Consumes a token matching any of the expected types
    /// 
    /// This method is used when the parser can accept one of several
    /// token types at a given position.
    /// 
    /// - Parameter expectedTypes: Array of acceptable token types
    /// - Returns: The consumed token
    /// - Throws: ParseError.unexpectedToken if the token doesn't match any expected type
    private func consumeAny(_ expectedTypes: [TokenType]) throws -> Token {
        guard let token = currentToken else {
            let error = createUnexpectedEndOfInputError(expected: expectedTypes)
            
            if errorRecoveryMode {
                collectedErrors.append(error)
                // In recovery mode, we can't continue without a token
                throw error
            } else {
                throw error
            }
        }
        
        guard expectedTypes.contains(token.type) else {
            let error = ParseError.unexpectedToken(token, expected: expectedTypes)
            
            if errorRecoveryMode {
                // Collect the error and attempt recovery
                collectedErrors.append(error)
                
                // Attempt targeted recovery first, then fall back to generic recovery
                if !attemptTargetedRecovery(from: error) {
                    do {
                        try recoverFromError(error)
                    } catch {
                        // If recovery fails, we still collected the error
                        throw error
                    }
                }
                
                // After recovery, try to return a reasonable token or throw if we can't continue
                if let recoveredToken = currentToken, expectedTypes.contains(recoveredToken.type) {
                    advance()
                    return recoveredToken
                } else {
                    // Can't recover to a valid state, throw the original error
                    throw error
                }
            } else {
                // Normal mode: attempt recovery and re-throw
                if !attemptTargetedRecovery(from: error) {
                    try recoverFromError(error)
                }
                throw error
            }
        }
        
        advance()
        return token
    }
    
    /// Creates a detailed unexpected end of input error with context
    /// 
    /// This method creates more informative error messages when the parser
    /// reaches the end of input unexpectedly, including information about
    /// what tokens were expected.
    /// 
    /// - Parameter expected: The token types that were expected
    /// - Returns: A ParseError.unexpectedEndOfInput with enhanced context
    private func createUnexpectedEndOfInputError(expected: [TokenType] = []) -> ParseError {
        let position = tokens.last?.position ?? Position(line: 1, column: 1)
        
        // If we have specific expected tokens, create a more detailed error
        if !expected.isEmpty {
            // Create a synthetic EOF token for the error
            let eofToken = Token(type: .eof, value: "", position: position)
            return ParseError.unexpectedToken(eofToken, expected: expected)
        }
        
        return ParseError.unexpectedEndOfInput(position)
    }
    
    // MARK: - Operator Precedence System
    
    /// Represents the associativity of an operator
    /// 
    /// Associativity determines how operators of the same precedence level
    /// are grouped when they appear consecutively in an expression.
    private enum Associativity {
        /// Left-associative: a + b + c is parsed as (a + b) + c
        case left
        /// Right-associative: a = b = c is parsed as a = (b = c)
        case right
    }
    
    /// Contains precedence and associativity information for an operator
    /// 
    /// This structure encapsulates the parsing rules for each operator type,
    /// enabling the precedence climbing algorithm to correctly handle
    /// operator precedence and associativity.
    private struct OperatorInfo {
        /// The precedence level (higher numbers = higher precedence)
        let precedence: Int
        /// The associativity rule for this operator
        let associativity: Associativity
        
        init(precedence: Int, associativity: Associativity) {
            self.precedence = precedence
            self.associativity = associativity
        }
    }
    
    /// Represents the current state of the parser for debugging and error recovery
    /// 
    /// This structure tracks the parser's current position, parsing context,
    /// and other state information that's useful for debugging and implementing
    /// sophisticated error recovery strategies.
    private struct ParserState {
        /// Current position in the token array
        var currentIndex: Int
        /// The parsing context stack (tracks what we're currently parsing)
        var contextStack: [ParsingContext]
        /// Number of errors encountered so far
        var errorCount: Int
        /// Timestamp when parsing started (for performance debugging)
        var startTime: Date
        /// Number of tokens consumed so far
        var tokensConsumed: Int
        /// Maximum recursion depth reached during parsing
        var maxRecursionDepth: Int
        /// Current recursion depth
        var currentRecursionDepth: Int
        /// History of recent parsing operations (for debugging)
        var operationHistory: [ParsingOperation]
        
        init(tokenCount: Int) {
            self.currentIndex = 0
            self.contextStack = []
            self.errorCount = 0
            self.startTime = Date()
            self.tokensConsumed = 0
            self.maxRecursionDepth = 0
            self.currentRecursionDepth = 0
            self.operationHistory = []
        }
        
        /// Records a parsing operation for debugging purposes
        mutating func recordOperation(_ operation: ParsingOperation) {
            operationHistory.append(operation)
            // Keep only the last 50 operations to prevent memory bloat
            if operationHistory.count > 50 {
                operationHistory.removeFirst()
            }
        }
        
        /// Updates recursion depth tracking
        mutating func enterRecursion() {
            currentRecursionDepth += 1
            maxRecursionDepth = max(maxRecursionDepth, currentRecursionDepth)
        }
        
        /// Updates recursion depth tracking
        mutating func exitRecursion() {
            currentRecursionDepth = max(0, currentRecursionDepth - 1)
        }
    }
    
    /// Represents different parsing contexts for state tracking
    /// 
    /// This enum helps track what type of construct the parser is currently
    /// processing, which is useful for error recovery and debugging.
    private enum ParsingContext {
        case expression(precedence: Int)
        case binaryOperation(operator: String)
        case unaryOperation(operator: String)
        case functionCall(name: String)
        case assignment(target: String)
        case parenthesizedExpression
        case primaryExpression
        
        var description: String {
            switch self {
            case .expression(let precedence):
                return "expression(precedence: \(precedence))"
            case .binaryOperation(let op):
                return "binaryOperation(\(op))"
            case .unaryOperation(let op):
                return "unaryOperation(\(op))"
            case .functionCall(let name):
                return "functionCall(\(name))"
            case .assignment(let target):
                return "assignment(\(target))"
            case .parenthesizedExpression:
                return "parenthesizedExpression"
            case .primaryExpression:
                return "primaryExpression"
            }
        }
    }
    
    /// Represents a parsing operation for debugging and state tracking
    /// 
    /// This structure records information about parsing operations to help
    /// with debugging and understanding the parser's behavior.
    private struct ParsingOperation {
        let timestamp: Date
        let operation: String
        let tokenIndex: Int
        let tokenType: String
        let context: String
        
        init(operation: String, tokenIndex: Int, tokenType: String, context: String) {
            self.timestamp = Date()
            self.operation = operation
            self.tokenIndex = tokenIndex
            self.tokenType = tokenType
            self.context = context
        }
    }
    
    /// Operator precedence and associativity lookup table
    /// 
    /// This table defines the precedence hierarchy and associativity rules
    /// for all supported operators. The precedence levels are:
    /// 
    /// Level 4: Exponentiation (^) - right-associative
    /// Level 3: Multiplicative (*, /, %) - left-associative  
    /// Level 2: Additive (+, -) - left-associative
    /// Level 1: Assignment (=) - right-associative
    /// 
    /// Higher precedence numbers indicate higher precedence.
    private static let operatorTable: [OperatorType: OperatorInfo] = [
        .power:    OperatorInfo(precedence: 4, associativity: .right),
        .multiply: OperatorInfo(precedence: 3, associativity: .left),
        .divide:   OperatorInfo(precedence: 3, associativity: .left),
        .modulo:   OperatorInfo(precedence: 3, associativity: .left),
        .plus:     OperatorInfo(precedence: 2, associativity: .left),
        .minus:    OperatorInfo(precedence: 2, associativity: .left)
    ]
    
    /// Assignment operator precedence (lowest precedence)
    /// 
    /// Assignment has the lowest precedence and is right-associative,
    /// meaning a = b = c is parsed as a = (b = c).
    private static let assignmentPrecedence = 1
    
    /// Gets the precedence level for a binary operator token
    /// 
    /// This method extracts the precedence level for binary operators,
    /// including both mathematical operators and assignment.
    /// 
    /// - Parameter token: The token to get precedence for
    /// - Returns: The precedence level, or nil if the token is not a binary operator
    private func getPrecedence(for token: Token) -> Int? {
        switch token.type {
        case .operator(let op):
            return Self.operatorTable[op]?.precedence
        case .assign:
            return Self.assignmentPrecedence
        default:
            return nil
        }
    }
    
    /// Gets the associativity for a binary operator token
    /// 
    /// This method determines whether an operator is left-associative
    /// or right-associative, which affects how consecutive operators
    /// of the same precedence are grouped.
    /// 
    /// - Parameter token: The token to get associativity for
    /// - Returns: The associativity, or nil if the token is not a binary operator
    private func getAssociativity(for token: Token) -> Associativity? {
        switch token.type {
        case .operator(let op):
            return Self.operatorTable[op]?.associativity
        case .assign:
            return .right  // Assignment is right-associative
        default:
            return nil
        }
    }
    
    /// Checks if a token represents a binary operator
    /// 
    /// Binary operators are operators that take two operands (left and right).
    /// This includes mathematical operators and assignment.
    /// 
    /// - Parameter token: The token to check
    /// - Returns: true if the token is a binary operator
    private func isBinaryOperator(_ token: Token) -> Bool {
        switch token.type {
        case .operator(_), .assign:
            return true
        default:
            return false
        }
    }
    
    /// Compares the precedence of two operator tokens
    /// 
    /// This method is used by the precedence climbing algorithm to determine
    /// the order in which operators should be processed.
    /// 
    /// - Parameters:
    ///   - lhs: The left-hand side operator token
    ///   - rhs: The right-hand side operator token
    /// - Returns: true if lhs has higher or equal precedence to rhs
    private func hasHigherOrEqualPrecedence(_ lhs: Token, than rhs: Token) -> Bool {
        guard let lhsPrecedence = getPrecedence(for: lhs),
              let rhsPrecedence = getPrecedence(for: rhs) else {
            return false
        }
        return lhsPrecedence >= rhsPrecedence
    }
    
    /// Determines if an operator is left-associative
    /// 
    /// Left-associative operators group from left to right when they
    /// have the same precedence level. For example: a - b - c = (a - b) - c
    /// 
    /// - Parameter token: The operator token to check
    /// - Returns: true if the operator is left-associative
    private func isLeftAssociative(_ token: Token) -> Bool {
        return getAssociativity(for: token) == .left
    }
    
    /// Determines if an operator is right-associative
    /// 
    /// Right-associative operators group from right to left when they
    /// have the same precedence level. For example: a = b = c = a = (b = c)
    /// 
    /// - Parameter token: The operator token to check
    /// - Returns: true if the operator is right-associative
    private func isRightAssociative(_ token: Token) -> Bool {
        return getAssociativity(for: token) == .right
    }
    
    // MARK: - Specific Precedence Level Helpers
    
    /// Checks if a token is an assignment operator
    /// 
    /// Assignment operators have the lowest precedence (level 1) and are
    /// right-associative. This includes the = operator.
    /// 
    /// - Parameter token: The token to check
    /// - Returns: true if the token is an assignment operator
    private func isAssignmentOperator(_ token: Token) -> Bool {
        return token.type == .assign
    }
    
    /// Checks if a token is an additive operator
    /// 
    /// Additive operators have precedence level 2 and are left-associative.
    /// This includes + and - operators.
    /// 
    /// - Parameter token: The token to check
    /// - Returns: true if the token is an additive operator
    private func isAdditiveOperator(_ token: Token) -> Bool {
        switch token.type {
        case .operator(.plus), .operator(.minus):
            return true
        default:
            return false
        }
    }
    
    /// Checks if a token is a multiplicative operator
    /// 
    /// Multiplicative operators have precedence level 3 and are left-associative.
    /// This includes *, /, and % operators.
    /// 
    /// - Parameter token: The token to check
    /// - Returns: true if the token is a multiplicative operator
    private func isMultiplicativeOperator(_ token: Token) -> Bool {
        switch token.type {
        case .operator(.multiply), .operator(.divide), .operator(.modulo):
            return true
        default:
            return false
        }
    }
    
    /// Checks if a token is an exponentiation operator
    /// 
    /// Exponentiation operators have precedence level 4 and are right-associative.
    /// This includes the ^ operator.
    /// 
    /// - Parameter token: The token to check
    /// - Returns: true if the token is an exponentiation operator
    private func isExponentiationOperator(_ token: Token) -> Bool {
        switch token.type {
        case .operator(.power):
            return true
        default:
            return false
        }
    }
    
    // MARK: - Expression Parsing with Precedence Climbing
    
    /// Parses expressions using the precedence climbing algorithm
    /// 
    /// This is the main expression parsing method that handles binary operators
    /// with proper precedence and associativity. It uses the precedence climbing
    /// algorithm to efficiently parse expressions with multiple precedence levels.
    /// 
    /// The algorithm works by:
    /// 1. Parse the left operand (unary expression)
    /// 2. While there are binary operators with sufficient precedence:
    ///    a. Parse the operator
    ///    b. Determine the minimum precedence for the right operand
    ///    c. Recursively parse the right operand
    ///    d. Create a binary operation node
    /// 
    /// Examples:
    /// - `2 + 3 * 4` becomes BinaryOperation(+, Literal("2"), BinaryOperation(*, Literal("3"), Literal("4")))
    /// - `2 ^ 3 ^ 4` becomes BinaryOperation(^, Literal("2"), BinaryOperation(^, Literal("3"), Literal("4")))
    /// - `a = b = 5` becomes Assignment(Identifier("a"), Assignment(Identifier("b"), Literal("5")))
    /// 
    /// - Parameter minPrecedence: The minimum precedence level for operators to be parsed at this level
    /// - Returns: An Expression representing the parsed expression
    /// - Throws: ParseError if the expression cannot be parsed
    private func parseExpression(minPrecedence: Int = 0) throws -> Expression {
        enterContext(.expression(precedence: minPrecedence))
        defer { exitContext() }
        
        // Assignment has the lowest precedence, so handle it first
        return try parseAssignment()
    }
    
    // MARK: - Assignment Expression Parsing
    
    /// Parses assignment expressions with right-associativity
    /// 
    /// Assignment expressions have the lowest precedence and are right-associative,
    /// meaning that `a = b = 5` is parsed as `a = (b = 5)`. This method handles
    /// both simple assignments and chained assignments.
    /// 
    /// Grammar: additive_expression ('=' assignment_expression)?
    /// 
    /// Examples:
    /// - `x = 5` becomes Assignment(Identifier("x"), Literal("5"))
    /// - `a = b = 5` becomes Assignment(Identifier("a"), Assignment(Identifier("b"), Literal("5")))
    /// - `x = y + 2` becomes Assignment(Identifier("x"), BinaryOperation(+, Identifier("y"), Literal("2")))
    /// 
    /// - Returns: An Expression representing the parsed assignment or non-assignment expression
    /// - Throws: ParseError if the expression cannot be parsed or assignment target is invalid
    private func parseAssignment() throws -> Expression {
        // Parse the left side (could be an identifier for assignment or any expression)
        let expr = try parseAdditive()
        
        // Check if this is an assignment
        if let assignToken = currentToken, assignToken.type == .assign {
            // Validate that the left side is a valid assignment target
            try validateAssignmentTarget(expr, at: assignToken)
            
            let target = expr as! Identifier
            enterContext(.assignment(target: target.name))
            defer { exitContext() }
            
            let assignPosition = assignToken.position
            advance() // consume '='
            
            // Parse the right side recursively to handle chained assignments
            // Since assignment is right-associative, we parse another assignment expression
            let value = try parseAssignment()
            
            return Assignment(target: target, value: value, position: assignPosition)
        }
        
        return expr
    }
    
    /// Validates that an expression can be used as an assignment target
    /// 
    /// Only identifiers can be assignment targets. This method checks the expression
    /// type and throws an appropriate error if the target is invalid.
    /// 
    /// - Parameters:
    ///   - expr: The expression to validate as an assignment target
    ///   - assignToken: The assignment token for error reporting
    /// - Throws: ParseError.invalidAssignmentTarget if the target is not an identifier
    internal func validateAssignmentTarget(_ expr: Expression, at assignToken: Token) throws {
        guard expr is Identifier else {
            throw ParseError.invalidAssignmentTarget(assignToken)
        }
    }
    
    // MARK: - Additive Expression Parsing
    
    /// Parses additive expressions (+ and -)
    /// 
    /// This method handles addition and subtraction operators with left-associativity.
    /// It uses the precedence climbing algorithm for operators at this precedence level.
    /// 
    /// - Returns: An Expression representing the parsed additive expression
    /// - Throws: ParseError if the expression cannot be parsed
    private func parseAdditive() throws -> Expression {
        return try parseMultiplicative(minPrecedence: Self.assignmentPrecedence + 1)
    }
    
    /// Parses expressions with precedence climbing starting from a minimum precedence
    /// 
    /// This is a helper method that implements the precedence climbing algorithm
    /// for binary operators above the assignment level.
    /// 
    /// - Parameter minPrecedence: The minimum precedence level for operators to be parsed
    /// - Returns: An Expression representing the parsed expression
    /// - Throws: ParseError if the expression cannot be parsed
    private func parseMultiplicative(minPrecedence: Int) throws -> Expression {
        // Parse the left operand (starts with unary expressions)
        var left = try parseUnary()
        
        // Continue parsing binary operators while they have sufficient precedence
        while let operatorToken = currentToken,
              isBinaryOperator(operatorToken),
              operatorToken.type != .assign, // Assignment is handled separately
              let precedence = getPrecedence(for: operatorToken),
              precedence >= minPrecedence {
            
            // Store the operator information
            let op = operatorToken
            let opPrecedence = precedence
            let opAssociativity = getAssociativity(for: operatorToken) ?? .left
            
            advance() // consume the operator
            
            // Calculate the minimum precedence for the right operand
            // For left-associative operators, we need higher precedence on the right
            // For right-associative operators, we allow equal precedence on the right
            let nextMinPrecedence = opPrecedence + (opAssociativity == .left ? 1 : 0)
            
            // Recursively parse the right operand
            let right = try parseMultiplicative(minPrecedence: nextMinPrecedence)
            
            // Create the binary operation node
            if case .operator(let operatorType) = op.type {
                left = BinaryOperation(
                    operator: operatorType,
                    left: left,
                    right: right,
                    position: op.position
                )
            } else {
                // This should not happen since we filtered out assignment
                throw ParseError.unexpectedToken(op, expected: [])
            }
        }
        
        return left
    }
    
    // MARK: - Unary Expression Parsing
    
    /// Parses unary expressions including unary minus
    /// 
    /// This method handles unary operators that take a single operand.
    /// Currently supports unary minus (-) for negation. It correctly handles
    /// nested unary operators like --5 and ensures proper precedence with
    /// binary operators.
    /// 
    /// Grammar: unary_operator unary_expression | primary_expression
    /// 
    /// Examples:
    /// - `-5` becomes UnaryOperation(minus, Literal("5"))
    /// - `--5` becomes UnaryOperation(minus, UnaryOperation(minus, Literal("5")))
    /// - `-(2 + 3)` becomes UnaryOperation(minus, ParenthesizedExpression(...))
    /// 
    /// - Returns: An Expression representing the parsed unary expression or primary expression
    /// - Throws: ParseError if the expression cannot be parsed
    private func parseUnary() throws -> Expression {
        guard let token = currentToken else {
            throw createUnexpectedEndOfInputError(expected: [.number, .identifier, .leftParen, .operator(.minus)])
        }
        
        // Check if this is a unary minus operator
        if case .operator(.minus) = token.type {
            let operatorPosition = token.position
            advance() // consume the unary minus
            
            // Recursively parse the operand (which could be another unary expression)
            let operand = try parseUnary()
            
            return UnaryOperation(
                operator: .minus,
                operand: operand,
                position: operatorPosition
            )
        }
        
        // Not a unary operator, parse as primary expression
        return try parsePrimary()
    }
    
    // MARK: - Primary Expression Parsing
    
    /// Parses primary expressions (literals, identifiers, parentheses, function calls)
    /// 
    /// Primary expressions are the basic building blocks of expressions that cannot
    /// be broken down further by operator precedence. This includes:
    /// - Numeric literals (42, 3.14)
    /// - Identifiers (x, myVar)
    /// - Parenthesized expressions ((2 + 3))
    /// - Function calls (sin(x), max(a, b))
    /// 
    /// - Returns: An Expression representing the parsed primary expression
    /// - Throws: ParseError if no valid primary expression is found
    private func parsePrimary() throws -> Expression {
        // Skip any comments before parsing
        skipComments()
        
        guard let token = currentToken else {
            throw createUnexpectedEndOfInputError(expected: [.number, .identifier, .leftParen])
        }
        
        switch token.type {
        case .number:
            return try parseLiteral()
        case .identifier:
            // Check if this is a function call or just an identifier
            if peek()?.type == .leftParen {
                return try parseFunctionCall()
            } else {
                return try parseIdentifier()
            }
        case .leftParen:
            return try parseParenthesizedExpression()
        default:
            throw ParseError.unexpectedToken(token, expected: [.number, .identifier, .leftParen])
        }
    }
    
    /// Parses a literal number token into a Literal AST node
    /// 
    /// This method handles numeric literals, preserving the original token value
    /// to maintain precision and format. The position information is preserved
    /// for error reporting and debugging.
    /// 
    /// - Returns: A Literal AST node representing the parsed number
    /// - Throws: ParseError.unexpectedToken if the current token is not a number
    /// - Throws: ParseError.unexpectedEndOfInput if at end of input
    private func parseLiteral() throws -> Literal {
        let token = try getCurrentToken()
        
        guard token.type == .number else {
            throw ParseError.unexpectedToken(token, expected: [.number])
        }
        
        advance()
        return Literal(value: token.value, position: token.position)
    }
    
    /// Parses an identifier token into an Identifier AST node
    /// 
    /// This method handles identifier tokens, preserving the name and position
    /// information. Identifiers can represent variable names or function names.
    /// 
    /// - Returns: An Identifier AST node representing the parsed identifier
    /// - Throws: ParseError.unexpectedToken if the current token is not an identifier
    /// - Throws: ParseError.unexpectedEndOfInput if at end of input
    private func parseIdentifier() throws -> Identifier {
        let token = try getCurrentToken()
        
        guard token.type == .identifier else {
            throw ParseError.unexpectedToken(token, expected: [.identifier])
        }
        
        advance()
        return Identifier(name: token.value, position: token.position)
    }
    
    /// Parses a parenthesized expression
    /// 
    /// This method handles expressions wrapped in parentheses, which can be used
    /// to override operator precedence or make expression structure explicit.
    /// It supports nested parentheses and properly handles unmatched parentheses.
    /// 
    /// Grammar: '(' expression ')'
    /// 
    /// - Returns: A ParenthesizedExpression AST node containing the inner expression
    /// - Throws: ParseError.unexpectedToken if the current token is not a left parenthesis
    /// - Throws: ParseError.unmatchedParenthesis if the closing parenthesis is missing
    /// - Throws: ParseError.unexpectedEndOfInput if at end of input
    private func parseParenthesizedExpression() throws -> ParenthesizedExpression {
        let openParenToken = try consume(.leftParen)
        let position = openParenToken.position
        
        // Parse the inner expression, which could include binary operators
        let innerExpression: Expression
        do {
            innerExpression = try parseExpression()
        } catch {
            // If we can't parse the inner expression, it's still an unmatched parenthesis error
            // because the opening parenthesis won't have a proper closing
            if error is ParseError {
                throw error // Re-throw the original parsing error
            } else {
                throw ParseError.unmatchedParenthesis(position)
            }
        }
        
        // Consume the closing parenthesis with better error reporting
        do {
            _ = try consume(.rightParen)
        } catch ParseError.unexpectedToken(_, _) {
            // Convert unexpected token errors to unmatched parenthesis for better context
            throw ParseError.unmatchedParenthesis(position)
        } catch ParseError.unexpectedEndOfInput(_) {
            // Convert end of input to unmatched parenthesis
            throw ParseError.unmatchedParenthesis(position)
        }
        
        return ParenthesizedExpression(expression: innerExpression, position: position)
    }
    
    /// Parses a function call expression
    /// 
    /// This method handles function calls with zero or more arguments.
    /// For now, this implementation supports single-argument function calls
    /// since comma tokens are not yet supported by the tokenizer.
    /// 
    /// Grammar: identifier '(' expression? ')'
    /// 
    /// - Returns: A FunctionCall AST node containing the function name and arguments
    /// - Throws: ParseError.unexpectedToken if the current token is not an identifier
    /// - Throws: ParseError.unmatchedParenthesis if parentheses are not properly matched
    /// - Throws: ParseError.unexpectedEndOfInput if at end of input
    private func parseFunctionCall() throws -> FunctionCall {
        let nameToken = try consume(.identifier)
        let functionName = nameToken.value
        let position = nameToken.position
        
        enterContext(.functionCall(name: functionName))
        defer { exitContext() }
        
        // Expect opening parenthesis
        let openParenToken = try consume(.leftParen)
        
        var arguments: [Expression] = []
        
        // Check if we have an argument or empty parameter list
        if let token = currentToken, token.type != .rightParen {
            do {
                // Parse single argument (comma-separated arguments not yet supported)
                let argument = try parseArgument()
                arguments.append(argument)
            } catch {
                // If we can't parse the argument, it's likely an unmatched parenthesis
                if error is ParseError {
                    throw error // Re-throw the original parsing error
                } else {
                    throw ParseError.unmatchedParenthesis(openParenToken.position)
                }
            }
        }
        
        // Consume closing parenthesis with better error reporting
        do {
            _ = try consume(.rightParen)
        } catch ParseError.unexpectedToken(_, _) {
            // Convert unexpected token errors to unmatched parenthesis for better context
            throw ParseError.unmatchedParenthesis(openParenToken.position)
        } catch ParseError.unexpectedEndOfInput(_) {
            // Convert end of input to unmatched parenthesis
            throw ParseError.unmatchedParenthesis(openParenToken.position)
        }
        
        return FunctionCall(name: functionName, arguments: arguments, position: position)
    }
    
    /// Parses a single function argument expression
    /// 
    /// This helper method parses individual arguments within function calls.
    /// Arguments can be any valid expression including binary operators.
    /// 
    /// - Returns: An Expression representing the parsed argument
    /// - Throws: ParseError if the argument cannot be parsed
    private func parseArgument() throws -> Expression {
        // Arguments can include any expression, so use parseExpression
        return try parseExpression()
    }
    
    // MARK: - Token Validation and Error Handling
    
    /// Validates that the token array doesn't contain error tokens from the tokenizer
    /// 
    /// This method scans through all tokens to detect any error tokens that were
    /// produced by the tokenizer due to lexical errors. If error tokens are found,
    /// they are converted to parser errors with appropriate position information.
    /// The method attempts to infer the type of tokenizer error based on the token value.
    /// 
    /// - Throws: ParseError.tokenizerError if any error tokens are found
    private func validateTokensForErrors() throws {
        for token in tokens {
            if token.type == .error {
                // Convert tokenizer error to parser error
                // Infer the type of tokenizer error based on the token value
                let tokenizerError = inferTokenizerError(from: token)
                throw ParseError.tokenizerError(tokenizerError, token.position)
            }
        }
    }
    
    /// Infers the type of tokenizer error based on an error token
    /// 
    /// This method analyzes the value of an error token to determine what type
    /// of tokenizer error likely occurred. This provides more specific error
    /// messages to users.
    /// 
    /// - Parameter token: The error token to analyze
    /// - Returns: The inferred TokenizerError
    private func inferTokenizerError(from token: Token) -> TokenizerError {
        let value = token.value
        
        // Check if it looks like a malformed number (contains digits and multiple dots)
        if value.contains(".") && value.filter({ $0 == "." }).count > 1 {
            return TokenizerError.malformedNumber(value, token.position)
        }
        
        // Check if it contains digits but has invalid characters mixed in
        if value.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil &&
           value.rangeOfCharacter(from: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))) != value.startIndex..<value.endIndex {
            return TokenizerError.malformedNumber(value, token.position)
        }
        
        // Default to invalid character error using the first character
        let invalidChar = value.first ?? Character(" ")
        return TokenizerError.invalidCharacter(invalidChar, token.position)
    }
    
    /// Validates that parsing has reached the end of input correctly
    /// 
    /// This method ensures that after parsing the main expression, the parser
    /// is positioned at the EOF token. This validates that all tokens have been
    /// consumed and no unexpected tokens remain.
    /// 
    /// - Throws: ParseError.unexpectedToken if there are remaining non-EOF tokens
    /// - Throws: ParseError.unexpectedEndOfInput if EOF token is missing
    private func validateEndOfInput() throws {
        guard let token = currentToken else {
            // No current token means we've gone past the end of the array
            // This is acceptable if the last token was EOF
            if let lastToken = tokens.last, lastToken.type == .eof {
                return
            } else {
                // Missing EOF token
                let position = tokens.last?.position ?? Position(line: 1, column: 1)
                throw ParseError.unexpectedEndOfInput(position)
            }
        }
        
        // We should be at EOF token
        guard token.type == .eof else {
            throw ParseError.unexpectedToken(token, expected: [.eof])
        }
        
        // Consume the EOF token to complete parsing
        advance()
    }
    
    // MARK: - Parser State Management and Debugging
    
    /// Resets the parser state to the beginning
    /// 
    /// This method initializes all state tracking variables and prepares
    /// the parser for a new parsing session.
    private func resetParserState() {
        currentIndex = 0
        parserState = ParserState(tokenCount: tokens.count)
        collectedErrors = []
    }
    
    /// Records a parsing operation for debugging purposes
    /// 
    /// This method tracks parsing operations when debug mode is enabled,
    /// providing detailed information about the parser's behavior.
    /// 
    /// - Parameters:
    ///   - operation: Description of the operation being performed
    ///   - context: Additional context information
    private func recordOperation(_ operation: String, context: String = "") {
        guard debugMode else { return }
        
        let tokenType = currentToken?.type.description ?? "EOF"
        let fullContext = parserState.contextStack.isEmpty ? context : 
            "\(context) in \(parserState.contextStack.last?.description ?? "unknown")"
        
        let op = ParsingOperation(
            operation: operation,
            tokenIndex: currentIndex,
            tokenType: tokenType,
            context: fullContext
        )
        
        parserState.recordOperation(op)
    }
    
    /// Enters a new parsing context
    /// 
    /// This method tracks the parsing context stack for debugging and
    /// error recovery purposes.
    /// 
    /// - Parameter context: The parsing context being entered
    private func enterContext(_ context: ParsingContext) {
        parserState.contextStack.append(context)
        parserState.enterRecursion()
        
        if debugMode {
            recordOperation("enter_context", context: context.description)
        }
    }
    
    /// Exits the current parsing context
    /// 
    /// This method removes the current context from the stack and updates
    /// recursion depth tracking.
    private func exitContext() {
        if !parserState.contextStack.isEmpty {
            let context = parserState.contextStack.removeLast()
            parserState.exitRecursion()
            
            if debugMode {
                recordOperation("exit_context", context: context.description)
            }
        }
    }
    
    /// Gets the current parsing context
    /// 
    /// - Returns: The current parsing context, or nil if no context is active
    private func getCurrentContext() -> ParsingContext? {
        return parserState.contextStack.last
    }
    
    // MARK: - Public Debugging Interface
    
    /// Gets a snapshot of the current parser state
    /// 
    /// This method provides access to the parser's internal state for
    /// debugging and analysis purposes. It returns a read-only view
    /// of the current state.
    /// 
    /// - Returns: A dictionary containing parser state information
    public func getParserState() -> [String: Any] {
        return [
            "currentIndex": currentIndex,
            "tokensConsumed": parserState.tokensConsumed,
            "errorCount": parserState.errorCount,
            "maxRecursionDepth": parserState.maxRecursionDepth,
            "currentRecursionDepth": parserState.currentRecursionDepth,
            "contextStack": parserState.contextStack.map { $0.description },
            "currentToken": currentToken?.description ?? "EOF",
            "remainingTokens": tokens.count - currentIndex,
            "parsingDuration": Date().timeIntervalSince(parserState.startTime)
        ]
    }
    
    /// Gets the parsing operation history
    /// 
    /// This method returns the history of recent parsing operations
    /// for debugging purposes. Only available when debug mode is enabled.
    /// 
    /// - Returns: An array of parsing operation descriptions
    public func getOperationHistory() -> [String] {
        guard debugMode else {
            return ["Debug mode not enabled"]
        }
        
        return parserState.operationHistory.map { op in
            let timestamp = String(format: "%.3f", op.timestamp.timeIntervalSince(parserState.startTime))
            return "[\(timestamp)s] \(op.operation) at token \(op.tokenIndex) (\(op.tokenType)) - \(op.context)"
        }
    }
    
    /// Gets detailed parser statistics
    /// 
    /// This method provides comprehensive statistics about the parsing
    /// process, useful for performance analysis and debugging.
    /// 
    /// - Returns: A dictionary containing detailed parser statistics
    public func getParserStatistics() -> [String: Any] {
        let duration = Date().timeIntervalSince(parserState.startTime)
        let tokensPerSecond = duration > 0 ? Double(parserState.tokensConsumed) / duration : 0
        
        return [
            "totalTokens": tokens.count,
            "tokensConsumed": parserState.tokensConsumed,
            "tokensRemaining": tokens.count - currentIndex,
            "errorCount": parserState.errorCount,
            "maxRecursionDepth": parserState.maxRecursionDepth,
            "parsingDuration": duration,
            "tokensPerSecond": tokensPerSecond,
            "operationCount": parserState.operationHistory.count,
            "debugModeEnabled": debugMode,
            "errorRecoveryEnabled": errorRecoveryMode
        ]
    }
    
    /// Prints the current parser state to the console
    /// 
    /// This method provides a convenient way to inspect the parser state
    /// during debugging sessions.
    public func printParserState() {
        print("=== Parser State ===")
        let state = getParserState()
        for (key, value) in state.sorted(by: { $0.key < $1.key }) {
            print("\(key): \(value)")
        }
        print("==================")
    }
    
    /// Prints the parsing operation history to the console
    /// 
    /// This method provides a convenient way to inspect the recent
    /// parsing operations during debugging sessions.
    public func printOperationHistory() {
        print("=== Operation History ===")
        let history = getOperationHistory()
        for operation in history {
            print(operation)
        }
        print("========================")
    }
    
    /// Prints comprehensive parser statistics to the console
    /// 
    /// This method provides a convenient way to inspect detailed
    /// parser statistics during debugging sessions.
    public func printParserStatistics() {
        print("=== Parser Statistics ===")
        let stats = getParserStatistics()
        for (key, value) in stats.sorted(by: { $0.key < $1.key }) {
            print("\(key): \(value)")
        }
        print("========================")
    }
    
    /// Enables or disables debug mode
    /// 
    /// Debug mode can be toggled at runtime to control the level of
    /// state tracking and operation recording.
    /// 
    /// - Parameter enabled: Whether to enable debug mode
    public func setDebugMode(_ enabled: Bool) {
        debugMode = enabled
        if enabled {
            recordOperation("debug_mode_enabled", context: "runtime")
        }
    }
    
    /// Checks if debug mode is currently enabled
    /// 
    /// - Returns: True if debug mode is enabled, false otherwise
    public func isDebugModeEnabled() -> Bool {
        return debugMode
    }
    
    /// Gets a summary of the current parsing position
    /// 
    /// This method provides a human-readable summary of where the parser
    /// is currently positioned in the token stream.
    /// 
    /// - Returns: A string describing the current parsing position
    public func getPositionSummary() -> String {
        guard let token = currentToken else {
            return "At end of input"
        }
        
        let progress = tokens.count > 0 ? (currentIndex * 100) / tokens.count : 0
        let context = getCurrentContext()?.description ?? "no context"
        
        return "Token \(currentIndex + 1)/\(tokens.count) (\(progress)%) - \(token.type.description) at \(token.position) in \(context)"
    }
    
    // MARK: - Debugging and Introspection Methods
    
    /// Generates a detailed debug representation of an AST
    /// 
    /// This method creates a comprehensive debug view of the AST including
    /// node types, positions, and structural information. Useful for
    /// development and debugging purposes.
    /// 
    /// - Parameters:
    ///   - ast: The AST root node to debug
    ///   - includePositions: Whether to include position information
    ///   - includeTypes: Whether to include node type information
    /// - Returns: A detailed debug string representation
    /// - Throws: Any error encountered during AST traversal
    public static func debugAST(_ ast: Expression, 
                               includePositions: Bool = true, 
                               includeTypes: Bool = true) throws -> String {
        let visitor = ASTDebugVisitor(includePositions: includePositions, includeTypes: includeTypes)
        return try ast.accept(visitor)
    }
    
    /// Serializes an AST to a structured dictionary format
    /// 
    /// This method converts the AST into a serializable format that preserves
    /// all structural and positional information. The result can be converted
    /// to JSON or other formats for persistence or transmission.
    /// 
    /// - Parameter ast: The AST root node to serialize
    /// - Returns: A dictionary representation of the AST
    /// - Throws: Any error encountered during AST traversal
    public static func serializeAST(_ ast: Expression) throws -> [String: Any] {
        let visitor = ASTSerializationVisitor()
        return try ast.accept(visitor)
    }
    
    /// Converts an AST to a JSON string representation
    /// 
    /// This method serializes the AST and converts it to a pretty-printed
    /// JSON string that preserves all structural and positional information.
    /// 
    /// - Parameter ast: The AST root node to convert
    /// - Returns: A JSON string representation of the AST
    /// - Throws: Any error encountered during serialization or JSON conversion
    public static func astToJSON(_ ast: Expression) throws -> String {
        let serialized = try serializeAST(ast)
        return try ASTSerializationVisitor.toJSON(serialized)
    }
    
    /// Converts an AST to a compact JSON string representation
    /// 
    /// This method serializes the AST and converts it to a compact JSON
    /// string without pretty-printing, suitable for storage or transmission.
    /// 
    /// - Parameter ast: The AST root node to convert
    /// - Returns: A compact JSON string representation of the AST
    /// - Throws: Any error encountered during serialization or JSON conversion
    public static func astToCompactJSON(_ ast: Expression) throws -> String {
        let serialized = try serializeAST(ast)
        return try ASTSerializationVisitor.toCompactJSON(serialized)
    }
    
    /// Gets comprehensive debugging information about the parser state
    /// 
    /// This method returns detailed information about the current parser state,
    /// including token position, parsing context, and collected errors.
    /// 
    /// - Returns: A dictionary containing parser state information
    public func getDebugInfo() -> [String: Any] {
        var info: [String: Any] = [
            "currentIndex": currentIndex,
            "totalTokens": tokens.count,
            "errorRecoveryMode": errorRecoveryMode,
            "debugMode": debugMode,
            "collectedErrorCount": collectedErrors.count
        ]
        
        if let token = currentToken {
            info["currentToken"] = [
                "type": token.type.description,
                "value": token.value,
                "position": [
                    "line": token.position.line,
                    "column": token.position.column
                ]
            ]
        }
        
        if debugMode {
            info["parserState"] = [
                "operationCount": parserState.operationHistory.count,
                "maxDepthReached": parserState.maxRecursionDepth,
                "lastOperation": parserState.operationHistory.last?.operation ?? "none"
            ]
        }
        
        return info
    }
    
    /// Gets a summary of parsing statistics
    /// 
    /// This method returns statistical information about the parsing process,
    /// useful for performance analysis and debugging.
    /// 
    /// - Returns: A dictionary containing parsing statistics
    public func getParsingStatistics() -> [String: Any] {
        return [
            "tokenCount": tokens.count,
            "currentPosition": currentIndex,
            "tokensRemaining": max(0, tokens.count - currentIndex),
            "progressPercentage": tokens.isEmpty ? 100.0 : Double(currentIndex) / Double(tokens.count) * 100.0,
            "errorCount": collectedErrors.count,
            "operationCount": parserState.operationHistory.count,
            "maxDepthReached": parserState.maxRecursionDepth
        ]
    }
    
    /// Generates a readable summary of the parsing process
    /// 
    /// This method creates a human-readable summary of the parsing process,
    /// including statistics, errors, and current state information.
    /// 
    /// - Returns: A formatted string summary of the parsing process
    public func getParsingSummary() -> String {
        let stats = getParsingStatistics()
        let debugInfo = getDebugInfo()
        
        var summary = "=== Parser Summary ===\n"
        summary += "Tokens: \(stats["tokenCount"] ?? 0) total, \(stats["tokensRemaining"] ?? 0) remaining\n"
        summary += "Progress: \(String(format: "%.1f", stats["progressPercentage"] as? Double ?? 0.0))%\n"
        summary += "Operations: \(stats["operationCount"] ?? 0)\n"
        summary += "Max Depth: \(stats["maxDepthReached"] ?? 0)\n"
        summary += "Errors: \(stats["errorCount"] ?? 0)\n"
        
        if let currentToken = debugInfo["currentToken"] as? [String: Any] {
            summary += "Current Token: \(currentToken["type"] ?? "unknown")"
            if let position = currentToken["position"] as? [String: Any] {
                summary += " at \(position["line"] ?? 0):\(position["column"] ?? 0)"
            }
            summary += "\n"
        }
        
        if !collectedErrors.isEmpty {
            summary += "\nErrors:\n"
            for (index, error) in collectedErrors.enumerated() {
                summary += "  \(index + 1). \(error.localizedDescription)\n"
            }
        }
        
        return summary
    }
}