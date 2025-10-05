import SwiftCalcTokenizer

/// AST node representing a function call expression
/// 
/// Function call nodes represent invocations of functions with zero or more
/// arguments. This supports mathematical functions like sin(x), max(a, b),
/// or user-defined functions.
/// 
/// Example usage:
/// ```swift
/// // Represents: sin(x)
/// let singleArg = FunctionCall(
///     name: "sin",
///     arguments: [Identifier(name: "x", position: pos1)],
///     position: pos2
/// )
/// 
/// // Represents: max(a, b)
/// let multipleArgs = FunctionCall(
///     name: "max",
///     arguments: [
///         Identifier(name: "a", position: pos1),
///         Identifier(name: "b", position: pos2)
///     ],
///     position: pos3
/// )
/// ```
public struct FunctionCall: Expression {
    /// The name of the function being called
    /// 
    /// This is the function identifier as it appears in the source text.
    /// Function names follow standard identifier conventions.
    public let name: String
    
    /// The array of argument expressions passed to the function
    /// 
    /// Arguments can be any valid expressions: literals, identifiers,
    /// binary operations, or even other function calls for nested calls.
    /// An empty array represents a function call with no arguments.
    public let arguments: [Expression]
    
    /// The position in the source text where this function call was parsed from
    public let position: Position
    
    /// Creates a new function call node
    /// 
    /// - Parameters:
    ///   - name: The name of the function
    ///   - arguments: The array of argument expressions
    ///   - position: The position in the source text
    public init(name: String, arguments: [Expression], position: Position) {
        self.name = name
        self.arguments = arguments
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