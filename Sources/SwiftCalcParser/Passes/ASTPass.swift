import Foundation

/// Protocol for AST passes that analyze and transform AST nodes
/// 
/// AST passes are used to perform analysis, optimization, or transformation
/// operations on the Abstract Syntax Tree after parsing. Each pass can
/// collect information, annotate nodes, or modify the tree structure.
/// 
/// Example usage:
/// ```swift
/// let pass = NumberTypeAnalysisPass()
/// let annotatedAST = try pass.run(on: ast)
/// ```
public protocol ASTPass {
    /// The type of result this pass produces
    associatedtype Result
    
    /// Runs the pass on the given AST node
    /// 
    /// - Parameter node: The AST node to process
    /// - Returns: The result of running the pass
    /// - Throws: Any error encountered during pass execution
    func run(on node: SwiftCalcParser.Expression) throws -> Result
}

/// Base class for AST passes that provides common functionality
/// 
/// This class provides a foundation for implementing AST passes with
/// common utilities like error handling, progress tracking, and
/// debugging support.
open class BaseASTPass<T>: ASTPass {
    public typealias Result = T
    
    /// Whether debug mode is enabled for this pass
    public let debugMode: Bool
    
    /// The name of this pass for debugging and logging
    public let passName: String
    
    /// Creates a new base AST pass
    /// 
    /// - Parameters:
    ///   - passName: The name of this pass
    ///   - debugMode: Whether to enable debug mode
    public init(passName: String, debugMode: Bool = false) {
        self.passName = passName
        self.debugMode = debugMode
    }
    
    /// Runs the pass on the given AST node
    /// 
    /// This method provides the basic framework for pass execution,
    /// including debug logging and error handling. Subclasses should
    /// override `executePass` to implement the actual pass logic.
    /// 
    /// - Parameter node: The AST node to process
    /// - Returns: The result of running the pass
    /// - Throws: Any error encountered during pass execution
    public func run(on node: SwiftCalcParser.Expression) throws -> T {
        if debugMode {
            print("[\(passName)] Starting pass execution")
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try executePass(on: node)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        if debugMode {
            let duration = endTime - startTime
            print("[\(passName)] Pass completed in \(String(format: "%.4f", duration))s")
        }
        
        return result
    }
    
    /// Executes the actual pass logic
    /// 
    /// Subclasses must override this method to implement their specific
    /// pass functionality.
    /// 
    /// - Parameter node: The AST node to process
    /// - Returns: The result of the pass execution
    /// - Throws: Any error encountered during pass execution
    open func executePass(on node: SwiftCalcParser.Expression) throws -> T {
        fatalError("Subclasses must override executePass(on:)")
    }
    
    /// Logs a debug message if debug mode is enabled
    /// 
    /// - Parameter message: The message to log
    internal func debugLog(_ message: String) {
        if debugMode {
            print("[\(passName)] \(message)")
        }
    }
}

/// Error types for AST pass execution
public enum ASTPassError: Error, LocalizedError {
    /// The pass encountered an unsupported AST node type
    case unsupportedNodeType(String)
    
    /// The pass failed due to invalid input
    case invalidInput(String)
    
    /// The pass encountered an internal error
    case internalError(String)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedNodeType(let nodeType):
            return "Unsupported AST node type: \(nodeType)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .internalError(let message):
            return "Internal error: \(message)"
        }
    }
}