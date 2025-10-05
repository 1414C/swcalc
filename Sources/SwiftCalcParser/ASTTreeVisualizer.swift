import SwiftCalcTokenizer

/// A utility class for creating visual tree representations of ASTs
/// 
/// This class generates ASCII-based tree visualizations of AST structures,
/// making it easier to understand the hierarchical relationships between nodes
/// during debugging and development.
/// 
/// Example usage:
/// ```swift
/// let visualization = try ASTTreeVisualizer.visualize(ast)
/// print(visualization)
/// ```
public final class ASTTreeVisualizer {
    
    /// Private initializer to prevent instantiation
    private init() {}
    
    /// Characters used for drawing the tree structure
    private enum TreeChars {
        static let vertical = "│"
        static let horizontal = "─"
        static let branch = "├"
        static let lastBranch = "└"
        static let space = " "
    }
    
    /// Creates a visual tree representation of an AST
    /// 
    /// - Parameter node: The root node to visualize
    /// - Returns: A string containing the visual tree representation
    /// - Throws: Any error encountered during traversal
    public static func visualize(_ node: Expression) throws -> String {
        let visitor = TreeVisualizationVisitor()
        return try node.accept(visitor)
    }
    
    /// A visitor that creates tree visualizations
    private struct TreeVisualizationVisitor: ASTVisitor {
        typealias Result = String
        
        private let prefix: String
        private let isLast: Bool
        
        init(prefix: String = "", isLast: Bool = true) {
            self.prefix = prefix
            self.isLast = isLast
        }
        
        private func childVisitor(isLast: Bool) -> TreeVisualizationVisitor {
            let childPrefix = prefix + (self.isLast ? "    " : "│   ")
            return TreeVisualizationVisitor(prefix: childPrefix, isLast: isLast)
        }
        
        private func nodeHeader(_ label: String) -> String {
            let connector = isLast ? TreeChars.lastBranch : TreeChars.branch
            return prefix + connector + TreeChars.horizontal + TreeChars.horizontal + " " + label
        }
        
        func visit(_ node: BinaryOperation) throws -> String {
            let header = nodeHeader("BinaryOp: \(node.operator.description)")
            let leftResult = try node.left.accept(childVisitor(isLast: false))
            let rightResult = try node.right.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(leftResult)
            \(rightResult)
            """
        }
        
        func visit(_ node: UnaryOperation) throws -> String {
            let header = nodeHeader("UnaryOp: \(node.operator.description)")
            let operandResult = try node.operand.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(operandResult)
            """
        }
        
        func visit(_ node: Literal) throws -> String {
            return nodeHeader("Literal: \(node.value)")
        }
        
        func visit(_ node: Identifier) throws -> String {
            return nodeHeader("Identifier: \(node.name)")
        }
        
        func visit(_ node: Assignment) throws -> String {
            let header = nodeHeader("Assignment: =")
            let targetResult = try node.target.accept(childVisitor(isLast: false))
            let valueResult = try node.value.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(targetResult)
            \(valueResult)
            """
        }
        
        func visit(_ node: FunctionCall) throws -> String {
            let header = nodeHeader("FunctionCall: \(node.name)(\(node.arguments.count))")
            
            if node.arguments.isEmpty {
                return header
            }
            
            var result = header + "\n"
            for (index, argument) in node.arguments.enumerated() {
                let isLastArg = index == node.arguments.count - 1
                let argResult = try argument.accept(childVisitor(isLast: isLastArg))
                result += argResult
                if !isLastArg {
                    result += "\n"
                }
            }
            
            return result
        }
        
        func visit(_ node: ParenthesizedExpression) throws -> String {
            let header = nodeHeader("Parentheses: ()")
            let innerResult = try node.expression.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(innerResult)
            """
        }
    }
}

/// Extension to provide convenient visualization methods
public extension Expression {
    
    /// Creates a visual tree representation of this AST node
    /// 
    /// - Returns: A string containing the visual tree representation
    /// - Throws: Any error encountered during traversal
    func visualizeTree() throws -> String {
        return try ASTTreeVisualizer.visualize(self)
    }
    
    /// Creates a debug representation of this AST node
    /// 
    /// - Parameters:
    ///   - includePositions: Whether to include position information
    ///   - includeTypes: Whether to include node type information
    /// - Returns: A detailed debug string representation
    /// - Throws: Any error encountered during traversal
    func debugDescription(includePositions: Bool = true, includeTypes: Bool = true) throws -> String {
        let visitor = ASTDebugVisitor(includePositions: includePositions, includeTypes: includeTypes)
        return try self.accept(visitor)
    }
    
    /// Serializes this AST node to a dictionary format
    /// 
    /// - Returns: A dictionary representation of the AST
    /// - Throws: Any error encountered during traversal
    func serialize() throws -> [String: Any] {
        let visitor = ASTSerializationVisitor()
        return try self.accept(visitor)
    }
    
    /// Converts this AST node to a JSON string
    /// 
    /// - Returns: A JSON string representation of the AST
    /// - Throws: Any error encountered during serialization
    func toJSON() throws -> String {
        let serialized = try serialize()
        return try ASTSerializationVisitor.toJSON(serialized)
    }
    
    /// Converts this AST node to a compact JSON string
    /// 
    /// - Returns: A compact JSON string representation of the AST
    /// - Throws: Any error encountered during serialization
    func toCompactJSON() throws -> String {
        let serialized = try serialize()
        return try ASTSerializationVisitor.toCompactJSON(serialized)
    }
}