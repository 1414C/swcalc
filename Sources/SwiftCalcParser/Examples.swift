import Foundation
import SwiftCalcTokenizer

/// Example usage patterns for the SwiftCalcParser
/// 
/// This file demonstrates various ways to use the parser for different
/// use cases, including basic parsing, AST traversal, error handling,
/// and integration with SwiftCalcTokenizer.
public struct ParserExamples {
    
    // MARK: - Basic Usage Examples
    
    /// Example 1: Basic parsing of a simple mathematical expression
    public static func basicParsingExample() {
        print("=== Basic Parsing Example ===")
        
        let input = "3.14 + x * 2"
        print("Input: \(input)")
        
        do {
            // Tokenize the input
            let tokenizer = Tokenizer(input: input)
            let tokens = try tokenizer.tokenize()
            
            // Parse the tokens into an AST
            let parser = Parser(tokens: tokens)
            let ast = try parser.parse()
            
            print("✅ Successfully parsed!")
            print("AST Type: \(type(of: ast))")
            
            // Use the string visitor to display the AST structure
            let stringVisitor = ASTStringVisitor()
            let astString = try ast.accept(stringVisitor)
            print("AST Structure: \(astString)")
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        print()
    }
    
    /// Example 2: Parsing expressions with operator precedence
    public static func operatorPrecedenceExample() {
        print("=== Operator Precedence Example ===")
        
        let expressions = [
            "2 + 3 * 4",        // Should be: 2 + (3 * 4)
            "2 * 3 + 4",        // Should be: (2 * 3) + 4
            "2 ^ 3 ^ 4",        // Should be: 2 ^ (3 ^ 4) - right associative
            "10 - 5 - 2",       // Should be: (10 - 5) - 2 - left associative
            "a = b = 5"         // Should be: a = (b = 5) - right associative
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                let stringVisitor = ASTStringVisitor()
                let astString = try ast.accept(stringVisitor)
                print("  Parsed as: \(astString)")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    /// Example 3: Parsing expressions with parentheses
    public static func parenthesesExample() {
        print("=== Parentheses Example ===")
        
        let expressions = [
            "(2 + 3) * 4",      // Parentheses override precedence
            "2 * (3 + 4)",      // Parentheses change evaluation order
            "((2 + 3) * 4)",    // Nested parentheses
            "(x + y) / (a - b)" // Multiple parenthesized groups
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                let stringVisitor = ASTStringVisitor()
                let astString = try ast.accept(stringVisitor)
                print("  Parsed as: \(astString)")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    /// Example 4: Parsing assignment expressions
    public static func assignmentExample() {
        print("=== Assignment Example ===")
        
        let expressions = [
            "x = 5",
            "result = a + b",
            "y = sin(x) * 2",
            "a = b = c = 10"    // Chained assignment (right-associative)
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                if let assignment = ast as? Assignment {
                    print("  Target: \(assignment.target.name)")
                    
                    let stringVisitor = ASTStringVisitor()
                    let valueString = try assignment.value.accept(stringVisitor)
                    print("  Value: \(valueString)")
                } else {
                    let stringVisitor = ASTStringVisitor()
                    let astString = try ast.accept(stringVisitor)
                    print("  Parsed as: \(astString)")
                }
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    /// Example 5: Parsing function calls
    public static func functionCallExample() {
        print("=== Function Call Example ===")
        
        let expressions = [
            "sin(x)",
            "max(a, b)",
            "pow(2, 3)",
            "f()",                  // No arguments
            "sin(cos(x))",          // Nested function calls
            "max(a + b, c * d)"     // Complex arguments
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                if let functionCall = ast as? FunctionCall {
                    print("  Function: \(functionCall.name)")
                    print("  Arguments: \(functionCall.arguments.count)")
                    
                    for (index, arg) in functionCall.arguments.enumerated() {
                        let stringVisitor = ASTStringVisitor()
                        let argString = try arg.accept(stringVisitor)
                        print("    Arg \(index + 1): \(argString)")
                    }
                } else {
                    let stringVisitor = ASTStringVisitor()
                    let astString = try ast.accept(stringVisitor)
                    print("  Parsed as: \(astString)")
                }
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    /// Example 6: Parsing unary operators
    public static func unaryOperatorExample() {
        print("=== Unary Operator Example ===")
        
        let expressions = [
            "-5",
            "-(x + y)",
            "--5",              // Double negative
            "2 * -3",           // Unary in binary expression
            "-sin(x)"           // Unary with function call
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                let stringVisitor = ASTStringVisitor()
                let astString = try ast.accept(stringVisitor)
                print("  Parsed as: \(astString)")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    // MARK: - AST Traversal and Analysis Examples
    
    /// Example 7: AST traversal using the visitor pattern
    public static func astTraversalExample() {
        print("=== AST Traversal Example ===")
        
        let input = "result = (a + b) * sin(x) - 2"
        print("Expression: \(input)")
        
        do {
            let tokenizer = Tokenizer(input: input)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens)
            let ast = try parser.parse()
            
            // Use different visitors to analyze the AST
            
            // 1. String representation
            let stringVisitor = ASTStringVisitor()
            let astString = try ast.accept(stringVisitor)
            print("  String representation: \(astString)")
            
            // 2. Node count
            let nodeCountVisitor = ASTNodeCountVisitor()
            let nodeCount = try ast.accept(nodeCountVisitor)
            print("  Total nodes: \(nodeCount)")
            
            // 3. Maximum depth
            let depthVisitor = ASTDepthVisitor()
            let maxDepth = try ast.accept(depthVisitor)
            print("  Maximum depth: \(maxDepth)")
            
            // 4. Analysis information
            let identifiers = ASTAnalysis.extractIdentifiers(from: ast)
            let literals = ASTAnalysis.extractLiterals(from: ast)
            let operators = ASTAnalysis.extractOperators(from: ast)
            let functionCalls = ASTAnalysis.extractFunctionCalls(from: ast)
            let hasAssignments = ASTAnalysis.containsAssignments(ast)
            
            print("  Identifiers: \(Array(identifiers).sorted())")
            print("  Literals: \(literals)")
            print("  Operators: \(operators)")
            print("  Function calls: \(functionCalls.map { "\($0.name)(\($0.argumentCount))" })")
            print("  Has assignments: \(hasAssignments)")
            
        } catch {
            print("  ❌ Error: \(error)")
        }
        
        print()
    }
    
    /// Example 8: Custom visitor implementation
    public static func customVisitorExample() {
        print("=== Custom Visitor Example ===")
        
        // Define a custom visitor that collects all variable names
        struct VariableCollector: ASTVisitor {
            typealias Result = Set<String>
            
            func visit(_ node: BinaryOperation) throws -> Set<String> {
                var variables = try node.left.accept(self)
                variables.formUnion(try node.right.accept(self))
                return variables
            }
            
            func visit(_ node: UnaryOperation) throws -> Set<String> {
                return try node.operand.accept(self)
            }
            
            func visit(_ node: Literal) throws -> Set<String> {
                return []
            }
            
            func visit(_ node: Identifier) throws -> Set<String> {
                return [node.name]
            }
            
            func visit(_ node: Assignment) throws -> Set<String> {
                var variables = Set([node.target.name])
                variables.formUnion(try node.value.accept(self))
                return variables
            }
            
            func visit(_ node: FunctionCall) throws -> Set<String> {
                var variables = Set<String>()
                for arg in node.arguments {
                    variables.formUnion(try arg.accept(self))
                }
                return variables
            }
            
            func visit(_ node: ParenthesizedExpression) throws -> Set<String> {
                return try node.expression.accept(self)
            }
            
            func visitProgram(_ node: Program) throws -> Set<String> {
                var variables = Set<String>()
                for statement in node.statements {
                    variables.formUnion(try statement.accept(self))
                }
                return variables
            }
        }
        
        let expressions = [
            "x + y",
            "result = a * b + c",
            "sin(x) + cos(y) - z"
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                let variableCollector = VariableCollector()
                let variables = try ast.accept(variableCollector)
                print("  Variables used: \(Array(variables).sorted())")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    // MARK: - Error Handling Examples
    
    /// Example 9: Handling syntax errors
    public static func syntaxErrorHandlingExample() {
        print("=== Syntax Error Handling Example ===")
        
        let invalidExpressions = [
            "2 + + 3",          // Missing operand
            "(2 + 3",           // Unmatched parenthesis
            "5 = x",            // Invalid assignment target
            "sin(",             // Incomplete function call
            "x + * y"           // Invalid operator sequence
        ]
        
        for expression in invalidExpressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                print("  ✅ Unexpectedly succeeded!")
                let stringVisitor = ASTStringVisitor()
                let astString = try ast.accept(stringVisitor)
                print("  Result: \(astString)")
                
            } catch let error as ParseError {
                print("  ❌ Parse Error: \(error.localizedDescription)")
            } catch {
                print("  ❌ Unexpected Error: \(error)")
            }
            
            print()
        }
    }
    
    /// Example 10: Error recovery mode
    public static func errorRecoveryExample() {
        print("=== Error Recovery Example ===")
        
        let expressions = [
            "2 + + 3 * 4",      // Error in the middle
            "x = 5 + * y",      // Multiple potential errors
            "(2 + 3 * 4"        // Unmatched parenthesis
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            
            let tokenizer = Tokenizer(input: expression)
            do {
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens, enableErrorRecovery: true)
                let result = parser.parseWithErrorRecovery()
                
                if let ast = result.expression {
                    print("  ✅ Partial parse succeeded")
                    let stringVisitor = ASTStringVisitor()
                    let astString = try ast.accept(stringVisitor)
                    print("  Result: \(astString)")
                } else {
                    print("  ❌ Parse failed completely")
                }
                
                if !result.errors.isEmpty {
                    print("  Errors found:")
                    for error in result.errors {
                        print("    - \(error.localizedDescription)")
                    }
                }
                
            } catch {
                print("  ❌ Tokenization Error: \(error)")
            }
            
            print()
        }
    }
    
    /// Example 11: Handling tokenizer errors
    public static func tokenizerErrorHandlingExample() {
        print("=== Tokenizer Error Handling Example ===")
        
        let invalidInputs = [
            "3 + @ - 5",        // Invalid character
            "3.14.159 + 2",     // Malformed number
            "x = 5 & y"         // Invalid character in assignment
        ]
        
        for input in invalidInputs {
            print("Input: \(input)")
            
            do {
                let tokenizer = Tokenizer(input: input)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                print("  ✅ Unexpectedly succeeded!")
                let stringVisitor = ASTStringVisitor()
                let astString = try ast.accept(stringVisitor)
                print("  Result: \(astString)")
                
            } catch let error as ParseError {
                switch error {
                case .tokenizerError(let tokenizerError, let position):
                    print("  ❌ Tokenizer Error at line \(position.line), column \(position.column):")
                    print("    \(tokenizerError.localizedDescription)")
                default:
                    print("  ❌ Parse Error: \(error.localizedDescription)")
                }
            } catch {
                print("  ❌ Unexpected Error: \(error)")
            }
            
            print()
        }
    }
    
    // MARK: - Advanced Usage Examples
    
    /// Example 12: Complex expression parsing
    public static func complexExpressionExample() {
        print("=== Complex Expression Example ===")
        
        let complexExpressions = [
            "result = (a + b) * sin(x) / cos(y) - pow(2, 3)",
            "matrix = ((a * b) + (c * d)) / ((e * f) - (g * h))",
            "final = max(min(x, y), abs(z)) + sqrt(a ^ 2 + b ^ 2)"
        ]
        
        for expression in complexExpressions {
            print("Expression: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                // Analyze the complex expression
                let identifiers = ASTAnalysis.extractIdentifiers(from: ast)
                let functionCalls = ASTAnalysis.extractFunctionCalls(from: ast)
                let operators = ASTAnalysis.extractOperators(from: ast)
                let nodeCountVisitor = ASTNodeCountVisitor()
                let nodeCount = try ast.accept(nodeCountVisitor)
                let depthVisitor = ASTDepthVisitor()
                let maxDepth = try ast.accept(depthVisitor)
                
                print("  ✅ Successfully parsed!")
                print("  Complexity metrics:")
                print("    Total nodes: \(nodeCount)")
                print("    Maximum depth: \(maxDepth)")
                print("    Identifiers: \(identifiers.count)")
                print("    Function calls: \(functionCalls.count)")
                print("    Binary operations: \(operators.values.reduce(0, +))")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    /// Example 13: Performance benchmarking
    public static func performanceBenchmarkExample() {
        print("=== Performance Benchmark Example ===")
        
        // Generate increasingly complex expressions
        var testCases = [
            ("Simple", "x + y"),
            ("Medium", "a * b + c * d - e / f"),
            ("Complex", "(a + b) * (c - d) / (e + f) - (g * h)"),
            ("Very Complex", "sin(x) + cos(y) * tan(z) - sqrt(a ^ 2 + b ^ 2) / log(c)")
        ]
        
        // Generate a large expression
        var largeExpression = "result = "
        for i in 1...100 {
            if i > 1 {
                largeExpression += " + "
            }
            largeExpression += "x\(i) * y\(i)"
        }
        testCases.append(("Large", largeExpression))
        
        for (name, expression) in testCases {
            print("\(name) Expression:")
            print("  Length: \(expression.count) characters")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                // Tokenization phase
                let tokenizeStart = CFAbsoluteTimeGetCurrent()
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let tokenizeEnd = CFAbsoluteTimeGetCurrent()
                
                // Parsing phase
                let parseStart = CFAbsoluteTimeGetCurrent()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                let parseEnd = CFAbsoluteTimeGetCurrent()
                
                // Analysis phase
                let analysisStart = CFAbsoluteTimeGetCurrent()
                let nodeCountVisitor = ASTNodeCountVisitor()
                let nodeCount = try ast.accept(nodeCountVisitor)
                let analysisEnd = CFAbsoluteTimeGetCurrent()
                
                let totalTime = parseEnd - startTime
                let tokenizeTime = tokenizeEnd - tokenizeStart
                let parseTime = parseEnd - parseStart
                let analysisTime = analysisEnd - analysisStart
                
                print("  ✅ Success!")
                print("  Tokens: \(tokens.count - 1) (excluding EOF)")
                print("  AST nodes: \(nodeCount)")
                print("  Timing:")
                print("    Tokenization: \(String(format: "%.4f", tokenizeTime))s")
                print("    Parsing: \(String(format: "%.4f", parseTime))s")
                print("    Analysis: \(String(format: "%.4f", analysisTime))s")
                print("    Total: \(String(format: "%.4f", totalTime))s")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
            
            print()
        }
    }
    
    // MARK: - Integration Examples
    
    /// Example 14: Building a simple calculator
    public static func simpleCalculatorExample() {
        print("=== Simple Calculator Example ===")
        
        // This example shows how to use the parser as part of a larger system
        struct SimpleCalculator {
            private var variables: [String: Double] = [:]
            
            mutating func evaluate(_ input: String) -> Result<Double, Error> {
                do {
                    // Parse the input
                    let tokenizer = Tokenizer(input: input)
                    let tokens = try tokenizer.tokenize()
                    let parser = Parser(tokens: tokens)
                    let ast = try parser.parse()
                    
                    // Evaluate the AST
                    return .success(try evaluateExpression(ast))
                    
                } catch {
                    return .failure(error)
                }
            }
            
            private mutating func evaluateExpression(_ expr: Expression) throws -> Double {
                switch expr {
                case let literal as Literal:
                    guard let value = Double(literal.value) else {
                        throw NSError(domain: "EvaluationError", code: 1, 
                                    userInfo: [NSLocalizedDescriptionKey: "Invalid number: \(literal.value)"])
                    }
                    return value
                    
                case let identifier as Identifier:
                    guard let value = variables[identifier.name] else {
                        throw NSError(domain: "EvaluationError", code: 2,
                                    userInfo: [NSLocalizedDescriptionKey: "Undefined variable: \(identifier.name)"])
                    }
                    return value
                    
                case let binaryOp as BinaryOperation:
                    let left = try evaluateExpression(binaryOp.left)
                    let right = try evaluateExpression(binaryOp.right)
                    
                    switch binaryOp.operator {
                    case .plus: return left + right
                    case .minus: return left - right
                    case .multiply: return left * right
                    case .divide: 
                        guard right != 0 else {
                            throw NSError(domain: "EvaluationError", code: 3,
                                        userInfo: [NSLocalizedDescriptionKey: "Division by zero"])
                        }
                        return left / right
                    case .modulo: return left.truncatingRemainder(dividingBy: right)
                    case .power: return pow(left, right)
                    }
                    
                case let unaryOp as UnaryOperation:
                    let operand = try evaluateExpression(unaryOp.operand)
                    switch unaryOp.operator {
                    case .minus: return -operand
                    }
                    
                case let assignment as Assignment:
                    let value = try evaluateExpression(assignment.value)
                    variables[assignment.target.name] = value
                    return value
                    
                case let parenExpr as ParenthesizedExpression:
                    return try evaluateExpression(parenExpr.expression)
                    
                case let functionCall as FunctionCall:
                    // Simple function implementations
                    switch functionCall.name {
                    case "sin":
                        guard functionCall.arguments.count == 1 else {
                            throw NSError(domain: "EvaluationError", code: 4,
                                        userInfo: [NSLocalizedDescriptionKey: "sin() requires exactly 1 argument"])
                        }
                        let arg = try evaluateExpression(functionCall.arguments[0])
                        return sin(arg)
                        
                    case "cos":
                        guard functionCall.arguments.count == 1 else {
                            throw NSError(domain: "EvaluationError", code: 4,
                                        userInfo: [NSLocalizedDescriptionKey: "cos() requires exactly 1 argument"])
                        }
                        let arg = try evaluateExpression(functionCall.arguments[0])
                        return cos(arg)
                        
                    case "sqrt":
                        guard functionCall.arguments.count == 1 else {
                            throw NSError(domain: "EvaluationError", code: 4,
                                        userInfo: [NSLocalizedDescriptionKey: "sqrt() requires exactly 1 argument"])
                        }
                        let arg = try evaluateExpression(functionCall.arguments[0])
                        return sqrt(arg)
                        
                    default:
                        throw NSError(domain: "EvaluationError", code: 5,
                                    userInfo: [NSLocalizedDescriptionKey: "Unknown function: \(functionCall.name)"])
                    }
                    
                default:
                    throw NSError(domain: "EvaluationError", code: 6,
                                userInfo: [NSLocalizedDescriptionKey: "Unsupported expression type"])
                }
            }
        }
        
        var calculator = SimpleCalculator()
        
        let testExpressions = [
            "3 + 4 * 2",
            "x = 10",
            "y = x + 5",
            "result = x * y",
            "sin(3.14159 / 2)",
            "sqrt(x ^ 2 + y ^ 2)"
        ]
        
        for expression in testExpressions {
            print("Expression: \(expression)")
            
            switch calculator.evaluate(expression) {
            case .success(let result):
                print("  ✅ Result: \(result)")
            case .failure(let error):
                print("  ❌ Error: \(error.localizedDescription)")
            }
            
            print()
        }
    }
    
    // MARK: - Main Example Runner
    
    /// Runs all examples to demonstrate parser capabilities
    public static func runAllExamples() {
        print("SwiftCalcParser Usage Examples")
        print("==============================\n")
        
        basicParsingExample()
        operatorPrecedenceExample()
        parenthesesExample()
        assignmentExample()
        functionCallExample()
        unaryOperatorExample()
        astTraversalExample()
        customVisitorExample()
        syntaxErrorHandlingExample()
        errorRecoveryExample()
        tokenizerErrorHandlingExample()
        complexExpressionExample()
        performanceBenchmarkExample()
        simpleCalculatorExample()
        parserDebuggingExample()
        errorRecoveryDebuggingExample()
        
        print("All examples completed!")
    }
    
    /// Example: Parser state management and debugging
    public static func parserDebuggingExample() {
        print("=== Parser Debugging Example ===")
        
        let input = "result = sin(x) + 2 * (y - 1)"
        print("Input: \(input)")
        
        do {
            // Tokenize the input
            let tokenizer = Tokenizer(input: input)
            let tokens = try tokenizer.tokenize()
            
            // Create parser with debug mode enabled
            let parser = Parser(tokens: tokens, enableErrorRecovery: false, enableDebugMode: true)
            
            print("Debug mode enabled: \(parser.isDebugModeEnabled())")
            
            // Parse the expression
            let ast = try parser.parse()
            
            print("✅ Successfully parsed!")
            
            // Display parser state information
            print("\n--- Parser State ---")
            let state = parser.getParserState()
            for (key, value) in state.sorted(by: { $0.key < $1.key }) {
                print("\(key): \(value)")
            }
            
            // Display operation history
            print("\n--- Operation History ---")
            let history = parser.getOperationHistory()
            for operation in history.prefix(10) { // Show first 10 operations
                print(operation)
            }
            
            // Display parser statistics
            print("\n--- Parser Statistics ---")
            let stats = parser.getParserStatistics()
            for (key, value) in stats.sorted(by: { $0.key < $1.key }) {
                print("\(key): \(value)")
            }
            
            // Display position summary
            print("\n--- Position Summary ---")
            print(parser.getPositionSummary())
            
            // Use AST analysis to get more information
            print("\n--- AST Analysis ---")
            let nodeCount = try ASTAnalysis.countNodes(in: ast)
            let depth = try ASTAnalysis.calculateDepth(of: ast)
            let complexity = try ASTAnalysis.calculateComplexity(of: ast)
            let identifiers = ASTAnalysis.extractIdentifiers(from: ast)
            
            print("Node count: \(nodeCount)")
            print("AST depth: \(depth)")
            print("Complexity score: \(complexity)")
            print("Identifiers used: \(identifiers.sorted())")
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        print()
    }
    
    /// Example: Parser debugging with error recovery
    public static func errorRecoveryDebuggingExample() {
        print("=== Error Recovery Debugging Example ===")
        
        let input = "x = 2 + + 3 * y" // Invalid syntax (double plus)
        print("Input: \(input)")
        
        do {
            // Tokenize the input
            let tokenizer = Tokenizer(input: input)
            let tokens = try tokenizer.tokenize()
            
            // Create parser with both error recovery and debug mode enabled
            let parser = Parser(tokens: tokens, enableErrorRecovery: true, enableDebugMode: true)
            
            // Parse with error recovery
            let result = parser.parseWithErrorRecovery()
            
            if let ast = result.expression {
                print("✅ Partial parsing successful!")
                let stringVisitor = ASTStringVisitor()
                let astString = try ast.accept(stringVisitor)
                print("Parsed AST: \(astString)")
            } else {
                print("❌ Could not parse any valid expression")
            }
            
            // Display errors encountered
            print("\n--- Errors Encountered ---")
            for (index, error) in result.errors.enumerated() {
                print("\(index + 1). \(error)")
            }
            
            // Display parser statistics
            print("\n--- Parser Statistics ---")
            let stats = parser.getParserStatistics()
            print("Total tokens: \(stats["totalTokens"] ?? "unknown")")
            print("Tokens consumed: \(stats["tokensConsumed"] ?? "unknown")")
            print("Error count: \(stats["errorCount"] ?? "unknown")")
            print("Max recursion depth: \(stats["maxRecursionDepth"] ?? "unknown")")
            
            // Display operation history to see recovery attempts
            print("\n--- Recent Operations ---")
            let history = parser.getOperationHistory()
            for operation in history.suffix(5) { // Show last 5 operations
                print(operation)
            }
            
        } catch {
            print("❌ Unexpected error: \(error)")
        }
        
        print()
    }
    
    // MARK: - Debugging and Introspection Examples
    
    /// Example: Comprehensive AST debugging and analysis
    public static func astDebuggingExample() {
        print("=== AST Debugging Example ===")
        
        let input = "result = sin(x + 2) * (y - 1)"
        print("Input: \(input)")
        
        do {
            // Parse the expression
            let tokenizer = Tokenizer(input: input)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens)
            let ast = try parser.parse()
            
            print("\n1. Basic String Representation:")
            let stringVisitor = ASTStringVisitor()
            let basicString = try ast.accept(stringVisitor)
            print("   \(basicString)")
            
            print("\n2. Debug Representation (with positions and types):")
            let debugString = try Parser.debugAST(ast)
            print(debugString)
            
            print("\n3. Tree Visualization:")
            let treeVisualization = try ast.visualizeTree()
            print(treeVisualization)
            
            print("\n4. Analysis Report:")
            let analysisReport = try ASTAnalysis.generateAnalysisReport(for: ast)
            print(analysisReport)
            
            print("5. JSON Serialization:")
            let jsonString = try ast.toJSON()
            print(jsonString)
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        print()
    }
    
    /// Example: Advanced parser state debugging and introspection
    public static func advancedParserDebuggingExample() {
        print("=== Advanced Parser Debugging Example ===")
        
        let input = "a = b + c * d"
        print("Input: \(input)")
        
        do {
            // Create parser with debug mode enabled
            let tokenizer = Tokenizer(input: input)
            let tokens = try tokenizer.tokenize()
            let parser = Parser(tokens: tokens, enableErrorRecovery: false, enableDebugMode: true)
            
            print("\nParser state before parsing:")
            let initialDebugInfo = parser.getDebugInfo()
            print("  Current index: \(initialDebugInfo["currentIndex"] ?? "unknown")")
            print("  Total tokens: \(initialDebugInfo["totalTokens"] ?? "unknown")")
            print("  Debug mode: \(initialDebugInfo["debugMode"] ?? "unknown")")
            
            // Parse the expression
            let _ = try parser.parse()
            
            print("\nParser state after parsing:")
            let finalDebugInfo = parser.getDebugInfo()
            print("  Current index: \(finalDebugInfo["currentIndex"] ?? "unknown")")
            print("  Operations performed: \((finalDebugInfo["parserState"] as? [String: Any])?["operationCount"] ?? "unknown")")
            print("  Max depth reached: \((finalDebugInfo["parserState"] as? [String: Any])?["maxDepthReached"] ?? "unknown")")
            
            print("\nParsing Statistics:")
            let stats = parser.getParsingStatistics()
            for (key, value) in stats {
                print("  \(key): \(value)")
            }
            
            print("\nParsing Summary:")
            let summary = parser.getParsingSummary()
            print(summary)
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        print()
    }
    
    /// Example: AST serialization and deserialization
    public static func astSerializationExample() {
        print("=== AST Serialization Example ===")
        
        let expressions = [
            "42",
            "x + y",
            "func(a, b, c)",
            "result = (x + y) * z"
        ]
        
        for expression in expressions {
            print("\nExpression: \(expression)")
            
            do {
                // Parse the expression
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens)
                let ast = try parser.parse()
                
                // Serialize to dictionary
                let serialized = try ast.serialize()
                print("Serialized keys: \(serialized.keys.sorted())")
                
                // Convert to JSON (pretty-printed)
                let prettyJSON = try ast.toJSON()
                print("Pretty JSON:")
                print(prettyJSON.split(separator: "\n").map { "  \($0)" }.joined(separator: "\n"))
                
                // Convert to compact JSON
                let compactJSON = try ast.toCompactJSON()
                print("Compact JSON: \(compactJSON)")
                
            } catch {
                print("❌ Error: \(error)")
            }
        }
        
        print()
    }
    
    /// Example: Advanced error recovery and debugging
    public static func advancedErrorRecoveryDebuggingExample() {
        print("=== Advanced Error Recovery Debugging Example ===")
        
        let invalidExpressions = [
            "2 + + 3",           // Double operator
            "(2 + 3",            // Unmatched parenthesis
            "5 = x",             // Invalid assignment target
            "func(",             // Incomplete function call
        ]
        
        for expression in invalidExpressions {
            print("\nTesting: \(expression)")
            
            do {
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens, enableErrorRecovery: true, enableDebugMode: true)
                
                // Try parsing with error recovery
                let result = parser.parseWithErrorRecovery()
                
                if let ast = result.expression {
                    print("✅ Partial AST recovered:")
                    let debugString = try Parser.debugAST(ast, includePositions: true, includeTypes: false)
                    print(debugString)
                } else {
                    print("❌ No AST could be recovered")
                }
                
                print("Errors encountered (\(result.errors.count)):")
                for (index, error) in result.errors.enumerated() {
                    print("  \(index + 1). \(error.localizedDescription)")
                }
                
                print("Parser Summary:")
                let summary = parser.getParsingSummary()
                print(summary.split(separator: "\n").map { "  \($0)" }.joined(separator: "\n"))
                
            } catch {
                print("❌ Tokenizer error: \(error)")
            }
        }
        
        print()
    }
    
    /// Example: Performance analysis with debugging
    public static func performanceDebuggingExample() {
        print("=== Performance Debugging Example ===")
        
        // Create increasingly complex expressions
        let expressions = [
            "x",
            "x + y",
            "x + y * z",
            "(x + y) * (z - w)",
            "func(a, b) + func(c, d) * func(e, f)",
            "result = func1(x + y) * func2(z - w) + func3(a, b, c)"
        ]
        
        for expression in expressions {
            print("\nAnalyzing: \(expression)")
            
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Parse with debug mode
                let tokenizer = Tokenizer(input: expression)
                let tokens = try tokenizer.tokenize()
                let parser = Parser(tokens: tokens, enableDebugMode: true)
                let ast = try parser.parse()
                
                let parseTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Get complexity metrics
                let nodeCount = try ASTAnalysis.countNodes(in: ast)
                let depth = try ASTAnalysis.calculateDepth(of: ast)
                let complexity = try ASTAnalysis.calculateComplexity(of: ast)
                
                // Get parser statistics
                let stats = parser.getParsingStatistics()
                
                print("  Parse time: \(String(format: "%.4f", parseTime * 1000)) ms")
                print("  Nodes: \(nodeCount), Depth: \(depth), Complexity: \(complexity)")
                print("  Operations: \(stats["operationCount"] ?? "unknown")")
                print("  Max depth reached: \(stats["maxDepthReached"] ?? "unknown")")
                
            } catch {
                print("  ❌ Error: \(error)")
            }
        }
        
        print()
    }
    
    /// Runs all debugging examples
    public static func runAllDebuggingExamples() {
        print("🔍 Running All Debugging Examples\n")
        
        astDebuggingExample()
        advancedParserDebuggingExample()
        astSerializationExample()
        advancedErrorRecoveryDebuggingExample()
        performanceDebuggingExample()
        
        print("✅ All debugging examples completed!")
    }
}