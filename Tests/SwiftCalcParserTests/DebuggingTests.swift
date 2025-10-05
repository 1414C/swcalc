import XCTest
import SwiftCalcTokenizer
@testable import SwiftCalcParser

final class DebuggingTests: XCTestCase {
    
    func testASTDebugVisitor() throws {
        // Create a simple AST
        let input = "x + y * 2"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Test debug visitor
        let debugString = try Parser.debugAST(ast, includePositions: false, includeTypes: true)
        
        XCTAssertTrue(debugString.contains("[BinaryOperation]"))
        XCTAssertTrue(debugString.contains("[Identifier]"))
        XCTAssertTrue(debugString.contains("[Literal]"))
        XCTAssertTrue(debugString.contains("+"))
        XCTAssertTrue(debugString.contains("*"))
    }
    
    func testASTSerializationVisitor() throws {
        // Create a simple AST
        let input = "result = 42"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Test serialization
        let serialized = try Parser.serializeAST(ast)
        
        XCTAssertEqual(serialized["type"] as? String, "Assignment")
        XCTAssertNotNil(serialized["target"])
        XCTAssertNotNil(serialized["value"])
        XCTAssertNotNil(serialized["position"])
    }
    
    func testASTTreeVisualizer() throws {
        // Create a simple AST
        let input = "a + b"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Test tree visualization
        let treeVisualization = try ast.visualizeTree()
        
        XCTAssertTrue(treeVisualization.contains("BinaryOp: +"))
        XCTAssertTrue(treeVisualization.contains("Identifier: a"))
        XCTAssertTrue(treeVisualization.contains("Identifier: b"))
        XCTAssertTrue(treeVisualization.contains("└"))
        XCTAssertTrue(treeVisualization.contains("├"))
    }
    
    func testJSONSerialization() throws {
        // Create a simple AST
        let input = "x"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Test JSON serialization
        let jsonString = try ast.toJSON()
        let compactJSON = try ast.toCompactJSON()
        
        XCTAssertTrue(jsonString.contains("\"type\" : \"Identifier\""))
        XCTAssertTrue(jsonString.contains("\"name\" : \"x\""))
        XCTAssertTrue(compactJSON.contains("\"type\":\"Identifier\""))
        XCTAssertTrue(compactJSON.contains("\"name\":\"x\""))
    }
    
    func testParserDebuggingMethods() throws {
        let input = "a = b + c"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens, enableDebugMode: true)
        
        // Get initial debug info
        let initialDebugInfo = parser.getDebugInfo()
        XCTAssertEqual(initialDebugInfo["currentIndex"] as? Int, 0)
        XCTAssertEqual(initialDebugInfo["debugMode"] as? Bool, true)
        
        // Parse
        let _ = try parser.parse()
        
        // Get final debug info
        let finalDebugInfo = parser.getDebugInfo()
        XCTAssertTrue((finalDebugInfo["currentIndex"] as? Int ?? 0) > 0)
        
        // Get parsing statistics
        let stats = parser.getParsingStatistics()
        XCTAssertNotNil(stats["tokenCount"])
        XCTAssertNotNil(stats["progressPercentage"])
        XCTAssertNotNil(stats["operationCount"])
        
