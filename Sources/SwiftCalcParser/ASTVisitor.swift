/// Protocol for implementing the visitor pattern on AST nodes
/// 
/// The visitor pattern allows you to define operations on AST nodes without
/// modifying the node classes themselves. This enables clean separation of
/// concerns and makes it easy to add new operations like evaluation, code
/// generation, optimization, or analysis.
/// 
/// Example implementation:
/// ```swift
/// struct Evaluator: ASTVisitor {
///     typealias Result = Double
///     
///     func visit(_ node: Literal) throws -> Double {
///         return Double(node.value) ?? 0.0
///     }
///     
///     func visit(_ node: BinaryOperation) throws -> Double {
///         let left = try node.left.accept(self)
///         let right = try node.right.accept(self)
///         switch node.operator {
///         case .plus: return left + right
///         case .minus: return left - right
///         // ... other operators
///         }
///     }
/// }
/// ```
public protocol ASTVisitor {
    /// The type of result that this visitor produces
    /// 
    /// Different visitors can produce different result types:
    /// - Evaluator might produce `Double` for numeric results
    /// - CodeGenerator might produce `String` for generated code
    /// - Analyzer might produce `Void` for side-effect operations
    associatedtype Result
    
    /// Visit a binary operation node
    /// 
    /// - Parameter node: The binary operation node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visit(_ node: BinaryOperation) throws -> Result
    
    /// Visit a unary operation node
    /// 
    /// - Parameter node: The unary operation node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visit(_ node: UnaryOperation) throws -> Result
    
    /// Visit a literal node
    /// 
    /// - Parameter node: The literal node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visit(_ node: Literal) throws -> Result
    
    /// Visit an identifier node
    /// 
    /// - Parameter node: The identifier node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visit(_ node: Identifier) throws -> Result
    
    /// Visit an assignment node
    /// 
    /// - Parameter node: The assignment node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visit(_ node: Assignment) throws -> Result
    
    /// Visit a function call node
    /// 
    /// - Parameter node: The function call node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visit(_ node: FunctionCall) throws -> Result
    
    /// Visit a parenthesized expression node
    /// 
    /// - Parameter node: The parenthesized expression node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visit(_ node: ParenthesizedExpression) throws -> Result
    
    /// Visit a program node
    /// 
    /// - Parameter node: The program node to visit
    /// - Returns: The result of processing this node
    /// - Throws: Any error encountered during processing
    func visitProgram(_ node: Program) throws -> Result
}