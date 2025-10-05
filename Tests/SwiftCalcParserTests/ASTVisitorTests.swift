import XCTest
@testable import SwiftCalcParser
@testable import SwiftCalcTokenizer

final class ASTVisitorTests: XCTestCase {
    
    func testASTStringVisitor() throws {
        // Create a simple AST: 2 + 3
        let left = Literal(value: "2", position: Position(line: 1, column: 1))
        let right = Literal(value: "3", position: Position(line: 1, column: 5))
        let ast = BinaryOperation(operator: .plus, left: left, right: right, position: Position(line: 1, column: 3))
        
        let visitor = ASTStringVisitor()
        let result = try ast.accept(visitor)
        
        XCTAssertEqual(result, "2 + 3")
    }
    
    func testASTStringVisitorWithExplicitParentheses() throws {
        // Create a simple AST: 2 + 3
        let left = Literal(value: "2", position: Position(line: 1, column: 1))
        let right = Literal(value: "3", position: Position(line: 1, column: 5))
        let ast = BinaryOperation(operator: .plus, left: left, right: right, position: Position(line: 1, column: 3))
        
        let visitor = ASTStringVisitor(explicitParentheses: true)
        let result = try ast.accept(visitor)
        
        XCTAssertEqual(result, "(2 + 3)")
    }
    
    func testASTDepthVisitor() throws {
        // Create a nested AST: (2 + 3) * 4
        let innerLeft = Literal(value: "2", position: Position(line: 1, column: 2))
        let innerRight = Literal(value: "3", position: Position(line: 1, column: 6))
        let innerAdd = BinaryOperation(operator: .plus, left: innerLeft, right: innerRight, position: Position(line: 1, column: 4))
        let parenthesized = ParenthesizedExpression(expression: innerAdd, position: Position(line: 1, column: 1))
        
        let rightOperand = Literal(value: "4", position: Position(line: 1, column: 11))
        let ast = BinaryOperation(operator: .multiply, left: parenthesized, right: rightOperand, position: Position(line: 1, column: 9))
        
        let visitor = ASTDepthVisitor()
        let depth = try ast.accept(visitor)
        
        // Depth should be: BinaryOp(1) -> ParenthesizedExpr(1) -> BinaryOp(1) -> Literal(1) = 4
        XCTAssertEqual(depth, 4)
    }
    
    func testASTNodeCountVisitor() throws {
        // Create AST: x = 5
        let target = Identifier(name: "x", position: Position(line: 1, column: 1))
        let value = Literal(value: "5", position: Position(line: 1, column: 5))
        let ast = Assignment(target: target, value: value, position: Position(line: 1, column: 3))
        
        let visitor = ASTNodeCountVisitor()
        let count = try ast.accept(visitor)
        
        // Should count: Assignment(1) + Identifier(1) + Literal(1) = 3
        XCTAssertEqual(count, 3)
    }
    
    func testASTTraversalPreOrder() throws {
        // Create AST: 2 + 3
        let left = Literal(value: "2", position: Position(line: 1, column: 1))
        let right = Literal(value: "3", position: Position(line: 1, column: 5))
        let ast = BinaryOperation(operator: .plus, left: left, right: right, position: Position(line: 1, column: 3))
        
        var visitedNodes: [String] = []
        try ASTTraversal.preOrderTraversal(ast) { node in
            if let literal = node as? Literal {
                visitedNodes.append("Literal(\(literal.value))")
            } else if node is BinaryOperation {
                visitedNodes.append("BinaryOperation")
            }
        }
        
        // Pre-order: root first, then children
        XCTAssertEqual(visitedNodes, ["BinaryOperation", "Literal(2)", "Literal(3)"])
    }
    
    func testASTTraversalPostOrder() throws {
        // Create AST: 2 + 3
        let left = Literal(value: "2", position: Position(line: 1, column: 1))
        let right = Literal(value: "3", position: Position(line: 1, column: 5))
        let ast = BinaryOperation(operator: .plus, left: left, right: right, position: Position(line: 1, column: 3))
        
        var visitedNodes: [String] = []
        try ASTTraversal.postOrderTraversal(ast) { node in
            if let literal = node as? Literal {
                visitedNodes.append("Literal(\(literal.value))")
            } else if node is BinaryOperation {
                visitedNodes.append("BinaryOperation")
            }
        }
        
        // Post-order: children first, then root
        XCTAssertEqual(visitedNodes, ["Literal(2)", "Literal(3)", "BinaryOperation"])
    }
    
