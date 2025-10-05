import SwiftCalcTokenizer

/// A visitor that creates detailed debug representations of AST nodes
/// 
/// This visitor provides comprehensive debugging information including node types,
/// positions, and structural details. It's designed for development and debugging
/// purposes where detailed AST inspection is needed.
/// 
/// Example usage:
/// ```swift
/// let visitor = ASTDebugVisitor()
/// let debugInfo = try ast.accept(visitor)
/// print("Debug AST:\n\(debugInfo)")
/// ```
public struct ASTDebugVisitor: ASTVisitor {
    public typealias Result = String
    
    /// The current indentation level for pretty printing
    private let indentLevel: Int
    
    /// The string used for each level of indentation
    private let indentString: String
    
    /// Whether to include position information in the output
    public let includePositions: Bool
    
    /// Whether to include type information in the output
    public let includeTypes: Bool
    
    /// Creates a new debug visitor
    /// 
    /// - Parameters:
    ///   - indentLevel: The current indentation level (used internally for recursion)
    ///   - indentString: The string to use for each indentation level
    ///   - includePositions: Whether to include position information
    ///   - includeTypes: Whether to include node type information
    public init(indentLevel: Int = 0, 
                indentString: String = "  ", 
                includePositions: Bool = true, 
                includeTypes: Bool = true) {
        self.indentLevel = indentLevel
        self.indentString = indentString
        self.includePositions = includePositions
        self.includeTypes = includeTypes
    }
    
    /// Creates a visitor for the next indentation level
    private func nextLevel() -> ASTDebugVisitor {
        return ASTDebugVisitor(
            indentLevel: indentLevel + 1,
            indentString: indentString,
            includePositions: includePositions,
            includeTypes: includeTypes
        )
    }
    
    /// Creates the indentation string for the current level
    private var indent: String {
        return String(repeating: indentString, count: indentLevel)
    }
    
    /// Formats position information if enabled
    private func positionInfo(_ position: Position) -> String {
        guard includePositions else { return "" }
        return " @\(position.line):\(position.column)"
    }
    
    /// Formats type information if enabled
    private func typeInfo(_ typeName: String) -> String {
        guard includeTypes else { return "" }
        return "[\(typeName)]"
    }
    
    public func visit(_ node: BinaryOperation) throws -> String {
        let left = try node.left.accept(nextLevel())
        let right = try node.right.accept(nextLevel())
        let posInfo = positionInfo(node.position)
        let typeInfo = self.typeInfo("BinaryOperation")
        
        return """
        \(indent)\(typeInfo) \(node.operator.description)\(posInfo)
        \(left)
        \(right)
        """
    }
    
    public func visit(_ node: UnaryOperation) throws -> String {
        let operand = try node.operand.accept(nextLevel())
        let posInfo = positionInfo(node.position)
        let typeInfo = self.typeInfo("UnaryOperation")
        
        return """
        \(indent)\(typeInfo) \(node.operator.description)\(posInfo)
        \(operand)
        """
    }
    
    public func visit(_ node: Literal) throws -> String {
        let posInfo = positionInfo(node.position)
        let typeInfo = self.typeInfo("Literal")
        return "\(indent)\(typeInfo) \(node.value)\(posInfo)"
    }
    
    public func visit(_ node: Identifier) throws -> String {
        let posInfo = positionInfo(node.position)
        let typeInfo = self.typeInfo("Identifier")
        return "\(indent)\(typeInfo) \(node.name)\(posInfo)"
    }
    
    public func visit(_ node: Assignment) throws -> String {
        let target = try node.target.accept(nextLevel())
        let value = try node.value.accept(nextLevel())
        let posInfo = positionInfo(node.position)
        let typeInfo = self.typeInfo("Assignment")
        
        return """
        \(indent)\(typeInfo) =\(posInfo)
        \(target)
        \(value)
        """
    }
    
    public func visit(_ node: FunctionCall) throws -> String {
        let posInfo = positionInfo(node.position)
        let typeInfo = self.typeInfo("FunctionCall")
        
        var result = "\(indent)\(typeInfo) \(node.name)(\(node.arguments.count) args)\(posInfo)"
        
        for (index, argument) in node.arguments.enumerated() {
            let argResult = try argument.accept(nextLevel())
            result += "\n\(indent)\(indentString)arg[\(index)]:\n\(argResult)"
        }
        
        return result
    }
    
    public func visit(_ node: ParenthesizedExpression) throws -> String {
        let inner = try node.expression.accept(nextLevel())
        let posInfo = positionInfo(node.position)
        let typeInfo = self.typeInfo("ParenthesizedExpression")
        
        return """
        \(indent)\(typeInfo) ()\(posInfo)
        \(inner)
        """
    }
}