import Foundation

/// Information about an inferred variable type
public struct VariableTypeInfo: Equatable {
    /// The name of the variable
    public let name: String
    
    /// The inferred type of the variable
    public let inferredType: NumberType
    
    /// The position where the variable was first assigned
    public let firstAssignmentPosition: Position
    
    /// The confidence level of the type inference (0.0 to 1.0)
    public let confidence: Double
    
    /// The reason for the type inference
    public let reason: String
    
    /// Creates new variable type information
    /// 
    /// - Parameters:
    ///   - name: The variable name
    ///   - inferredType: The inferred type
    ///   - firstAssignmentPosition: Position of first assignment
    ///   - confidence: Confidence level (0.0 to 1.0)
    ///   - reason: Reason for the inference
    public init(name: String, inferredType: NumberType, firstAssignmentPosition: Position, confidence: Double = 1.0, reason: String) {
        self.name = name
        self.inferredType = inferredType
        self.firstAssignmentPosition = firstAssignmentPosition
        self.confidence = confidence
        self.reason = reason
    }
}

/// Result of variable type inference containing all analyzed variables
public struct VariableTypeInferenceResult {
    /// All variables with their inferred types
    public let variables: [VariableTypeInfo]
    
    /// Count of variables inferred as integers
    public var integerVariableCount: Int {
        return variables.filter { $0.inferredType == .integer }.count
    }
    
    /// Count of variables inferred as floats
    public var floatVariableCount: Int {
        return variables.filter { $0.inferredType == .float }.count
    }
    
    /// Total count of analyzed variables
    public var totalVariableCount: Int {
        return variables.count
    }
    
    /// Creates a new inference result
    /// 
    /// - Parameter variables: The array of variable type information
    public init(variables: [VariableTypeInfo]) {
        self.variables = variables
    }
    
    /// Gets all variables of a specific type
    /// 
    /// - Parameter type: The type to filter by
    /// - Returns: Array of variables matching the specified type
    public func variables(ofType type: NumberType) -> [VariableTypeInfo] {
        return variables.filter { $0.inferredType == type }
    }
    
    /// Gets type information for a specific variable
    /// 
    /// - Parameter name: The variable name
    /// - Returns: The variable type info, or nil if not found
    public func typeInfo(for name: String) -> VariableTypeInfo? {
        return variables.first { $0.name == name }
    }
}

/// AST pass that infers variable types based on their usage and number type analysis
/// 
/// This pass analyzes variable assignments and expressions to determine whether
/// each variable should be typed as an integer or float. It uses type promotion
/// rules where:
/// - integer op integer = integer
/// - integer op float = float
/// - float op float = float
/// 
/// Example usage:
/// ```swift
/// let numberPass = NumberTypeAnalysisPass()
/// let numberResult = try numberPass.run(on: ast)
/// 
/// let typePass = VariableTypeInferencePass()
/// let typeResult = try typePass.run(on: ast, with: numberResult)
/// 
/// for variable in typeResult.variables {
///     print("\(variable.name): \(variable.inferredType) (\(variable.reason))")
/// }
/// ```
public class VariableTypeInferencePass: BaseASTPass<VariableTypeInferenceResult>, ASTVisitor {
    public typealias Result = VariableTypeInferenceResult
    
    /// The number type analysis results to use for inference
    private var numberAnalysis: NumberTypeAnalysisResult?
    
    /// Dictionary to track variable type information during analysis
    private var variableTypes: [String: VariableTypeInfo] = [:]
    
    /// Dictionary to track expression types during evaluation
    private var expressionTypes: [String: NumberType] = [:]
    
    /// Creates a new variable type inference pass
    /// 
    /// - Parameter debugMode: Whether to enable debug logging
    public init(debugMode: Bool = false) {
        super.init(passName: "VariableTypeInference", debugMode: debugMode)
    }
    
    /// Runs the variable type inference pass with number analysis results
    /// 
    /// - Parameters:
    ///   - node: The AST node to analyze
    ///   - numberAnalysis: The results from number type analysis
    /// - Returns: The variable type inference result
    /// - Throws: ASTPassError if analysis fails
    public func run(on node: SwiftCalcParser.Expression, with numberAnalysis: NumberTypeAnalysisResult) throws -> VariableTypeInferenceResult {
        self.numberAnalysis = numberAnalysis
        return try run(on: node)
    }
    
