/// Represents a single token with its type, value, and position information
/// 
/// A Token is the fundamental unit produced by the tokenizer. Each token represents
/// a meaningful element from the source text, such as a number, operator, identifier,
/// or delimiter. Tokens include position information for error reporting and debugging.
/// 
/// Example usage:
/// ```swift
/// let token = Token(type: .number, value: "3.14", position: Position(line: 1, column: 1))
/// print(token) // Prints: NUMBER('3.14') at 1:1
/// ```
public struct Token {
    /// The type of the token (number, operator, identifier, etc.)
    /// 
    /// This property categorizes the token and may include additional type-specific
    /// information, such as the specific operator type for operator tokens.
    public let type: TokenType
    
    /// The string value of the token as it appears in the source
    /// 
    /// This is the exact text from the source input that this token represents.
    /// For example, a number token with value "3.14" represents those exact
    /// characters from the input.
    public let value: String
    
    /// The position where this token was found in the source text
    /// 
    /// Position information is useful for error reporting, syntax highlighting,
    /// and debugging. The position refers to the start of the token.
    public let position: Position
    
    /// Creates a new token with the specified type, value, and position
    /// 
    /// - Parameters:
    ///   - type: The type of the token (see TokenType for available types)
    ///   - value: The string value of the token as it appears in the source
    ///   - position: The position where the token was found in the source text
    /// 
    /// Example:
    /// ```swift
    /// let numberToken = Token(
    ///     type: .number,
    ///     value: "42",
    ///     position: Position(line: 1, column: 5)
    /// )
    /// ```
    public init(type: TokenType, value: String, position: Position) {
        self.type = type
        self.value = value
        self.position = position
    }
}

// MARK: - Equatable
extension Token: Equatable {}

// MARK: - CustomStringConvertible
extension Token: CustomStringConvertible {
    public var description: String {
        return "\(type)('\(value)') at \(position)"
    }
}