// SwiftCalcParser - A Swift calculator expression parser
//
// This module provides a recursive descent parser that transforms tokens
// from SwiftCalcTokenizer into a strongly-typed Abstract Syntax Tree (AST).
// The parser implements proper operator precedence and associativity rules
// for mathematical expressions and assignments.

// Re-export SwiftCalcTokenizer types that are used in the public API
@_exported import SwiftCalcTokenizer

// MARK: - Core Parser Interface
// The main parser class and error types
// (Parser.swift and ParseError.swift are automatically available)

// MARK: - AST Node Protocols
// Base protocols for AST nodes and visitor pattern
// (ASTNode.swift and ASTVisitor.swift are automatically available)

// MARK: - AST Node Types
// Concrete AST node implementations
// (All AST/*.swift files are automatically available)

/// Version information for SwiftCalcParser
public struct SwiftCalcParserVersion {
    /// The current version of SwiftCalcParser
    public static let current = "1.0.0"
    
    /// The minimum supported SwiftCalcTokenizer version
    public static let minimumTokenizerVersion = "1.0.0"
}