    /// Executes the variable type inference pass
    /// 
    /// - Parameter node: The AST node to analyze
    /// - Returns: The inference result containing all analyzed variables
    /// - Throws: ASTPassError if analysis fails
    public override func executePass(on node: SwiftCalcParser.Expression) throws -> VariableTypeInferenceResult {
        // Reset state for this pass execution
        variableTypes = [:]
        expressionTypes = [:]
        
        guard let numberAnalysis = self.numberAnalysis else {
            throw ASTPassError.invalidInput("Number type analysis results are required")
        }
        
        debugLog("Starting variable type inference with \(numberAnalysis.totalCount) number literals")
        
        // Traverse the AST and infer variable types
        _ = try node.accept(self)
        
        let variables = Array(variableTypes.values)
        
        debugLog("Inferred types for \(variables.count) variables")
        debugLog("Integer variables: \(variables.filter { $0.inferredType == .integer }.count)")
        debugLog("Float variables: \(variables.filter { $0.inferredType == .float }.count)")
        
        return VariableTypeInferenceResult(variables: variables)
    }
    
    // MARK: - ASTVisitor Implementation
    
    public func visit(_ node: BinaryOperation) throws -> VariableTypeInferenceResult {
        // First, analyze the operands
        _ = try node.left.accept(self)
        _ = try node.right.accept(self)
        
        // Determine the type of this binary operation
        let leftType = try inferExpressionType(node.left)
        let rightType = try inferExpressionType(node.right)
        
        // Apply type promotion rules
        let resultType = promoteTypes(leftType, rightType)
        
        // Store the result type for this expression
        let expressionKey = "\(node.position.line):\(node.position.column)"
        expressionTypes[expressionKey] = resultType
        
        debugLog("Binary operation \(node.operator) at \(node.position): \(leftType) \(node.operator) \(rightType) -> \(resultType)")
        
        return VariableTypeInferenceResult(variables: [])
    }
    
    public func visit(_ node: UnaryOperation) throws -> VariableTypeInferenceResult {
        // Analyze the operand
        _ = try node.operand.accept(self)
        
        // Unary operations preserve the type of their operand
        let operandType = try inferExpressionType(node.operand)
        
        let expressionKey = "\(node.position.line):\(node.position.column)"
        expressionTypes[expressionKey] = operandType
        
        debugLog("Unary operation \(node.operator) at \(node.position): \(operandType) -> \(operandType)")
        
        return VariableTypeInferenceResult(variables: [])
    }
    
    public func visit(_ node: Literal) throws -> VariableTypeInferenceResult {
        // Literals have their type determined by number analysis
        return VariableTypeInferenceResult(variables: [])
    }
    
    public func visit(_ node: Identifier) throws -> VariableTypeInferenceResult {
        // Identifiers are handled when we encounter their assignments
        return VariableTypeInferenceResult(variables: [])
    }
    
    public func visit(_ node: Assignment) throws -> VariableTypeInferenceResult {
        // First, analyze the value expression
        _ = try node.value.accept(self)
        
        // Get the target variable name
        let targetIdentifier = node.target
        
        // Infer the type of the assigned value
        let valueType = try inferExpressionType(node.value)
        
        // Create or update variable type information
        let variableName = targetIdentifier.name
        
        if let existingInfo = variableTypes[variableName] {
            // Variable already exists, check for type consistency
            if existingInfo.inferredType != valueType {
                // Type conflict - promote to float if one is float
                let promotedType = promoteTypes(existingInfo.inferredType, valueType)
                let reason = "Type promotion from \(existingInfo.inferredType) to \(promotedType) due to assignment of \(valueType)"
                
                variableTypes[variableName] = VariableTypeInfo(
                    name: variableName,
                    inferredType: promotedType,
                    firstAssignmentPosition: existingInfo.firstAssignmentPosition,
                    confidence: 0.8, // Lower confidence due to type promotion
                    reason: reason
                )
                
                debugLog("Variable \(variableName) type promoted to \(promotedType): \(reason)")
            }
        } else {
            // New variable
            let reason = "Inferred from assignment of \(valueType) expression"
            
            variableTypes[variableName] = VariableTypeInfo(
                name: variableName,
                inferredType: valueType,
                firstAssignmentPosition: node.position,
                confidence: 1.0,
                reason: reason
            )
            
            debugLog("Variable \(variableName) inferred as \(valueType): \(reason)")
        }
        
        return VariableTypeInferenceResult(variables: [])
    }
    
    public func visit(_ node: FunctionCall) throws -> VariableTypeInferenceResult {
        // Visit all function arguments
        for argument in node.arguments {
            _ = try argument.accept(self)
        }
        
        // Most mathematical functions return float
        let resultType: NumberType = .float
        let expressionKey = "\(node.position.line):\(node.position.column)"
        expressionTypes[expressionKey] = resultType
        
        debugLog("Function call \(node.name) at \(node.position) -> \(resultType)")
        
        return VariableTypeInferenceResult(variables: [])
    }
    
