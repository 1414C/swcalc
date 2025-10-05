import SwiftCalcTokenizer

/// Utilities for analyzing AST structures and extracting information
/// 
/// This class provides methods for identifying node types, extracting specific
/// information from nodes, and performing common analysis operations on ASTs.
/// These utilities complement the visitor pattern for cases where a full
/// visitor implementation would be overkill.
public final class ASTAnalysis {
    
    /// Private initializer to prevent instantiation
    private init() {}
    
    // MARK: - Node Type Identification
    
    /// Checks if a node is a leaf node (has no children)
    /// 
    /// Leaf nodes are terminal nodes in the AST that don't contain other expressions.
    /// This includes literals and identifiers.
    /// 
    /// - Parameter node: The node to check
    /// - Returns: True if the node is a leaf node, false otherwise
    public static func isLeafNode(_ node: Expression) -> Bool {
        return node is Literal || node is Identifier
    }
    
    /// Checks if a node is a binary operation
    /// 
    /// - Parameter node: The node to check
    /// - Returns: True if the node is a binary operation, false otherwise
    public static func isBinaryOperation(_ node: Expression) -> Bool {
        return node is BinaryOperation
    }
    
    /// Checks if a node is a unary operation
    /// 
    /// - Parameter node: The node to check
    /// - Returns: True if the node is a unary operation, false otherwise
    public static func isUnaryOperation(_ node: Expression) -> Bool {
        return node is UnaryOperation
    }
    
    /// Checks if a node is an assignment
    /// 
    /// - Parameter node: The node to check
    /// - Returns: True if the node is an assignment, false otherwise
    public static func isAssignment(_ node: Expression) -> Bool {
        return node is Assignment
    }
    
    /// Checks if a node is a function call
    /// 
    /// - Parameter node: The node to check
    /// - Returns: True if the node is a function call, false otherwise
    public static func isFunctionCall(_ node: Expression) -> Bool {
        return node is FunctionCall
    }
    
    /// Checks if a node is a parenthesized expression
    /// 
    /// - Parameter node: The node to check
    /// - Returns: True if the node is a parenthesized expression, false otherwise
    public static func isParenthesizedExpression(_ node: Expression) -> Bool {
        return node is ParenthesizedExpression
    }
    
    /// Gets a string description of the node type
    /// 
    /// - Parameter node: The node to describe
    /// - Returns: A string describing the node type
    public static func nodeTypeDescription(_ node: Expression) -> String {
        switch node {
        case is BinaryOperation: return "BinaryOperation"
        case is UnaryOperation: return "UnaryOperation"
        case is Literal: return "Literal"
        case is Identifier: return "Identifier"
        case is Assignment: return "Assignment"
        case is FunctionCall: return "FunctionCall"
        case is ParenthesizedExpression: return "ParenthesizedExpression"
        default: return "Unknown"
        }
    }
    
    // MARK: - Information Extraction
    
    /// Extracts all identifiers used in an expression
    /// 
    /// This method traverses the AST and collects all identifier names,
    /// including those used as assignment targets and function names.
    /// 
    /// - Parameter node: The root node to extract identifiers from
    /// - Returns: A set of all identifier names found in the expression
    public static func extractIdentifiers(from node: Expression) -> Set<String> {
        var identifiers = Set<String>()
        
        do {
            try ASTTraversal.preOrderTraversal(node) { currentNode in
                if let identifier = currentNode as? Identifier {
                    identifiers.insert(identifier.name)
                } else if let functionCall = currentNode as? FunctionCall {
                    identifiers.insert(functionCall.name)
                }
            }
        } catch {
            // This shouldn't happen since we're not throwing in the closure
        }
        
        return identifiers
    }
    
    /// Extracts all literal values used in an expression
    /// 
    /// This method traverses the AST and collects all literal values
    /// as they appear in the original source text.
    /// 
    /// - Parameter node: The root node to extract literals from
    /// - Returns: An array of all literal values found in the expression
    public static func extractLiterals(from node: Expression) -> [String] {
        let literals = ASTTraversal.collectNodes(from: node, ofType: Literal.self)
        return literals.map { $0.value }
    }
    
    /// Extracts all operators used in an expression
    /// 
    /// This method traverses the AST and collects all binary and unary operators.
    /// 
    /// - Parameter node: The root node to extract operators from
    /// - Returns: A dictionary mapping operator types to their usage counts
    public static func extractOperators(from node: Expression) -> [String: Int] {
        var operators: [String: Int] = [:]
        
        do {
            try ASTTraversal.preOrderTraversal(node) { currentNode in
                if let binaryOp = currentNode as? BinaryOperation {
                    let opStr = binaryOp.operator.description
                    operators[opStr, default: 0] += 1
                } else if let unaryOp = currentNode as? UnaryOperation {
                    let opStr = unaryOp.operator.description
                    operators[opStr, default: 0] += 1
                }
            }
        } catch {
            // This shouldn't happen since we're not throwing in the closure
        }
        
        return operators
    }
    
