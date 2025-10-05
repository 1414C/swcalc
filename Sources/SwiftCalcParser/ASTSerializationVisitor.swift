import Foundation
import SwiftCalcTokenizer

/// A visitor that serializes AST nodes to a structured format
/// 
/// This visitor converts AST nodes into a serializable dictionary format that
/// preserves all structural and positional information. The serialized format
/// can be used for persistence, debugging, or transmission over networks.
/// 
/// Example usage:
/// ```swift
/// let visitor = ASTSerializationVisitor()
/// let serialized = try ast.accept(visitor)
/// // Convert to JSON or other formats as needed
/// ```
public struct ASTSerializationVisitor: ASTVisitor {
    public typealias Result = [String: Any]
    
    public init() {}
    
    /// Serializes position information
    private func serializePosition(_ position: Position) -> [String: Any] {
        return [
            "line": position.line,
            "column": position.column
        ]
    }
    
    public func visit(_ node: BinaryOperation) throws -> [String: Any] {
        let left = try node.left.accept(self)
        let right = try node.right.accept(self)
        
        return [
            "type": "BinaryOperation",
            "operator": node.operator.description,
            "left": left,
            "right": right,
            "position": serializePosition(node.position)
        ]
    }
    
    public func visit(_ node: UnaryOperation) throws -> [String: Any] {
        let operand = try node.operand.accept(self)
        
        return [
            "type": "UnaryOperation",
            "operator": node.operator.description,
            "operand": operand,
            "position": serializePosition(node.position)
        ]
    }
    
    public func visit(_ node: Literal) throws -> [String: Any] {
        return [
            "type": "Literal",
            "value": node.value,
            "position": serializePosition(node.position)
        ]
    }
    
    public func visit(_ node: Identifier) throws -> [String: Any] {
        return [
            "type": "Identifier",
            "name": node.name,
            "position": serializePosition(node.position)
        ]
    }
    
    public func visit(_ node: Assignment) throws -> [String: Any] {
        let target = try node.target.accept(self)
        let value = try node.value.accept(self)
        
        return [
            "type": "Assignment",
            "target": target,
            "value": value,
            "position": serializePosition(node.position)
        ]
    }
    
    public func visit(_ node: FunctionCall) throws -> [String: Any] {
        let arguments = try node.arguments.map { try $0.accept(self) }
        
        return [
            "type": "FunctionCall",
            "name": node.name,
            "arguments": arguments,
            "position": serializePosition(node.position)
        ]
    }
    
    public func visit(_ node: ParenthesizedExpression) throws -> [String: Any] {
        let expression = try node.expression.accept(self)
        
        return [
            "type": "ParenthesizedExpression",
            "expression": expression,
            "position": serializePosition(node.position)
        ]
    }
}

/// Utility functions for AST serialization
public extension ASTSerializationVisitor {
    
    /// Converts a serialized AST to a JSON string
    /// 
    /// - Parameter serialized: The serialized AST dictionary
    /// - Returns: A JSON string representation
    /// - Throws: JSONSerialization errors
    static func toJSON(_ serialized: [String: Any]) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: serialized, options: [.prettyPrinted, .sortedKeys])
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    /// Converts a serialized AST to a compact JSON string
    /// 
    /// - Parameter serialized: The serialized AST dictionary
    /// - Returns: A compact JSON string representation
    /// - Throws: JSONSerialization errors
    static func toCompactJSON(_ serialized: [String: Any]) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: serialized, options: [])
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
}