    public func visit(_ node: ParenthesizedExpression) throws -> VariableTypeInferenceResult {
        // Analyze the inner expression
        _ = try node.expression.accept(self)
        
        // Parentheses preserve the type of their inner expression
        let innerType = try inferExpressionType(node.expression)
        
        let expressionKey = "\(node.position.line):\(node.position.column)"
        expressionTypes[expressionKey] = innerType
        
        return VariableTypeInferenceResult(variables: [])
    }
    
    public func visitProgram(_ node: Program) throws -> VariableTypeInferenceResult {
        // Visit all statements in the program
        for statement in node.statements {
            _ = try statement.accept(self)
        }
        return VariableTypeInferenceResult(variables: [])
    }
    
    // MARK: - Type Inference Logic
    
    /// Infers the type of an expression based on its content and context
    /// 
    /// - Parameter expression: The expression to analyze
    /// - Returns: The inferred type of the expression
    /// - Throws: ASTPassError if type cannot be inferred
    private func inferExpressionType(_ expression: SwiftCalcParser.Expression) throws -> NumberType {
        switch expression {
        case let literal as Literal:
            return try inferLiteralType(literal)
            
        case let identifier as Identifier:
            return try inferIdentifierType(identifier)
            
        case let binaryOp as BinaryOperation:
            let leftType = try inferExpressionType(binaryOp.left)
            let rightType = try inferExpressionType(binaryOp.right)
            return promoteTypes(leftType, rightType)
            
        case let unaryOp as UnaryOperation:
            return try inferExpressionType(unaryOp.operand)
            
        case _ as FunctionCall:
            // Most mathematical functions return float
            return .float
            
        case let parenthesized as ParenthesizedExpression:
            return try inferExpressionType(parenthesized.expression)
            
        default:
            throw ASTPassError.unsupportedNodeType("Cannot infer type for expression type: \(type(of: expression))")
        }
    }
    
    /// Infers the type of a literal based on number analysis results
    /// 
    /// - Parameter literal: The literal node
    /// - Returns: The type of the literal
    /// - Throws: ASTPassError if type cannot be determined
    private func inferLiteralType(_ literal: Literal) throws -> NumberType {
        guard let numberAnalysis = self.numberAnalysis else {
            throw ASTPassError.internalError("Number analysis results not available")
        }
        
        // Find the literal in the number analysis results
        for numberInfo in numberAnalysis.numbers {
            if numberInfo.position == literal.position && numberInfo.value == literal.value {
                return numberInfo.type
            }
        }
        
        // Fallback: analyze the literal value directly
        return literal.value.contains(".") ? .float : .integer
    }
    
    /// Infers the type of an identifier based on its current known type
    /// 
    /// - Parameter identifier: The identifier node
    /// - Returns: The type of the identifier
    /// - Throws: ASTPassError if type cannot be determined
    private func inferIdentifierType(_ identifier: Identifier) throws -> NumberType {
        if let variableInfo = variableTypes[identifier.name] {
            return variableInfo.inferredType
        }
        
        // If we don't know the variable type yet, assume integer as default
        // This can happen with forward references or complex expressions
        debugLog("Unknown variable \(identifier.name) at \(identifier.position), assuming integer")
        return .integer
    }
    
    /// Applies type promotion rules to determine the result type of an operation
    /// 
    /// Rules:
    /// - integer op integer = integer
    /// - integer op float = float
    /// - float op float = float
    /// 
    /// - Parameters:
    ///   - type1: First operand type
    ///   - type2: Second operand type
    /// - Returns: The promoted result type
    private func promoteTypes(_ type1: NumberType, _ type2: NumberType) -> NumberType {
        switch (type1, type2) {
        case (.integer, .integer):
            return .integer
        case (.integer, .float), (.float, .integer), (.float, .float):
            return .float
        }
    }
}

/// Convenience methods for variable type inference
public extension SwiftCalcParser.Expression {
    
    /// Infers variable types in this expression using number analysis results
    /// 
    /// - Parameters:
    ///   - numberAnalysis: The results from number type analysis
    ///   - debugMode: Whether to enable debug logging
    /// - Returns: The variable type inference result
    /// - Throws: ASTPassError if inference fails
    func inferVariableTypes(with numberAnalysis: NumberTypeAnalysisResult, debugMode: Bool = false) throws -> VariableTypeInferenceResult {
        let pass = VariableTypeInferencePass(debugMode: debugMode)
        return try pass.run(on: self, with: numberAnalysis)
    }
}