    /// Extracts all function calls used in an expression
    /// 
    /// This method traverses the AST and collects information about all function calls,
    /// including function names and argument counts.
    /// 
    /// - Parameter node: The root node to extract function calls from
    /// - Returns: An array of tuples containing function names and argument counts
    public static func extractFunctionCalls(from node: Expression) -> [(name: String, argumentCount: Int)] {
        let functionCalls = ASTTraversal.collectNodes(from: node, ofType: FunctionCall.self)
        return functionCalls.map { (name: $0.name, argumentCount: $0.arguments.count) }
    }
    
    /// Extracts all assignment targets from an expression
    /// 
    /// This method traverses the AST and collects all identifiers that are
    /// used as assignment targets.
    /// 
    /// - Parameter node: The root node to extract assignment targets from
    /// - Returns: A set of all identifier names used as assignment targets
    public static func extractAssignmentTargets(from node: Expression) -> Set<String> {
        let assignments = ASTTraversal.collectNodes(from: node, ofType: Assignment.self)
        return Set(assignments.map { $0.target.name })
    }
    
    // MARK: - Structural Analysis
    
    /// Calculates the maximum depth of the AST
    /// 
    /// This is a convenience method that uses the ASTDepthVisitor to calculate
    /// the depth of the expression tree.
    /// 
    /// - Parameter node: The root node to calculate depth for
    /// - Returns: The maximum depth of the AST
    /// - Throws: Any error encountered during traversal
    public static func calculateDepth(of node: Expression) throws -> Int {
        let visitor = ASTDepthVisitor()
        return try node.accept(visitor)
    }
    
    /// Counts the total number of nodes in the AST
    /// 
    /// This is a convenience method that uses the ASTNodeCountVisitor to count
    /// all nodes in the expression tree.
    /// 
    /// - Parameter node: The root node to count nodes for
    /// - Returns: The total number of nodes in the AST
    /// - Throws: Any error encountered during traversal
    public static func countNodes(in node: Expression) throws -> Int {
        let visitor = ASTNodeCountVisitor()
        return try node.accept(visitor)
    }
    
    /// Generates a string representation of the AST
    /// 
    /// This is a convenience method that uses the ASTStringVisitor to generate
    /// a readable string representation of the expression.
    /// 
    /// - Parameters:
    ///   - node: The root node to convert to string
    ///   - explicitParentheses: Whether to show all parentheses explicitly
    /// - Returns: A string representation of the AST
    /// - Throws: Any error encountered during traversal
    public static func toString(_ node: Expression, explicitParentheses: Bool = false) throws -> String {
        let visitor = ASTStringVisitor(explicitParentheses: explicitParentheses)
        return try node.accept(visitor)
    }
    
    // MARK: - Complexity Analysis
    
    /// Calculates a complexity score for the expression
    /// 
    /// The complexity score is based on the number of nodes, depth, and types
    /// of operations in the expression. Higher scores indicate more complex expressions.
    /// 
    /// - Parameter node: The root node to calculate complexity for
    /// - Returns: A complexity score (higher values indicate more complexity)
    /// - Throws: Any error encountered during analysis
    public static func calculateComplexity(of node: Expression) throws -> Int {
        let nodeCount = try countNodes(in: node)
        let depth = try calculateDepth(of: node)
        let operators = extractOperators(from: node)
        let functionCalls = extractFunctionCalls(from: node)
        
        // Base complexity from node count and depth
        var complexity = nodeCount + (depth * 2)
        
        // Add complexity for different operator types
        for (_, count) in operators {
            complexity += count
        }
        
        // Add complexity for function calls (functions are more complex)
        complexity += functionCalls.count * 3
        
        // Add complexity for function arguments
        let totalArguments = functionCalls.reduce(0) { $0 + $1.argumentCount }
        complexity += totalArguments
        
        return complexity
    }
    
    /// Checks if an expression contains any assignments
    /// 
    /// - Parameter node: The root node to check
    /// - Returns: True if the expression contains at least one assignment, false otherwise
    public static func containsAssignments(_ node: Expression) -> Bool {
        return ASTTraversal.contains(node: node, nodeOfType: Assignment.self)
    }
    
    /// Checks if an expression contains any function calls
    /// 
    /// - Parameter node: The root node to check
    /// - Returns: True if the expression contains at least one function call, false otherwise
    public static func containsFunctionCalls(_ node: Expression) -> Bool {
        return ASTTraversal.contains(node: node, nodeOfType: FunctionCall.self)
    }
    
    /// Checks if an expression is purely arithmetic (no assignments or function calls)
    /// 
    /// - Parameter node: The root node to check
    /// - Returns: True if the expression contains only arithmetic operations, literals, and identifiers
    public static func isPureArithmetic(_ node: Expression) -> Bool {
        return !containsAssignments(node) && !containsFunctionCalls(node)
    }
    
    // MARK: - Debugging and Serialization Methods
    
