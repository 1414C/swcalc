import SwiftCalcTokenizer

/// AST node representing an assignment expression
/// 
/// Assignment nodes represent variable assignments where a value is assigned
/// to an identifier. Assignments are right-associative, meaning that
/// `a = b = 5` is equivalent to `a = (b = 5)`.
/// 
/// Example usage:
/// ```swift
/// // Represents: x = 5
/// let assignment = Assignment(
///     target: Identifier(name: "x", position: pos1),
///     value: Literal(value: "5", position: pos2),
///     position: pos3
/// )
/// ```
public struct Assignment: Expression {
    /// The target identifier that will receive the assigned value
    /// 
    /// Only identifiers can be assignment targets. Attempting to assign
    /// to literals or other expression types should result in a parse error.
    public let target: Identifier
    
    /// The expression whose value will be assigned to the target
    /// 
    /// This can be any valid expression: literals, other identifiers,
    /// binary operations, function calls, or even other assignments
    /// (for chained assignments).
    public let value: Expression
    
    /// The position in the source text where this assignment was parsed from
    public let position: Position
    
    /// Creates a new assignment node
    /// 
    /// - Parameters:
    ///   - target: The target identifier
    ///   - value: The expression to assign
    ///   - position: The position in the source text
    public init(target: Identifier, value: Expression, position: Position) {
        self.target = target
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