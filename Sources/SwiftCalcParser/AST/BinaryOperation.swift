import SwiftCalcTokenizer

/// AST node representing a binary operation between two expressions
/// 
/// Binary operations include arithmetic operations like addition, subtraction,
/// multiplication, division, modulo, and exponentiation. Each binary operation
/// has an operator type, left operand, right operand, and position information.
/// 
/// Example usage:
/// ```swift
/// // Represents: 2 + 3
/// let addition = BinaryOperation(
///     operator: .plus,
///     left: Literal(value: "2", position: pos1),
///     right: Literal(value: "3", position: pos2),
///     position: pos3
/// )
/// ```
public struct BinaryOperation: Expression {
    /// The binary operator type
    public let `operator`: OperatorType
    
    /// The left operand expression
    public let left: Expression
    
    /// The right operand expression
    public let right: Expression
    
    /// The position in the source text where this operation was parsed from
    public let position: Position
    
    /// Creates a new binary operation node
    /// 
    /// - Parameters:
    ///   - operator: The binary operator type
    ///   - left: The left operand expression
    ///   - right: The right operand expression
    ///   - position: The position in the source text
    public init(operator: OperatorType, left: Expression, right: Expression, position: Position) {
        self.operator = `operator`
        self.left = left
        self.right = right
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