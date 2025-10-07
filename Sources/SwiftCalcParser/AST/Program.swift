import SwiftCalcTokenizer

/// Represents a complete program consisting of multiple statements/expressions
/// 
/// A Program node is the root of the AST when parsing multiple lines of calculator
/// language syntax. It contains a sequence of expressions that are evaluated in order.
/// 
/// Example usage:
/// ```swift
/// let program = Program(statements: [
///     Assignment(target: Identifier(name: "x", position: pos1), value: Literal(value: "5", position: pos2), position: pos3),
///     BinaryOperation(operator: .plus, left: Identifier(name: "x", position: pos4), right: Literal(value: "3", position: pos5), position: pos6)
/// ], position: Position(line: 1, column: 1))
/// ```
public struct Program: ASTNode {
    /// The list of statements/expressions in this program
    public let statements: [Expression]
    
    /// The position in the source text where this program starts
    public let position: Position
    
    /// Creates a new Program node
    /// 
    /// - Parameters:
    ///   - statements: The list of statements/expressions in the program
    ///   - position: The position where the program starts in the source
    public init(statements: [Expression], position: Position) {
        self.statements = statements
        self.position = position
    }
    
    /// Accepts a visitor for tree traversal using the visitor pattern
    /// 
    /// - Parameter visitor: The visitor that will process this node
    /// - Returns: The result of the visitor's processing
    /// - Throws: Any error that the visitor might encounter during processing
    public func accept<V: ASTVisitor>(_ visitor: V) throws -> V.Result {
        return try visitor.visitProgram(self)
    }
}

/// Extension to make Program conform to Expression for compatibility
/// 
/// This allows a Program to be treated as an Expression in contexts where
/// a single expression is expected, which is useful for maintaining backward
/// compatibility with existing code.
extension Program: Expression {}