import SwiftCalcTokenizer

/// Base protocol for all Abstract Syntax Tree nodes
/// 
/// This protocol defines the fundamental interface that all AST nodes must implement.
/// It provides position tracking for error reporting and supports the visitor pattern
/// for tree traversal and analysis.
/// 
/// Example usage:
/// ```swift
/// let literal = Literal(value: "42", position: Position(line: 1, column: 1))
/// let position = literal.position
/// let result = try literal.accept(evaluator)
/// ```
public protocol ASTNode {
    /// The position in the source text where this node was parsed from
    /// 
    /// This position information is crucial for providing meaningful error messages
    /// and supporting development tools like syntax highlighting and debugging.
    var position: Position { get }
    
    /// Accepts a visitor for tree traversal using the visitor pattern
    /// 
    /// This method enables clean separation of concerns by allowing different
    /// operations (evaluation, code generation, optimization, etc.) to be
    /// implemented as separate visitor classes without modifying the AST nodes.
    /// 
    /// - Parameter visitor: The visitor that will process this node
    /// - Returns: The result of the visitor's processing
    /// - Throws: Any error that the visitor might encounter during processing
    func accept<V: ASTVisitor>(_ visitor: V) throws -> V.Result
}

/// Protocol for AST nodes that represent expressions
/// 
/// Expression nodes are AST nodes that can be evaluated to produce values.
/// This includes literals, identifiers, binary operations, function calls, etc.
/// All expressions are also AST nodes, inheriting position tracking and visitor support.
/// 
/// Example usage:
/// ```swift
/// let expr: Expression = BinaryOperation(
///     operator: .plus,
///     left: Literal(value: "2", position: pos1),
///     right: Literal(value: "3", position: pos2),
///     position: pos3
/// )
/// ```
public protocol Expression: ASTNode {}

/// Protocol for AST nodes that represent statements
/// 
/// Statement nodes are AST nodes that perform actions but may not return values.
/// This protocol is defined for future extensibility when the parser supports
/// statements like variable declarations, control flow, etc.
/// 
/// Currently, the calculator primarily deals with expressions, but this protocol
/// provides a foundation for language extension.
public protocol Statement: ASTNode {}