import SwiftCalcTokenizer

/// AST node representing a literal value (number)
/// 
/// Literal nodes represent constant values in the expression, such as numbers.
/// The original token value is preserved to maintain precision and allow for
/// different numeric representations (integers, decimals, scientific notation).
/// 
/// Example usage:
/// ```swift
/// // Represents: 42
/// let intLiteral = Literal(value: "42", position: Position(line: 1, column: 1))
/// 
/// // Represents: 3.14
/// let decimalLiteral = Literal(value: "3.14", position: Position(line: 1, column: 5))
/// ```
public struct Literal: Expression {
    /// The original string value from the token
    /// 
    /// This preserves the exact representation from the source text,
    /// allowing for precise numeric conversion and maintaining the
    /// original format for error reporting or code generation.
    public let value: String
    
    /// The position in the source text where this literal was parsed from
    public let position: Position
    
    /// Creates a new literal node
    /// 
    /// - Parameters:
    ///   - value: The original string value from the token
    ///   - position: The position in the source text
    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
    
    /// Accepts a visitor for tree traversal using the visitor pattern
    /// 
    /// - Parameter visitor: The visitor that will process this node
    /// - Returns: The result of the visitor's processing
    /// - Throws: Any error that the visitor might encounter during processing
    public func accept<V: ASTVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visit(self)
    }
}