    func testASTAnalysisExtractIdentifiers() throws {
        // Create AST: x = y + 5
        let target = Identifier(name: "x", position: Position(line: 1, column: 1))
        let leftOperand = Identifier(name: "y", position: Position(line: 1, column: 5))
        let rightOperand = Literal(value: "5", position: Position(line: 1, column: 9))
        let addition = BinaryOperation(operator: .plus, left: leftOperand, right: rightOperand, position: Position(line: 1, column: 7))
        let ast = Assignment(target: target, value: addition, position: Position(line: 1, column: 3))
        
        let identifiers = ASTAnalysis.extractIdentifiers(from: ast)
        
        XCTAssertEqual(identifiers, Set(["x", "y"]))
    }
    
    func testASTAnalysisExtractLiterals() throws {
        // Create AST: 2 + 3.14
        let left = Literal(value: "2", position: Position(line: 1, column: 1))
        let right = Literal(value: "3.14", position: Position(line: 1, column: 5))
        let ast = BinaryOperation(operator: .plus, left: left, right: right, position: Position(line: 1, column: 3))
        
        let literals = ASTAnalysis.extractLiterals(from: ast)
        
        XCTAssertEqual(Set(literals), Set(["2", "3.14"]))
    }
    
    func testASTAnalysisNodeTypeIdentification() throws {
        let literal = Literal(value: "42", position: Position(line: 1, column: 1))
        let identifier = Identifier(name: "x", position: Position(line: 1, column: 1))
        let binaryOp = BinaryOperation(operator: .plus, left: literal, right: identifier, position: Position(line: 1, column: 3))
        
        XCTAssertTrue(ASTAnalysis.isLeafNode(literal))
        XCTAssertTrue(ASTAnalysis.isLeafNode(identifier))
        XCTAssertFalse(ASTAnalysis.isLeafNode(binaryOp))
        
        XCTAssertTrue(ASTAnalysis.isBinaryOperation(binaryOp))
        XCTAssertFalse(ASTAnalysis.isBinaryOperation(literal))
        
        XCTAssertEqual(ASTAnalysis.nodeTypeDescription(literal), "Literal")
        XCTAssertEqual(ASTAnalysis.nodeTypeDescription(identifier), "Identifier")
        XCTAssertEqual(ASTAnalysis.nodeTypeDescription(binaryOp), "BinaryOperation")
    }
    
    func testASTAnalysisComplexityCalculation() throws {
        // Create a simple AST: 2 + 3
        let left = Literal(value: "2", position: Position(line: 1, column: 1))
        let right = Literal(value: "3", position: Position(line: 1, column: 5))
        let simpleAST = BinaryOperation(operator: .plus, left: left, right: right, position: Position(line: 1, column: 3))
        
        // Create a more complex AST: sin(x) + (y * 2)
        let funcArg = Identifier(name: "x", position: Position(line: 1, column: 5))
        let functionCall = FunctionCall(name: "sin", arguments: [funcArg], position: Position(line: 1, column: 1))
        
        let multLeft = Identifier(name: "y", position: Position(line: 1, column: 11))
        let multRight = Literal(value: "2", position: Position(line: 1, column: 15))
        let multiplication = BinaryOperation(operator: .multiply, left: multLeft, right: multRight, position: Position(line: 1, column: 13))
        let parenthesized = ParenthesizedExpression(expression: multiplication, position: Position(line: 1, column: 10))
        
        let complexAST = BinaryOperation(operator: .plus, left: functionCall, right: parenthesized, position: Position(line: 1, column: 8))
        
        let simpleComplexity = try ASTAnalysis.calculateComplexity(of: simpleAST)
        let complexComplexity = try ASTAnalysis.calculateComplexity(of: complexAST)
        
        // Complex AST should have higher complexity than simple AST
        XCTAssertGreaterThan(complexComplexity, simpleComplexity)
    }
}