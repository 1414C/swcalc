import SwiftCalcTokenizer

/// AST node representing a unary operation on a single expression
/// 
/// Unary operations are operations that take a single operand, such as
/// negation (-5) or other unary operators that may be added in the future.
/// 
/// Example usage:
/// ```swift
/// // Represents: -5
/// let negation = UnaryOperation(
///     operator: .minus,
///     operand: Literal(value: "5", position: pos1),
///     position: pos2
/// )
/// ```
public struct UnaryOperation: Expression {
    /// Enumeration of supported unary operators
    public enum UnaryOperator {
        /// Unary minus operator (-)
        /// 
        /// Used for negation: -5, -(2 + 3), -x
        case minus
    }
    
    /// The unary operator type
    public let `operator`: UnaryOperator
    
    /// The operand expression
    public let operand: Expression
    
    /// The position in the source text where this operation was parsed from
    public let position: Position
    
    /// Creates a new unary operation node
    /// 
    /// - Parameters:
    ///   - operator: The unary operator type
    ///   - operand: The operand expression
    ///   - position: The position in the source text
    public init(operator: UnaryOperator, operand: Expression, position: Position) {
        self.operator = `operator`
        self.operand = operand
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

// MARK: - UnaryOperator Extensions

extension UnaryOperation.UnaryOperator: Equatable {}

extension UnaryOperation.UnaryOperator: CustomStringConvertible {
    public var description: String {
        switch self {
        case .minus: return "-"
        }
    }
}