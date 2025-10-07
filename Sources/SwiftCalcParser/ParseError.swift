import Foundation
import SwiftCalcTokenizer

/// Enumeration of parsing errors that can occur during AST construction
/// 
/// ParseError provides detailed information about syntax errors encountered
/// during parsing, including position information for meaningful error messages.
/// Each error case includes relevant context to help users understand and fix
/// the syntax issues.
/// 
/// Example usage:
/// ```swift
/// do {
///     let ast = try parser.parse()
/// } catch let error as ParseError {
///     switch error {
///     case .unexpectedToken(let token, let expected):
///         print("Unexpected \(token.type) at \(token.position), expected: \(expected)")
///     case .unexpectedEndOfInput(let position):
///         print("Unexpected end of input at \(position)")
///     // ... handle other error cases
///     }
/// }
/// ```
public enum ParseError: Error {
    /// Encountered an unexpected token during parsing
    /// 
    /// This error occurs when the parser encounters a token that doesn't
    /// fit the current parsing context. The error includes the unexpected
    /// token and a list of token types that were expected at that position.
    /// 
    /// - Parameters:
    ///   - token: The unexpected token that was encountered
    ///   - expected: Array of token types that were expected at this position
    case unexpectedToken(Token, expected: [TokenType])
    
    /// Reached the end of input unexpectedly
    /// 
    /// This error occurs when the parser expects more tokens but encounters
    /// the end of the token stream. This typically happens with incomplete
    /// expressions or unmatched parentheses.
    /// 
    /// - Parameter position: The position where the end of input was encountered
    case unexpectedEndOfInput(Position)
    
    /// Attempted to assign to an invalid target
    /// 
    /// This error occurs when the parser encounters an assignment where the
    /// left-hand side is not a valid assignment target. Only identifiers
    /// can be assignment targets.
    /// 
    /// - Parameter token: The token that was used as an invalid assignment target
    case invalidAssignmentTarget(Token)
    
    /// Encountered unmatched parentheses
    /// 
    /// This error occurs when the parser encounters a closing parenthesis
    /// without a corresponding opening parenthesis, or when an opening
    /// parenthesis is not properly closed.
    /// 
    /// - Parameter position: The position where the unmatched parenthesis was found
    case unmatchedParenthesis(Position)
    
    /// Error propagated from the tokenizer
    /// 
    /// This error occurs when the tokenizer produces an error token, indicating
    /// a lexical error in the source text. The parser wraps the tokenizer error
    /// with position information.
    /// 
    /// - Parameters:
    ///   - error: The original tokenizer error
    ///   - position: The position where the tokenizer error occurred
    case tokenizerError(TokenizerError, Position)
}

// MARK: - Error Descriptions

