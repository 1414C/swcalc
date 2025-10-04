/// Represents a position in the source text with line and column information
/// 
/// Position tracking is essential for providing meaningful error messages and
/// supporting development tools like syntax highlighting and debugging.
/// Both line and column numbers are 1-based to match common editor conventions.
/// 
/// Example usage:
/// ```swift
/// let position = Position(line: 3, column: 15)
/// print(position) // Prints: 3:15
/// 
/// // Used in tokens for error reporting
/// let token = Token(type: .error, value: "@", position: position)
/// print("Invalid character at \(token.position)")
/// ```
public struct Position {
    /// The line number (1-based)
    /// 
    /// Line numbers start at 1 and increment each time a newline character
    /// is encountered in the source text.
    public let line: Int
    
    /// The column number (1-based)
    /// 
    /// Column numbers start at 1 for each line and increment with each character.
    /// When a newline is encountered, the column resets to 1 for the next line.
    public let column: Int
    
    /// Creates a new position with the specified line and column
    /// 
    /// - Parameters:
    ///   - line: The line number (1-based, must be positive)
    ///   - column: The column number (1-based, must be positive)
    /// 
    /// Example:
    /// ```swift
    /// let startPosition = Position(line: 1, column: 1)
    /// let errorPosition = Position(line: 5, column: 23)
    /// ```
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
}

// MARK: - Equatable
extension Position: Equatable {}

// MARK: - CustomStringConvertible
extension Position: CustomStringConvertible {
    public var description: String {
        return "\(line):\(column)"
    }
}