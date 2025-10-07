import Foundation

/// A specialized AST visualizer that displays the AST with annotations from pass results
/// 
/// This visualizer enhances the standard AST tree display by incorporating information
/// from AST passes, such as number type analysis, to provide a richer view of the
/// analyzed AST structure.
/// 
/// Example usage:
/// ```swift
/// let passManager = ASTPassManager.withStandardAnalysis()
/// let results = try passManager.runPasses(on: ast)
/// let annotatedTree = try AnnotatedASTVisualizer.visualize(ast, with: results)
/// print(annotatedTree)
/// ```
public class AnnotatedASTVisualizer {
    
    /// Characters used for drawing the tree structure
    private struct TreeChars {
        static let branch = "├"
        static let lastBranch = "└"
        static let vertical = "│"
        static let horizontal = "─"
        static let space = " "
    }
    
    /// Creates an annotated visualization of the AST with pass results
    /// 
    /// - Parameters:
    ///   - node: The AST node to visualize
    ///   - results: The results from AST passes to include in the visualization
    /// - Returns: A string containing the annotated tree visualization
    /// - Throws: Any error encountered during visualization
    public static func visualize(_ node: SwiftCalcParser.Expression, with results: ASTPassResults) throws -> String {
        let visitor = AnnotatedTreeVisualizationVisitor(results: results)
        return try node.accept(visitor)
    }
    
    /// A visitor that creates annotated tree visualizations
    private struct AnnotatedTreeVisualizationVisitor: ASTVisitor {
        typealias Result = String
        
        private let prefix: String
        private let isLast: Bool
        private let results: ASTPassResults
        
        init(results: ASTPassResults, prefix: String = "", isLast: Bool = true) {
            self.results = results
            self.prefix = prefix
            self.isLast = isLast
        }
        
        private func childVisitor(isLast: Bool) -> AnnotatedTreeVisualizationVisitor {
            let childPrefix = prefix + (self.isLast ? "    " : "│   ")
            return AnnotatedTreeVisualizationVisitor(results: results, prefix: childPrefix, isLast: isLast)
        }
        
        private func nodeHeader(_ label: String, annotations: [String] = []) -> String {
            let connector = isLast ? TreeChars.lastBranch : TreeChars.branch
            let baseHeader = prefix + connector + TreeChars.horizontal + TreeChars.horizontal + " " + label
            
            if annotations.isEmpty {
                return baseHeader
            } else {
                let annotationString = annotations.joined(separator: ", ")
                return baseHeader + " " + "[\(annotationString)]"
            }
        }
        
        /// Gets annotations for a literal node based on pass results
        private func getAnnotationsForLiteral(_ node: Literal) -> [String] {
            var annotations: [String] = []
            
            // Add number type annotation if available
            if let numberAnalysis = results.getNumberTypeAnalysis() {
                for numberInfo in numberAnalysis.numbers {
                    if numberInfo.position == node.position && numberInfo.value == node.value {
                        let typeIcon = numberInfo.type == .integer ? "🔢" : "🔣"
                        annotations.append("\(typeIcon) \(numberInfo.type)")
                        
                        if let numericValue = numberInfo.numericValue {
                            annotations.append("val: \(numericValue)")
                        }
                        break
                    }
                }
            }
            
            return annotations
        }
        
        /// Gets annotations for any AST node based on pass results
        private func getAnnotationsForNode(_ node: ASTNode) -> [String] {
            var annotations: [String] = []
            
            // Add position information
            annotations.append("@\(node.position.line):\(node.position.column)")
            
            return annotations
        }
        
        /// Gets annotations for an identifier node based on variable type inference
        private func getAnnotationsForIdentifier(_ node: Identifier) -> [String] {
            var annotations: [String] = []
            
            // Add variable type annotation if available
            if let variableAnalysis = results.getVariableTypeInference() {
                if let variableInfo = variableAnalysis.typeInfo(for: node.name) {
                    let typeIcon = variableInfo.inferredType == .integer ? "🔢" : "🔣"
                    annotations.append("\(typeIcon) var:\(variableInfo.inferredType)")
                }
            }
            
            return annotations
        }
        
        func visit(_ node: BinaryOperation) throws -> String {
            let annotations = getAnnotationsForNode(node)
            let header = nodeHeader("BinaryOp: \(node.operator.description)", annotations: annotations)
            let leftResult = try node.left.accept(childVisitor(isLast: false))
            let rightResult = try node.right.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(leftResult)
            \(rightResult)
            """
        }
        
        func visit(_ node: UnaryOperation) throws -> String {
            let annotations = getAnnotationsForNode(node)
            let header = nodeHeader("UnaryOp: \(node.operator.description)", annotations: annotations)
            let operandResult = try node.operand.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(operandResult)
            """
        }
        
        func visit(_ node: Literal) throws -> String {
            var annotations = getAnnotationsForNode(node)
            annotations.append(contentsOf: getAnnotationsForLiteral(node))
            return nodeHeader("Literal: \(node.value)", annotations: annotations)
        }
        
        func visit(_ node: Identifier) throws -> String {
            var annotations = getAnnotationsForNode(node)
            annotations.append(contentsOf: getAnnotationsForIdentifier(node))
            return nodeHeader("Identifier: \(node.name)", annotations: annotations)
        }
        
        func visit(_ node: Assignment) throws -> String {
            let annotations = getAnnotationsForNode(node)
            let header = nodeHeader("Assignment: =", annotations: annotations)
            let targetResult = try node.target.accept(childVisitor(isLast: false))
            let valueResult = try node.value.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(targetResult)
            \(valueResult)
            """
        }
        
        func visit(_ node: FunctionCall) throws -> String {
            let annotations = getAnnotationsForNode(node)
            let header = nodeHeader("FunctionCall: \(node.name)(\(node.arguments.count))", annotations: annotations)
            
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
            let annotations = getAnnotationsForNode(node)
            let header = nodeHeader("Parentheses: ()", annotations: annotations)
            let innerResult = try node.expression.accept(childVisitor(isLast: true))
            
            return """
            \(header)
            \(innerResult)
            """
        }
        
        func visitProgram(_ node: Program) throws -> String {
            let annotations = getAnnotationsForNode(node)
            let header = nodeHeader("Program: (\(node.statements.count) statements)", annotations: annotations)
            
            if node.statements.isEmpty {
                return header
            }
            
            var result = header + "\n"
            for (index, statement) in node.statements.enumerated() {
                let isLastStmt = index == node.statements.count - 1
                let stmtResult = try statement.accept(childVisitor(isLast: isLastStmt))
                result += stmtResult
                if !isLastStmt {
                    result += "\n"
                }
            }
            
            return result
        }
    }
}

/// Extension to provide convenient annotated visualization methods
public extension SwiftCalcParser.Expression {
    
    /// Creates an annotated visual tree representation of this AST node with pass results
    /// 
    /// - Parameter results: The results from AST passes to include in the visualization
    /// - Returns: A string containing the annotated visual tree representation
    /// - Throws: Any error encountered during traversal
    func visualizeAnnotatedTree(with results: ASTPassResults) throws -> String {
        return try AnnotatedASTVisualizer.visualize(self, with: results)
    }
}