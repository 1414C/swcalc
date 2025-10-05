import SwiftCalcTokenizer

/// AST node representing a parenthesized expression
/// 
/// Parenthesized expression nodes represent expressions that are explicitly
/// grouped with parentheses to override default operator precedence or
/// to make the expression structure more explicit.
/// 
/// Example usage:
/// ```swift
/// // Represents: (2 + 3)
/// let grouped = ParenthesizedExpression(
///     expression: BinaryOperation(
///         operator: .plus,
///         left: Literal(value: "2", position: pos1),
///         right: Literal(value: "3", position: pos2),
///         position: pos3
///     ),
///     position: pos4
/// )
/// ```
public struct ParenthesizedExpression: Expression {
    /// The inner expression that is wrapped in parentheses
    /// 
    /// This can be any valid expression: literals, identifiers, binary
    /// operations, function calls, or even other parenthesized expressions
    /// for nested grouping.
    public let expression: Expression
    
    /// The position in the source text where this parenthesized expression was parsed from
    /// 
    /// This typically refers to the position of the opening parenthesis.
    public let position: Position
    
    /// Creates a new parenthesized expression node
    /// 
    /// - Parameters:
    ///   - expression: The inner expression
    ///   - position: The position in the source text
    public init(expression: Expression, position: Position) {
        self.expression = expression
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