    /// Generates a detailed debug representation of an AST
    /// 
    /// This method creates a comprehensive debug view of the AST including
    /// node types, positions, and structural information.
    /// 
    /// - Parameters:
    ///   - node: The AST root node to debug
    ///   - includePositions: Whether to include position information
    ///   - includeTypes: Whether to include node type information
    /// - Returns: A detailed debug string representation
    /// - Throws: Any error encountered during AST traversal
    public static func debugRepresentation(of node: Expression, 
                                         includePositions: Bool = true, 
                                         includeTypes: Bool = true) throws -> String {
        let visitor = ASTDebugVisitor(includePositions: includePositions, includeTypes: includeTypes)
        return try node.accept(visitor)
    }
    
    /// Serializes an AST to a structured dictionary format
    /// 
    /// This method converts the AST into a serializable format that preserves
    /// all structural and positional information.
    /// 
    /// - Parameter node: The AST root node to serialize
    /// - Returns: A dictionary representation of the AST
    /// - Throws: Any error encountered during AST traversal
    public static func serialize(_ node: Expression) throws -> [String: Any] {
        let visitor = ASTSerializationVisitor()
        return try node.accept(visitor)
    }
    
    /// Converts an AST to a JSON string representation
    /// 
    /// This method serializes the AST and converts it to a pretty-printed
    /// JSON string that preserves all structural and positional information.
    /// 
    /// - Parameter node: The AST root node to convert
    /// - Returns: A JSON string representation of the AST
    /// - Throws: Any error encountered during serialization or JSON conversion
    public static func toJSON(_ node: Expression) throws -> String {
        let serialized = try serialize(node)
        return try ASTSerializationVisitor.toJSON(serialized)
    }
    
    /// Converts an AST to a compact JSON string representation
    /// 
    /// This method serializes the AST and converts it to a compact JSON
    /// string without pretty-printing.
    /// 
    /// - Parameter node: The AST root node to convert
    /// - Returns: A compact JSON string representation of the AST
    /// - Throws: Any error encountered during serialization or JSON conversion
    public static func toCompactJSON(_ node: Expression) throws -> String {
        let serialized = try serialize(node)
        return try ASTSerializationVisitor.toCompactJSON(serialized)
    }
    
    /// Generates a comprehensive analysis report for an AST
    /// 
    /// This method creates a detailed report containing various metrics and
    /// information about the AST structure, useful for debugging and analysis.
    /// 
    /// - Parameter node: The AST root node to analyze
    /// - Returns: A formatted string containing the analysis report
    /// - Throws: Any error encountered during analysis
    public static func generateAnalysisReport(for node: Expression) throws -> String {
        let nodeCount = try countNodes(in: node)
        let depth = try calculateDepth(of: node)
        let complexity = try calculateComplexity(of: node)
        let identifiers = extractIdentifiers(from: node)
        let literals = extractLiterals(from: node)
        let operators = extractOperators(from: node)
        let functionCalls = extractFunctionCalls(from: node)
        let assignmentTargets = extractAssignmentTargets(from: node)
        
        var report = "=== AST Analysis Report ===\n"
        report += "Structure:\n"
        report += "  Total nodes: \(nodeCount)\n"
        report += "  Maximum depth: \(depth)\n"
        report += "  Complexity score: \(complexity)\n"
        report += "  Node type: \(nodeTypeDescription(node))\n"
        report += "\n"
        
        report += "Content Analysis:\n"
        report += "  Identifiers (\(identifiers.count)): \(identifiers.sorted().joined(separator: ", "))\n"
        report += "  Literals (\(literals.count)): \(literals.joined(separator: ", "))\n"
        report += "  Assignment targets (\(assignmentTargets.count)): \(assignmentTargets.sorted().joined(separator: ", "))\n"
        report += "\n"
        
        if !operators.isEmpty {
            report += "Operators:\n"
            for (op, count) in operators.sorted(by: { $0.key < $1.key }) {
                report += "  \(op): \(count) occurrence\(count == 1 ? "" : "s")\n"
            }
            report += "\n"
        }
        
        if !functionCalls.isEmpty {
            report += "Function Calls:\n"
            for (name, argCount) in functionCalls {
                report += "  \(name)(\(argCount) argument\(argCount == 1 ? "" : "s"))\n"
            }
            report += "\n"
        }
        
        report += "Properties:\n"
        report += "  Pure arithmetic: \(isPureArithmetic(node) ? "Yes" : "No")\n"
        report += "  Contains assignments: \(containsAssignments(node) ? "Yes" : "No")\n"
        report += "  Contains function calls: \(containsFunctionCalls(node) ? "Yes" : "No")\n"
        
        return report
    }
    
    /// Creates a visual tree representation of the AST
    /// 
    /// This method generates a tree-like visual representation of the AST
    /// structure using ASCII characters, useful for debugging and visualization.
    /// 
    /// - Parameter node: The AST root node to visualize
    /// - Returns: A string containing the visual tree representation
    /// - Throws: Any error encountered during traversal
    public static func visualizeTree(_ node: Expression) throws -> String {
        return try ASTTreeVisualizer.visualize(node)
    }
}