import Foundation
import SwiftCalcTokenizer
import SwiftCalcParser

// Disambiguate Expression type
typealias CalcExpression = SwiftCalcParser.Expression

/// SwiftCalc Demo - Command Line Calculator Parser
/// 
/// This program demonstrates the use of SwiftCalcTokenizer and SwiftCalcParser
/// by reading a text file containing calculator expressions, tokenizing the content,
/// and parsing it into an Abstract Syntax Tree (AST).
///
/// Usage: swift-calc-demo <input-file>
/// 
/// The program will:
/// 1. Read the input file
/// 2. Tokenize the content and display tokens
/// 3. Parse the tokens and display the resulting AST
/// 4. Show additional analysis information

func main() {
    // Parse command line arguments
    let arguments = CommandLine.arguments
    
    guard arguments.count == 2 else {
        printUsage()
        exit(1)
    }
    
    let inputFilePath = arguments[1]
    
    do {
        // Read the input file
        print("📖 Reading input file: \(inputFilePath)")
        let content = try String(contentsOfFile: inputFilePath, encoding: .utf8)
        print("📄 File content:")
        print("─" * 50)
        print(content)
        print("─" * 50)
        print()
        
        // Tokenize the content
        print("🔍 Tokenizing...")
        let tokenizer = Tokenizer(input: content)
        let tokens = try tokenizer.tokenize()
        
        // Display tokens
        displayTokens(tokens)
        
        // Parse the tokens
        print("🌳 Parsing...")
        let parser = Parser(tokens: tokens)
        
        // Try to parse as a program (multiple statements) first
        let ast: CalcExpression
        do {
            ast = try parser.parseProgram()
            print("✅ Parsed as multi-statement program")
        } catch {
            // If that fails, try parsing as a single expression
            print("ℹ️  Falling back to single expression parsing")
            let singleParser = Parser(tokens: tokens)
            ast = try singleParser.parse()
        }
        
        // Display AST
        try displayAST(ast)
        
        // Display additional analysis
        try displayAnalysis(ast)
        
    } catch let error as TokenizerError {
        print("❌ Tokenizer Error: \(error.localizedDescription)")
        exit(1)
    } catch let error as ParseError {
        print("❌ Parser Error: \(error.localizedDescription)")
        exit(1)
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
}

/// Prints usage information
func printUsage() {
    print("SwiftCalc Demo - Calculator Language Parser")
    print()
    print("Usage: swift-calc-demo <input-file>")
    print()
    print("This program demonstrates tokenizing and parsing calculator expressions.")
    print("The input file should contain mathematical expressions using the calculator language syntax.")
    print()
    print("Supported syntax:")
    print("  • Numbers: 42, 3.14")
    print("  • Identifiers: x, myVar, result")
    print("  • Operators: +, -, *, /, %, ^")
    print("  • Assignment: x = 5")
    print("  • Function calls: sin(x), cos(3.14)")
    print("  • Parentheses: (2 + 3) * 4")
    print()
    print("Example input file content:")
    print("  result = (a + b) * sin(x) - 2 ^ 3")
}

/// Displays the tokenized output
func displayTokens(_ tokens: [Token]) {
    print("🔤 Tokens (\(tokens.count)):")
    print("─" * 60)
    
    for (index, token) in tokens.enumerated() {
        let position = "[\(token.position.line):\(token.position.column)]"
        let typeDescription = String(describing: token.type).padding(toLength: 15, withPad: " ", startingAt: 0)
        let value = token.value.isEmpty ? "<empty>" : "'\(token.value)'"
        
        print(String(format: "%3d: %@ %@ %@ %@", 
                     index + 1, 
                     position.padding(toLength: 8, withPad: " ", startingAt: 0),
                     typeDescription, 
                     "→".padding(toLength: 3, withPad: " ", startingAt: 0),
                     value))
    }
    print("─" * 60)
    print()
}

/// Displays the Abstract Syntax Tree
func displayAST(_ ast: CalcExpression) throws {
    print("🌳 Abstract Syntax Tree:")
    print("─" * 60)
    
    // Use the tree visualizer to display the AST structure
    let treeString = try ASTTreeVisualizer.visualize(ast)
    print(treeString)
    
    print("─" * 60)
    print()
    
    // Also show a compact string representation
    print("📝 Compact representation:")
    let compactString = try ASTAnalysis.toString(ast)
    print("   \(compactString)")
    print()
}

/// Displays additional analysis information about the AST
func displayAnalysis(_ ast: CalcExpression) throws {
    print("📊 AST Analysis:")
    print("─" * 40)
    
    // Node count analysis
    let nodeCount = try ASTAnalysis.countNodes(in: ast)
    print("Total nodes: \(nodeCount)")
    
    // Depth analysis
    let depth = try ASTAnalysis.calculateDepth(of: ast)
    print("Tree depth: \(depth)")
    
    // Extract identifiers
    let identifiers = ASTAnalysis.extractIdentifiers(from: ast)
    if !identifiers.isEmpty {
        print("Identifiers: \(identifiers.sorted().joined(separator: ", "))")
    }
    
    // Extract literals
    let literals = ASTAnalysis.extractLiterals(from: ast)
    if !literals.isEmpty {
        print("Literals: \(literals.joined(separator: ", "))")
    }
    
    // Extract operators
    let operators = ASTAnalysis.extractOperators(from: ast)
    if !operators.isEmpty {
        print("Operators:")
        for (op, count) in operators.sorted(by: { $0.key < $1.key }) {
            print("  • \(op): \(count)")
        }
    }
    
    // Extract function calls
    let functionCalls = ASTAnalysis.extractFunctionCalls(from: ast)
    if !functionCalls.isEmpty {
        print("Function calls:")
        for (name, argCount) in functionCalls {
            print("  • \(name)(\(argCount) args)")
        }
    }
    
    // Extract assignment targets
    let assignmentTargets = ASTAnalysis.extractAssignmentTargets(from: ast)
    if !assignmentTargets.isEmpty {
        print("Assignment targets: \(assignmentTargets.sorted().joined(separator: ", "))")
    }
    
    // Complexity calculation
    let complexity = try ASTAnalysis.calculateComplexity(of: ast)
    print("Complexity score: \(complexity)")
    
    print("─" * 40)
    print()
}

// String multiplication operator for creating separator lines
infix operator *: MultiplicationPrecedence

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// Run the main function
main()