import Foundation

/// Represents errors that can occur during tokenization
/// 
/// TokenizerError provides detailed information about tokenization failures,
/// including the specific error type and the position where the error occurred.
/// This enables precise error reporting and debugging capabilities.
/// 
/// Example usage:
/// ```swift
/// do {
///     let tokens = try tokenizer.tokenize()
/// } catch TokenizerError.invalidCharacter(let char, let position) {
///     print("Invalid character '\(char)' at line \(position.line), column \(position.column)")
/// } catch TokenizerError.malformedNumber(let number, let position) {
///     print("Malformed number '\(number)' at \(position)")
/// } catch {
///     print("Other error: \(error)")
/// }
/// ```
public enum TokenizerError: Error {
    /// An invalid character was encountered at the specified position
    /// 
    /// This error occurs when the tokenizer encounters a character that is not
    /// part of the calculator language syntax (not a digit, letter, operator, etc.).
    /// 
    /// - Parameters:
    ///   - Character: The invalid character that was encountered
    ///   - Position: The position where the invalid character was found
    case invalidCharacter(Character, Position)
    
    /// A malformed number was encountered (e.g., multiple decimal points)
    /// 
    /// This error occurs when the tokenizer detects a number with invalid formatting,
    /// such as multiple decimal points (e.g., "3.14.159") or other malformed patterns.
    /// 
    /// - Parameters:
    ///   - String: The malformed number string that was encountered
    ///   - Position: The position where the malformed number started
    case malformedNumber(String, Position)
    
    /// Unexpected end of input while parsing a token
    /// 
    /// This error occurs when the tokenizer reaches the end of input while expecting
    /// more characters to complete a token (though this is rare in the current implementation).
    /// 
    /// - Parameter Position: The position where the unexpected end of input occurred
    case unexpectedEndOfInput(Position)
}

// MARK: - Equatable
extension TokenizerError: Equatable {}

// MARK: - CustomStringConvertible
extension TokenizerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidCharacter(let char, let position):
            return "Invalid character '\(char)' at \(position)"
        case .malformedNumber(let number, let position):
            return "Malformed number '\(number)' at \(position)"
        case .unexpectedEndOfInput(let position):
            return "Unexpected end of input at \(position)"
        }
    }
}

// MARK: - LocalizedError
extension TokenizerError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}