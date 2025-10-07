import SwiftCalcTokenizer

/// A visitor that counts the total number of nodes in an AST
/// 
/// This visitor traverses the entire AST and returns the total count of all nodes.
/// This is useful for analyzing expression complexity, memory usage estimation,
/// and performance analysis.
/// 
/// Example usage:
/// ```swift
/// let visitor = ASTNodeCountVisitor()
/// let count = try ast.accept(visitor)
/// print("Total nodes: \(count)")
/// ```
public struct ASTNodeCountVisitor: ASTVisitor {
    public typealias Result = Int
    
    public init() {}
    
    public func visit(_ node: BinaryOperation) throws -> Int {
        let leftCount = try node.left.accept(self)
        let rightCount = try node.right.accept(self)
        return 1 + leftCount + rightCount
    }
    
    public func visit(_ node: UnaryOperation) throws -> Int {
        let operandCount = try node.operand.accept(self)
        return 1 + operandCount
    }
    
    public func visit(_ node: Literal) throws -> Int {
        return 1
    }
    
    public func visit(_ node: Identifier) throws -> Int {
        return 1
    }
    
    public func visit(_ node: Assignment) throws -> Int {
        let targetCount = try node.target.accept(self)
        let valueCount = try node.value.accept(self)
        return 1 + targetCount + valueCount
    }
    
    public func visit(_ node: FunctionCall) throws -> Int {
        let argCounts = try node.arguments.map { try $0.accept(self) }
        let totalArgCount = argCounts.reduce(0, +)
        return 1 + totalArgCount
    }
    
    public func visit(_ node: ParenthesizedExpression) throws -> Int {
        let innerCount = try node.expression.accept(self)
        return 1 + innerCount
    }
    
    public func visitProgram(_ node: Program) throws -> Int {
        let statementCounts = try node.statements.map { try $0.accept(self) }
        let totalStatementCount = statementCounts.reduce(0, +)
        return 1 + totalStatementCount
    }
}