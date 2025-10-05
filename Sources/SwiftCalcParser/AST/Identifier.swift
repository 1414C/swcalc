import SwiftCalcTokenizer

/// AST node representing an identifier (variable name)
/// 
/// Identifier nodes represent variable names or function names in expressions.
/// They store the name of the identifier and position information for error
/// reporting and analysis.
/// 
/// Example usage:
/// ```swift
/// // Represents: x
/// let variable = Identifier(name: "x", position: Position(line: 1, column: 1))
/// 
/// // Represents: myVariable
/// let longName = Identifier(name: "myVariable", position: Position(line: 2, column: 5))
/// ```
public struct Identifier: Expression {
    /// The name of the identifier
    /// 
    /// This is the variable or function name as it appears in the source text.
    /// Identifier names follow standard programming language conventions.
    public let name: String
    
    /// The position in the source text where this identifier was parsed from
    public let position: Position
    
    /// Creates a new identifier node
    /// 
    /// - Parameters:
    ///   - name: The name of the identifier
    ///   - position: The position in the source text
    public init(name: String, position: Position) {
        self.name = name
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