        // Get parsing summary
        let summary = parser.getParsingSummary()
        XCTAssertTrue(summary.contains("Parser Summary"))
        XCTAssertTrue(summary.contains("Tokens:"))
        XCTAssertTrue(summary.contains("Progress:"))
    }
    
    func testASTAnalysisReport() throws {
        let input = "result = func(x + y)"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Generate analysis report
        let report = try ASTAnalysis.generateAnalysisReport(for: ast)
        
        XCTAssertTrue(report.contains("AST Analysis Report"))
        XCTAssertTrue(report.contains("Total nodes:"))
        XCTAssertTrue(report.contains("Maximum depth:"))
        XCTAssertTrue(report.contains("Complexity score:"))
        XCTAssertTrue(report.contains("Identifiers"))
        XCTAssertTrue(report.contains("Function Calls"))
        XCTAssertTrue(report.contains("func(1 argument)"))
    }
    
    func testExtensionMethods() throws {
        let input = "x * (y + z)"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Test extension methods
        let debugDesc = try ast.debugDescription(includePositions: false, includeTypes: true)
        let serialized = try ast.serialize()
        let jsonString = try ast.toJSON()
        let compactJSON = try ast.toCompactJSON()
        let treeViz = try ast.visualizeTree()
        
        XCTAssertTrue(debugDesc.contains("[BinaryOperation]"))
        XCTAssertEqual(serialized["type"] as? String, "BinaryOperation")
        XCTAssertTrue(jsonString.contains("\"type\" : \"BinaryOperation\""))
        XCTAssertTrue(compactJSON.contains("\"type\":\"BinaryOperation\""))
        XCTAssertTrue(treeViz.contains("BinaryOp: *"))
    }
    
    func testRequirement8_2_DebugStringRepresentation() throws {
        // Requirement 8.2: WHEN I need to debug parsing results THEN the system SHALL provide a readable string representation of the AST
        let input = "result = func(x + y * 2)"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Test debug representation with positions and types
        let debugWithAll = try ast.debugDescription(includePositions: true, includeTypes: true)
        XCTAssertTrue(debugWithAll.contains("[Assignment]"))
        XCTAssertTrue(debugWithAll.contains("[FunctionCall]"))
        XCTAssertTrue(debugWithAll.contains("[BinaryOperation]"))
        XCTAssertTrue(debugWithAll.contains("@1:"))  // Position information
        
        // Test debug representation without positions
        let debugNoPos = try ast.debugDescription(includePositions: false, includeTypes: true)
        XCTAssertTrue(debugNoPos.contains("[Assignment]"))
        XCTAssertFalse(debugNoPos.contains("@1:"))  // No position information
        
        // Test debug representation without types
        let debugNoTypes = try ast.debugDescription(includePositions: true, includeTypes: false)
        XCTAssertFalse(debugNoTypes.contains("[Assignment]"))  // No type information
        XCTAssertTrue(debugNoTypes.contains("@1:"))  // Position information
        
        // Test tree visualization
        let treeViz = try ast.visualizeTree()
        XCTAssertTrue(treeViz.contains("Assignment: ="))
        XCTAssertTrue(treeViz.contains("FunctionCall: func(1)"))
        XCTAssertTrue(treeViz.contains("BinaryOp: *"))
        XCTAssertTrue(treeViz.contains("└"))  // Tree structure characters
        XCTAssertTrue(treeViz.contains("├"))
    }
    
    func testRequirement8_3_SerializationPreservesStructureAndPosition() throws {
        // Requirement 8.3: WHEN I serialize an AST THEN the system SHALL preserve all structural and positional information
        let input = "a = b + c"
        let tokenizer = Tokenizer(input: input)
        let tokens = try tokenizer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        
        // Test serialization preserves structure
        let serialized = try ast.serialize()
        
        // Verify top-level structure
        XCTAssertEqual(serialized["type"] as? String, "Assignment")
        XCTAssertNotNil(serialized["target"])
        XCTAssertNotNil(serialized["value"])
        XCTAssertNotNil(serialized["position"])
        
        // Verify position information is preserved
        let position = serialized["position"] as? [String: Any]
        XCTAssertNotNil(position)
        XCTAssertNotNil(position?["line"])
        XCTAssertNotNil(position?["column"])
        
        // Verify nested structure is preserved
        let target = serialized["target"] as? [String: Any]
        XCTAssertEqual(target?["type"] as? String, "Identifier")
        XCTAssertEqual(target?["name"] as? String, "a")
        XCTAssertNotNil(target?["position"])
        
        let value = serialized["value"] as? [String: Any]
        XCTAssertEqual(value?["type"] as? String, "BinaryOperation")
        XCTAssertEqual(value?["operator"] as? String, "+")
        XCTAssertNotNil(value?["left"])
        XCTAssertNotNil(value?["right"])
        XCTAssertNotNil(value?["position"])
        
        // Test JSON serialization preserves all information
        let jsonString = try ast.toJSON()
        XCTAssertTrue(jsonString.contains("\"type\" : \"Assignment\""))
        XCTAssertTrue(jsonString.contains("\"line\""))
        XCTAssertTrue(jsonString.contains("\"column\""))
        XCTAssertTrue(jsonString.contains("\"name\" : \"a\""))
        XCTAssertTrue(jsonString.contains("\"operator\" : \"+\""))
        
        // Test compact JSON serialization preserves all information
        let compactJSON = try ast.toCompactJSON()
        XCTAssertTrue(compactJSON.contains("\"type\":\"Assignment\""))
        XCTAssertTrue(compactJSON.contains("\"line\""))
        XCTAssertTrue(compactJSON.contains("\"column\""))
        XCTAssertTrue(compactJSON.contains("\"name\":\"a\""))
        XCTAssertTrue(compactJSON.contains("\"operator\":\"+\""))
    }
}