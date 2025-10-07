import Foundation

/// Represents the type of a numeric value
public enum NumberType: Equatable, CustomStringConvertible {
    /// Integer number (no decimal point)
    case integer
    
    /// Floating-point number (has decimal point)
    case float
    
    public var description: String {
        switch self {
        case .integer:
            return "integer"
        case .float:
            return "float"
        }
    }
}

/// Information about numeric literals found in the AST
public struct NumberTypeInfo: Equatable {
    /// The original string value of the number
    public let value: String
    
    /// The determined type of the number
    public let type: NumberType
    
    /// The position of the number in the source code
    public let position: Position
    
    /// The parsed numeric value as a Double
    public let numericValue: Double?
    
    /// Creates new number type information
    /// 
    /// - Parameters:
    ///   - value: The original string value
    ///   - type: The determined number type
    ///   - position: The source position
    ///   - numericValue: The parsed numeric value
    public init(value: String, type: NumberType, position: Position, numericValue: Double? = nil) {
        self.value = value
        self.type = type
        self.position = position
        self.numericValue = numericValue
    }
}

/// Result of number type analysis containing all found numeric literals
public struct NumberTypeAnalysisResult {
    /// All numeric literals found in the AST with their type information
    public let numbers: [NumberTypeInfo]
    
    /// Count of integer literals
    public var integerCount: Int {
        return numbers.filter { $0.type == .integer }.count
    }
    
    /// Count of floating-point literals
    public var floatCount: Int {
        return numbers.filter { $0.type == .float }.count
    }
    
    /// Total count of numeric literals
    public var totalCount: Int {
        return numbers.count
    }
    
    /// Creates a new analysis result
    /// 
    /// - Parameter numbers: The array of number type information
    public init(numbers: [NumberTypeInfo]) {
        self.numbers = numbers
    }
    
    /// Gets all numbers of a specific type
    /// 
    /// - Parameter type: The number type to filter by
    /// - Returns: Array of numbers matching the specified type
    public func numbers(ofType type: NumberType) -> [NumberTypeInfo] {
        return numbers.filter { $0.type == type }
    }
}

/// AST pass that analyzes numeric literals to determine if they are integers or floats
/// 
/// This pass traverses the AST and examines all numeric literals, determining
/// whether each represents an integer or floating-point value based on the
/// presence of a decimal point in the original string representation.
/// 
/// Example usage:
/// ```swift
/// let pass = NumberTypeAnalysisPass()
/// let result = try pass.run(on: ast)
/// 
/// print("Found \(result.integerCount) integers and \(result.floatCount) floats")
/// for number in result.numbers {
///     print("\(number.value) is a \(number.type) at \(number.position)")
/// }
/// ```
public class NumberTypeAnalysisPass: BaseASTPass<NumberTypeAnalysisResult>, ASTVisitor {
    public typealias Result = NumberTypeAnalysisResult
    
    /// Array to collect number information during traversal
    private var collectedNumbers: [NumberTypeInfo] = []
    
    /// Creates a new number type analysis pass
    /// 
    /// - Parameter debugMode: Whether to enable debug logging
    public init(debugMode: Bool = false) {
        super.init(passName: "NumberTypeAnalysis", debugMode: debugMode)
    }
    
    /// Executes the number type analysis pass
    /// 
    /// - Parameter node: The AST node to analyze
    /// - Returns: The analysis result containing all found numbers
    /// - Throws: ASTPassError if analysis fails
    public override func executePass(on node: SwiftCalcParser.Expression) throws -> NumberTypeAnalysisResult {
        // Reset collected numbers for this pass execution
        collectedNumbers = []
        
        debugLog("Starting number type analysis")
        
        // Traverse the AST and collect number information
        _ = try node.accept(self)
        
        debugLog("Found \(collectedNumbers.count) numeric literals")
        debugLog("Integers: \(collectedNumbers.filter { $0.type == .integer }.count)")
        debugLog("Floats: \(collectedNumbers.filter { $0.type == .float }.count)")
        
        return NumberTypeAnalysisResult(numbers: collectedNumbers)
    }
    
    // MARK: - ASTVisitor Implementation
    
    public func visit(_ node: BinaryOperation) throws -> NumberTypeAnalysisResult {
        _ = try node.left.accept(self)
        _ = try node.right.accept(self)
        return NumberTypeAnalysisResult(numbers: [])
    }
    
    public func visit(_ node: UnaryOperation) throws -> NumberTypeAnalysisResult {
        _ = try node.operand.accept(self)
        return NumberTypeAnalysisResult(numbers: [])
    }
    
    public func visit(_ node: Literal) throws -> NumberTypeAnalysisResult {
        // Analyze the literal to determine its type
        let numberType = determineNumberType(from: node.value)
        let numericValue = Double(node.value)
        
        let numberInfo = NumberTypeInfo(
            value: node.value,
            type: numberType,
            position: node.position,
            numericValue: numericValue
        )
        
        collectedNumbers.append(numberInfo)
        
        debugLog("Found \(numberType) literal: \(node.value) at \(node.position)")
        
        return NumberTypeAnalysisResult(numbers: [numberInfo])
    }
    
    public func visit(_ node: Identifier) throws -> NumberTypeAnalysisResult {
        // Identifiers don't contain numeric literals
        return NumberTypeAnalysisResult(numbers: [])
    }
    
    public func visit(_ node: Assignment) throws -> NumberTypeAnalysisResult {
        _ = try node.target.accept(self)
        _ = try node.value.accept(self)
        return NumberTypeAnalysisResult(numbers: [])
    }
    
    public func visit(_ node: FunctionCall) throws -> NumberTypeAnalysisResult {
        // Visit all function arguments
        for argument in node.arguments {
            _ = try argument.accept(self)
        }
        return NumberTypeAnalysisResult(numbers: [])
    }
    
    public func visit(_ node: ParenthesizedExpression) throws -> NumberTypeAnalysisResult {
        _ = try node.expression.accept(self)
        return NumberTypeAnalysisResult(numbers: [])
    }
    
    public func visitProgram(_ node: Program) throws -> NumberTypeAnalysisResult {
        // Visit all statements in the program
        for statement in node.statements {
            _ = try statement.accept(self)
        }
        return NumberTypeAnalysisResult(numbers: [])
    }
    
    // MARK: - Number Type Analysis
    
    /// Determines the number type from a string representation
    /// 
    /// This method analyzes the string representation of a numeric literal
    /// to determine whether it represents an integer or floating-point value.
    /// The determination is based on the presence of a decimal point.
    /// 
    /// - Parameter value: The string representation of the number
    /// - Returns: The determined number type
    private func determineNumberType(from value: String) -> NumberType {
        // Check if the string contains a decimal point
        if value.contains(".") {
            return .float
        } else {
            return .integer
        }
    }
}

/// Convenience methods for number type analysis
public extension Expression {
    
    /// Analyzes this expression for numeric literal types
    /// 
    /// - Parameter debugMode: Whether to enable debug logging
    /// - Returns: The analysis result
    /// - Throws: ASTPassError if analysis fails
    func analyzeNumberTypes(debugMode: Bool = false) throws -> NumberTypeAnalysisResult {
        let pass = NumberTypeAnalysisPass(debugMode: debugMode)
        return try pass.run(on: self)
    }
}