extension ParseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedToken(let token, let expected):
            return formatUnexpectedTokenError(token: token, expected: expected)
            
        case .unexpectedEndOfInput(let position):
            return formatUnexpectedEndOfInputError(at: position)
            
        case .invalidAssignmentTarget(let token):
            return formatInvalidAssignmentTargetError(token: token)
            
        case .unmatchedParenthesis(let position):
            return formatUnmatchedParenthesisError(at: position)
            
        case .tokenizerError(let error, let position):
            return formatTokenizerError(error: error, at: position)
        }
    }
    
    /// Formats detailed error message for unexpected token errors
    /// 
    /// Creates comprehensive error messages that include:
    /// - The unexpected token type and value
    /// - Position information (line and column)
    /// - List of expected token types with user-friendly names
    /// - Context-specific suggestions when possible
    /// 
    /// - Parameters:
    ///   - token: The unexpected token that was encountered
    ///   - expected: Array of token types that were expected
    /// - Returns: A detailed error message string
    private func formatUnexpectedTokenError(token: Token, expected: [TokenType]) -> String {
        let tokenDescription = getTokenDescription(token)
        let positionInfo = "line \(token.position.line), column \(token.position.column)"
        
        if expected.isEmpty {
            return "Unexpected \(tokenDescription) at \(positionInfo)"
        }
        
        let expectedDescriptions = expected.map { getTokenTypeDescription($0) }
        let expectedList: String
        
        if expectedDescriptions.count == 1 {
            expectedList = expectedDescriptions[0]
        } else if expectedDescriptions.count == 2 {
            expectedList = "\(expectedDescriptions[0]) or \(expectedDescriptions[1])"
        } else {
            let allButLast = expectedDescriptions.dropLast().joined(separator: ", ")
            let last = expectedDescriptions.last!
            expectedList = "\(allButLast), or \(last)"
        }
        
        var message = "Unexpected \(tokenDescription) at \(positionInfo). Expected \(expectedList)."
        
        // Add context-specific suggestions
        if let suggestion = getContextualSuggestion(for: token, expected: expected) {
            message += " \(suggestion)"
        }
        
        return message
    }
    
    /// Formats detailed error message for unexpected end of input
    /// 
    /// Creates specific error messages based on context, indicating what
    /// was expected to complete the expression.
    /// 
    /// - Parameter position: The position where end of input was encountered
    /// - Returns: A detailed error message string
    private func formatUnexpectedEndOfInputError(at position: Position) -> String {
        let positionInfo = "line \(position.line), column \(position.column)"
        return "Unexpected end of input at \(positionInfo). The expression appears to be incomplete. Check for missing operands, closing parentheses, or assignment values."
    }
    
    /// Formats detailed error message for invalid assignment targets
    /// 
    /// Provides clear explanation of what can be assigned to and suggests
    /// corrections for common mistakes.
    /// 
    /// - Parameter token: The token that was used as an invalid assignment target
    /// - Returns: A detailed error message string
    private func formatInvalidAssignmentTargetError(token: Token) -> String {
        let tokenDescription = getTokenDescription(token)
        let positionInfo = "line \(token.position.line), column \(token.position.column)"
        
        var message = "Invalid assignment target at \(positionInfo). Cannot assign to \(tokenDescription). Only variable names (identifiers) can be assigned to."
        
        // Add specific suggestions based on the token type
        switch token.type {
        case .number:
            message += " You cannot assign a value to a number literal."
        case .operator(_):
            message += " You cannot assign a value to an operator."
        case .leftParen, .rightParen:
            message += " You cannot assign a value to a parenthesized expression."
        default:
            message += " Make sure the left side of the assignment is a variable name."
        }
        
        return message
    }
    
    /// Formats detailed error message for unmatched parentheses
    /// 
    /// Provides specific guidance on parenthesis matching issues.
    /// 
    /// - Parameter position: The position where the unmatched parenthesis was found
    /// - Returns: A detailed error message string
    private func formatUnmatchedParenthesisError(at position: Position) -> String {
        let positionInfo = "line \(position.line), column \(position.column)"
        return "Unmatched parenthesis at \(positionInfo). Make sure every opening parenthesis '(' has a corresponding closing parenthesis ')' and they are properly nested."
    }
    
    /// Formats detailed error message for tokenizer errors
    /// 
    /// Wraps tokenizer errors with additional context and suggestions.
    /// 
    /// - Parameters:
    ///   - error: The original tokenizer error
    ///   - position: The position where the error occurred
    /// - Returns: A detailed error message string
    private func formatTokenizerError(error: TokenizerError, at position: Position) -> String {
        let positionInfo = "line \(position.line), column \(position.column)"
        return "Lexical error at \(positionInfo): \(error.localizedDescription). This error occurred during tokenization before parsing could begin."
    }
    
    /// Gets a user-friendly description of a token
    /// 
    /// Converts token types and values into readable descriptions for error messages.
    /// 
    /// - Parameter token: The token to describe
    /// - Returns: A user-friendly description of the token
    private func getTokenDescription(_ token: Token) -> String {
        switch token.type {
        case .number:
            return "number '\(token.value)'"
        case .identifier:
            return "identifier '\(token.value)'"
        case .operator(let op):
            return "operator '\(op.description)'"
        case .assign:
            return "assignment operator '='"
        case .leftParen:
            return "opening parenthesis '('"
        case .rightParen:
            return "closing parenthesis ')'"
        case .comment:
            return "comment '\(token.value)'"
        case .eof:
            return "end of input"
        case .error:
            return "invalid token '\(token.value)'"
        }
    }
    
    /// Gets a user-friendly description of a token type
    /// 
    /// Converts token types into readable descriptions for expected token lists.
    /// 
    /// - Parameter tokenType: The token type to describe
    /// - Returns: A user-friendly description of the token type
    private func getTokenTypeDescription(_ tokenType: TokenType) -> String {
        switch tokenType {
        case .number:
            return "a number"
        case .identifier:
            return "an identifier"
        case .operator(let op):
            return "operator '\(op.description)'"
        case .assign:
            return "assignment operator '='"
        case .leftParen:
            return "opening parenthesis '('"
        case .rightParen:
            return "closing parenthesis ')'"
        case .comment:
            return "a comment"
        case .eof:
            return "end of input"
        case .error:
            return "a valid token"
        }
    }
    
    /// Provides contextual suggestions based on the error context
    /// 
    /// Analyzes the unexpected token and expected tokens to provide
    /// helpful suggestions for fixing the syntax error.
    /// 
    /// - Parameters:
    ///   - token: The unexpected token
    ///   - expected: The expected token types
    /// - Returns: A contextual suggestion string, or nil if no specific suggestion applies
    private func getContextualSuggestion(for token: Token, expected: [TokenType]) -> String? {
        // Suggest common fixes based on token patterns
        
        // If we expected a number or identifier but got an operator
        if expected.contains(.number) || expected.contains(.identifier) {
            switch token.type {
            case .operator(_):
                return "Did you forget an operand before this operator?"
            case .rightParen:
                return "Did you forget to add an expression before the closing parenthesis?"
            case .assign:
                return "Assignment operators need an identifier on the left side."
            default:
                break
            }
        }
        
        // If we expected a closing parenthesis
        if expected.contains(.rightParen) {
            switch token.type {
            case .eof:
                return "The expression is missing a closing parenthesis."
            case .operator(_):
                return "Did you forget to close the parentheses before this operator?"
            default:
                break
            }
        }
        
        // If we expected an operator but got something else
        if expected.contains(where: { if case .operator(_) = $0 { return true } else { return false } }) {
            switch token.type {
            case .number, .identifier:
                return "Did you forget an operator between these values?"
            case .leftParen:
                return "Did you forget an operator before this parenthesized expression?"
            default:
                break
            }
        }
        
        return nil
    }
}