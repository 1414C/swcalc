import SwiftCalcTokenizer

/// Utilities for traversing and analyzing AST structures
/// 
/// This class provides helper methods for common AST operations that don't
/// require implementing a full visitor. These utilities are useful for
/// quick analysis and manipulation of AST nodes.
public final class ASTTraversal {
    
    /// Private initializer to prevent instantiation
    private init() {}
    
    // MARK: - Tree Traversal Methods
    
    /// Performs a pre-order traversal of the AST, calling the provided closure for each node
    /// 
    /// Pre-order traversal visits the current node first, then recursively visits
    /// its children from left to right.
    /// 
    /// - Parameters:
    ///   - node: The root node to start traversal from
    ///   - visit: A closure called for each node during traversal
    /// - Throws: Any error thrown by the visit closure
    public static func preOrderTraversal(_ node: Expression, visit: (Expression) throws -> Void) throws {
        try visit(node)
        
        switch node {
        case let binaryOp as BinaryOperation:
            try preOrderTraversal(binaryOp.left, visit: visit)
            try preOrderTraversal(binaryOp.right, visit: visit)
            
        case let unaryOp as UnaryOperation:
            try preOrderTraversal(unaryOp.operand, visit: visit)
            
        case let assignment as Assignment:
            try preOrderTraversal(assignment.target, visit: visit)
            try preOrderTraversal(assignment.value, visit: visit)
            
        case let functionCall as FunctionCall:
            for argument in functionCall.arguments {
                try preOrderTraversal(argument, visit: visit)
            }
            
        case let parenthesized as ParenthesizedExpression:
            try preOrderTraversal(parenthesized.expression, visit: visit)
            
        case is Literal, is Identifier:
            // Leaf nodes - no children to traverse
            break
            
        default:
            // Handle any future node types
            break
        }
    }
    
    /// Performs a post-order traversal of the AST, calling the provided closure for each node
    /// 
    /// Post-order traversal recursively visits all children first, then visits
    /// the current node. This is useful for operations that need to process
    /// children before their parents.
    /// 
    /// - Parameters:
    ///   - node: The root node to start traversal from
    ///   - visit: A closure called for each node during traversal
    /// - Throws: Any error thrown by the visit closure
    public static func postOrderTraversal(_ node: Expression, visit: (Expression) throws -> Void) throws {
        switch node {
        case let binaryOp as BinaryOperation:
            try postOrderTraversal(binaryOp.left, visit: visit)
            try postOrderTraversal(binaryOp.right, visit: visit)
            
        case let unaryOp as UnaryOperation:
            try postOrderTraversal(unaryOp.operand, visit: visit)
            
        case let assignment as Assignment:
            try postOrderTraversal(assignment.target, visit: visit)
            try postOrderTraversal(assignment.value, visit: visit)
            
        case let functionCall as FunctionCall:
            for argument in functionCall.arguments {
                try postOrderTraversal(argument, visit: visit)
            }
            
        case let parenthesized as ParenthesizedExpression:
            try postOrderTraversal(parenthesized.expression, visit: visit)
            
        case is Literal, is Identifier:
            // Leaf nodes - no children to traverse
            break
            
        default:
            // Handle any future node types
            break
        }
        
        try visit(node)
    }
    
    /// Collects all nodes of a specific type from the AST
    /// 
    /// This method traverses the AST and returns all nodes that match the
    /// specified type. This is useful for analysis operations that need to
    /// examine all instances of a particular node type.
    /// 
    /// - Parameters:
    ///   - node: The root node to start searching from
    ///   - type: The type of nodes to collect
    /// - Returns: An array of all nodes matching the specified type
    public static func collectNodes<T>(from node: Expression, ofType type: T.Type) -> [T] {
        var results: [T] = []
        
        do {
            try preOrderTraversal(node) { currentNode in
                if let matchingNode = currentNode as? T {
                    results.append(matchingNode)
                }
            }
        } catch {
            // This shouldn't happen since we're not throwing in the closure
            // but we need to handle the throws requirement
        }
        
        return results
    }
    
    /// Finds the first node of a specific type in the AST
    /// 
    /// This method performs a pre-order traversal and returns the first node
    /// that matches the specified type, or nil if no matching node is found.
    /// 
    /// - Parameters:
    ///   - node: The root node to start searching from
    ///   - type: The type of node to find
    /// - Returns: The first matching node, or nil if none found
    public static func findFirst<T>(in node: Expression, ofType type: T.Type) -> T? {
        var result: T?
        
        do {
            try preOrderTraversal(node) { currentNode in
                if result == nil, let matchingNode = currentNode as? T {
                    result = matchingNode
                }
            }
        } catch {
            // This shouldn't happen since we're not throwing in the closure
        }
        
        return result
    }
    
    /// Checks if the AST contains any node of the specified type
    /// 
    /// This is a convenience method that returns true if at least one node
    /// of the specified type exists in the AST.
    /// 
    /// - Parameters:
    ///   - node: The root node to start searching from
    ///   - type: The type of node to search for
    /// - Returns: True if at least one matching node exists, false otherwise
    public static func contains<T>(node: Expression, nodeOfType type: T.Type) -> Bool {
        return findFirst(in: node, ofType: type) != nil
    }
}