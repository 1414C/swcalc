import SwiftCalcTokenizer

/// A visitor that converts AST nodes to their string representation
/// 
/// This visitor is useful for debugging, logging, and displaying AST structures
/// in a human-readable format. It reconstructs the original expression syntax
/// from the AST nodes.
/// 
/// Example usage:
/// ```swift
/// let visitor = ASTStringVisitor()
/// let result = try ast.accept(visitor)
/// print("Expression: \(result)")
/// ```
public struct ASTStringVisitor: ASTVisitor {
    public typealias Result = String
    
    /// Whether to include parentheses around all binary operations for clarity
    public let explicitParentheses: Bool
    
    /// Creates a new string visitor
    /// 
    /// - Parameter explicitParentheses: Whether to show all parentheses explicitly
    public init(explicitParentheses: Bool = false) {
        self.explicitParentheses = explicitParentheses
    }
    
    public func visit(_ node: BinaryOperation) throws -> String {
        let left = try node.left.accept(self)
        let right = try node.right.accept(self)
        let operatorStr = node.operator.description
        
        if explicitParentheses {
            return "(\(left) \(operatorStr) \(right))"
        } else {
            return "\(left) \(operatorStr) \(right)"
        }
    }
    
    public func visit(_ node: UnaryOperation) throws -> String {
        let operand = try node.operand.accept(self)
        let operatorStr = node.operator.description
        
        // Check if we need parentheses around the operand
        if node.operand is BinaryOperation {
            return "\(operatorStr)(\(operand))"
        } else {
            return "\(operatorStr)\(operand)"
        }
    }
    
    public func visit(_ node: Literal) throws -> String {
        return node.value
    }
    
    public func visit(_ node: Identifier) throws -> String {
        return node.name
    }
    
    public func visit(_ node: Assignment) throws -> String {
        let target = try node.target.accept(self)
        let value = try node.value.accept(self)
        return "\(target) = \(value)"
    }
    
    public func visit(_ node: FunctionCall) throws -> String {
        let args = try node.arguments.map { try $0.accept(self) }
        let argList = args.joined(separator: ", ")
        return "\(node.name)(\(argList))"
    }
    
    public func visit(_ node: ParenthesizedExpression) throws -> String {
        let inner = try node.expression.accept(self)
        return "(\(inner))"
    }
    
    public func visitProgram(_ node: Program) throws -> String {
        let statements = try node.statements.map { try $0.accept(self) }
        return statements.joined(separator: "\n")
    }
}