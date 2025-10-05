import SwiftCalcTokenizer

/// A visitor that calculates the depth of an AST
/// 
/// This visitor traverses the AST and returns the maximum depth (number of levels)
/// in the tree. This is useful for analyzing expression complexity and for
/// optimization purposes.
/// 
/// Example usage:
/// ```swift
/// let visitor = ASTDepthVisitor()
/// let depth = try ast.accept(visitor)
/// print("AST depth: \(depth)")
/// ```
public struct ASTDepthVisitor: ASTVisitor {
    public typealias Result = Int
    
    public init() {}
    
    public func visit(_ node: BinaryOperation) throws -> Int {
        let leftDepth = try node.left.accept(self)
        let rightDepth = try node.right.accept(self)
        return 1 + max(leftDepth, rightDepth)
    }
    
    public func visit(_ node: UnaryOperation) throws -> Int {
        let operandDepth = try node.operand.accept(self)
        return 1 + operandDepth
    }
    
    public func visit(_ node: Literal) throws -> Int {
        return 1
    }
    
    public func visit(_ node: Identifier) throws -> Int {
        return 1
    }
    
    public func visit(_ node: Assignment) throws -> Int {
        let targetDepth = try node.target.accept(self)
        let valueDepth = try node.value.accept(self)
        return 1 + max(targetDepth, valueDepth)
    }
    
    public func visit(_ node: FunctionCall) throws -> Int {
        let argDepths = try node.arguments.map { try $0.accept(self) }
        let maxArgDepth = argDepths.max() ?? 0
        return 1 + maxArgDepth
    }
    
    public func visit(_ node: ParenthesizedExpression) throws -> Int {
        let innerDepth = try node.expression.accept(self)
        return 1 + innerDepth
    }
}