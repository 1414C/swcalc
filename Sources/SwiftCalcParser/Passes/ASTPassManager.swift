import Foundation

/// Manages and coordinates the execution of multiple AST passes
/// 
/// The ASTPassManager provides a centralized way to run multiple analysis
/// and transformation passes on an AST. It handles pass ordering, dependency
/// management, and result collection.
/// 
/// Example usage:
/// ```swift
/// let manager = ASTPassManager()
/// manager.addPass(NumberTypeAnalysisPass())
/// 
/// let results = try manager.runPasses(on: ast)
/// let numberAnalysis = results.getResult(for: NumberTypeAnalysisPass.self)
/// ```
public class ASTPassManager {
    
    /// Information about a registered pass
    private struct PassInfo {
        let pass: Any
        let passType: Any.Type
        let name: String
    }
    
    /// Array of registered passes in execution order
    private var passes: [PassInfo] = []
    
    /// Whether debug mode is enabled
    public let debugMode: Bool
    
    /// Creates a new AST pass manager
    /// 
    /// - Parameter debugMode: Whether to enable debug logging
    public init(debugMode: Bool = false) {
        self.debugMode = debugMode
    }
    
    /// Adds a pass to the execution pipeline
    /// 
    /// - Parameter pass: The pass to add
    public func addPass<T: ASTPass>(_ pass: T) {
        let passInfo = PassInfo(
            pass: pass,
            passType: T.self,
            name: String(describing: T.self)
        )
        passes.append(passInfo)
        
        if debugMode {
            print("[PassManager] Added pass: \(passInfo.name)")
        }
    }
    
    /// Runs all registered passes on the given AST
    /// 
    /// - Parameter node: The AST node to process
    /// - Returns: A collection of pass results
    /// - Throws: Any error encountered during pass execution
    public func runPasses(on node: SwiftCalcParser.Expression) throws -> ASTPassResults {
        if debugMode {
            print("[PassManager] Running \(passes.count) passes")
        }
        
        let results = ASTPassResults()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for (index, passInfo) in passes.enumerated() {
            if debugMode {
                print("[PassManager] Running pass \(index + 1)/\(passes.count): \(passInfo.name)")
            }
            
            // Execute the pass using type erasure
            let result = try executePass(passInfo.pass, on: node, with: results)
            results.addResult(result, for: passInfo.passType)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalDuration = endTime - startTime
        
        if debugMode {
            print("[PassManager] All passes completed in \(String(format: "%.4f", totalDuration))s")
        }
        
        return results
    }
    
    /// Executes a single pass using type erasure
    /// 
    /// - Parameters:
    ///   - pass: The pass to execute
    ///   - node: The AST node to process
    ///   - results: The current pass results for dependency resolution
    /// - Returns: The pass result
    /// - Throws: Any error encountered during execution
    private func executePass(_ pass: Any, on node: SwiftCalcParser.Expression, with results: ASTPassResults) throws -> Any {
        // Try to cast to a known pass type and execute
        if let numberPass = pass as? NumberTypeAnalysisPass {
            return try numberPass.run(on: node)
        }
        
        if let typePass = pass as? VariableTypeInferencePass {
            // Variable type inference pass requires number analysis results
            guard let numberAnalysis = results.getNumberTypeAnalysis() else {
                throw ASTPassError.invalidInput("VariableTypeInferencePass requires NumberTypeAnalysisPass to run first")
            }
            return try typePass.run(on: node, with: numberAnalysis)
        }
        
        // If we can't cast to a known type, this is an error
        throw ASTPassError.unsupportedNodeType("Unknown pass type: \(type(of: pass))")
    }
    
    /// Removes all registered passes
    public func clearPasses() {
        passes.removeAll()
        
        if debugMode {
            print("[PassManager] Cleared all passes")
        }
    }
    
    /// Gets the number of registered passes
    public var passCount: Int {
        return passes.count
    }
    
    /// Gets the names of all registered passes
    public var passNames: [String] {
        return passes.map { $0.name }
    }
}

/// Collection of results from AST pass execution
public class ASTPassResults {
    
    /// Dictionary storing results by pass type
    private var results: [String: Any] = [:]
    
    /// Creates a new empty results collection
    public init() {}
    
    /// Adds a result for a specific pass type
    /// 
    /// - Parameters:
    ///   - result: The result to store
    ///   - passType: The type of pass that produced the result
    internal func addResult(_ result: Any, for passType: Any.Type) {
        let key = String(describing: passType)
        results[key] = result
    }
    
    /// Gets the result for a specific pass type
    /// 
    /// - Parameter passType: The type of pass to get results for
    /// - Returns: The result, or nil if not found
    public func getResult<T>(for passType: T.Type) -> Any? {
        let key = String(describing: passType)
        return results[key]
    }
    
    /// Gets the number type analysis result if available
    /// 
    /// - Returns: The number type analysis result, or nil if not available
    public func getNumberTypeAnalysis() -> NumberTypeAnalysisResult? {
        return getResult(for: NumberTypeAnalysisPass.self) as? NumberTypeAnalysisResult
    }
    
    /// Gets the variable type inference result if available
    /// 
    /// - Returns: The variable type inference result, or nil if not available
    public func getVariableTypeInference() -> VariableTypeInferenceResult? {
        return getResult(for: VariableTypeInferencePass.self) as? VariableTypeInferenceResult
    }
    
    /// Gets all available result types
    public var availableResults: [String] {
        return Array(results.keys)
    }
    
    /// Checks if a result is available for a specific pass type
    /// 
    /// - Parameter passType: The pass type to check
    /// - Returns: true if a result is available
    public func hasResult<T>(for passType: T.Type) -> Bool {
        let key = String(describing: passType)
        return results[key] != nil
    }
}

/// Convenience methods for common pass combinations
public extension ASTPassManager {
    
    /// Adds the standard analysis passes
    /// 
    /// This includes:
    /// - Number type analysis
    /// - Variable type inference (depends on number type analysis)
    func addStandardAnalysisPasses() {
        addPass(NumberTypeAnalysisPass(debugMode: debugMode))
        addPass(VariableTypeInferencePass(debugMode: debugMode))
    }
    
    /// Creates a pass manager with standard analysis passes
    /// 
    /// - Parameter debugMode: Whether to enable debug mode
    /// - Returns: A configured pass manager
    static func withStandardAnalysis(debugMode: Bool = false) -> ASTPassManager {
        let manager = ASTPassManager(debugMode: debugMode)
        manager.addStandardAnalysisPasses()
        return manager
    }
}