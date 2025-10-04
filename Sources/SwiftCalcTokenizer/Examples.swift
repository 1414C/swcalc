import Foundation

/// Example usage patterns for the SwiftCalcTokenizer
/// 
/// This file demonstrates various ways to use the tokenizer for different
/// use cases, including basic tokenization, error handling, and iterator patterns.
public struct TokenizerExamples {
    
    // MARK: - Basic Usage Examples
    
    /// Example 1: Basic tokenization of a simple mathematical expression
    public static func basicTokenization() {
        print("=== Basic Tokenization Example ===")
        
        let input = "3.14 + x * 2"
        let tokenizer = Tokenizer(input: input)
        
        do {
            let tokens = try tokenizer.tokenize()
            print("Input: \(input)")
            print("Tokens:")
            for token in tokens {
                print("  \(token)")
            }
        } catch {
            print("Error during tokenization: \(error)")
        }
        
        print()
    }
    
    /// Example 2: Sequential token processing using nextToken()
    public static func sequentialTokenization() {
        print("=== Sequential Tokenization Example ===")
        
        let input = "result = (a + b) / 2"
        let tokenizer = Tokenizer(input: input)
        
        print("Input: \(input)")
        print("Processing tokens one by one:")
        
        do {
            var tokenCount = 0
            while true {
                let token = try tokenizer.nextToken()
                tokenCount += 1
                print("  Token \(tokenCount): \(token)")
                
                // Stop when we reach EOF
                if case .eof = token.type {
                    break
                }
            }
        } catch {
            print("Error during tokenization: \(error)")
        }
        
        print()
    }
    
    /// Example 3: Using iterator support with for-in loops
    public static func iteratorExample() {
        print("=== Iterator Pattern Example ===")
        
        let input = "sin(x) + cos(y)"
        let tokenizer = Tokenizer(input: input)
        
        print("Input: \(input)")
        print("Using for-in loop:")
        
        for token in tokenizer {
            print("  \(token)")
        }
        
        print()
    }
    
    // MARK: - Error Handling Examples
    
    /// Example 4: Handling invalid characters gracefully
    public static func invalidCharacterHandling() {
        print("=== Invalid Character Handling Example ===")
        
        let input = "3 + @ - 5"  // @ is an invalid character
        let tokenizer = Tokenizer(input: input)
        
        print("Input: \(input)")
        print("Tokens (including error tokens):")
        
        do {
            let tokens = try tokenizer.tokenize()
            for token in tokens {
                if case .error = token.type {
                    print("  ❌ \(token) <- Error token")
                } else {
                    print("  ✅ \(token)")
                }
            }
        } catch {
            print("Error during tokenization: \(error)")
        }
        
        print()
    }
    
    /// Example 5: Handling malformed numbers
    public static func malformedNumberHandling() {
        print("=== Malformed Number Handling Example ===")
        
        let input = "3.14.159 + 2"  // Invalid number with multiple decimal points
        let tokenizer = Tokenizer(input: input)
        
        print("Input: \(input)")
        print("Tokens (including error tokens):")
        
        do {
            let tokens = try tokenizer.tokenize()
            for token in tokens {
                if case .error = token.type {
                    print("  ❌ \(token) <- Malformed number")
                } else {
                    print("  ✅ \(token)")
                }
            }
        } catch {
            print("Error during tokenization: \(error)")
        }
        
        print()
    }
    
    /// Example 6: Comprehensive error handling pattern
    public static func comprehensiveErrorHandling() {
        print("=== Comprehensive Error Handling Example ===")
        
        let inputs = [
            "3 + 4",           // Valid expression
            "x = 5.5",         // Valid assignment
            "2 * @ + 1",       // Invalid character
            "3.14.159",        // Malformed number
            "func(x, y)",      // Valid function call syntax
            "a + b & c"        // Invalid character
        ]
        
        for input in inputs {
            print("Processing: \(input)")
            let tokenizer = Tokenizer(input: input)
            
            do {
                let tokens = try tokenizer.tokenize()
                var hasErrors = false
                
                for token in tokens {
                    if case .error = token.type {
                        hasErrors = true
                        break
                    }
                }
                
                if hasErrors {
                    print("  ❌ Contains errors:")
                    for token in tokens {
                        if case .error = token.type {
                            print("    Error: \(token)")
                        }
                    }
                } else {
                    print("  ✅ Successfully tokenized (\(tokens.count - 1) tokens + EOF)")
                }
            } catch {
                print("  ❌ Tokenization failed: \(error)")
            }
            
            print()
        }
    }
    
    // MARK: - Advanced Usage Examples
    
    /// Example 7: Position tracking for error reporting
    public static func positionTrackingExample() {
        print("=== Position Tracking Example ===")
        
        let input = """
        x = 3.14
        y = x + @
        result = x * y
        """
        
        let tokenizer = Tokenizer(input: input)
        
        print("Input:")
        print(input)
        print("\nTokens with positions:")
        
        do {
            let tokens = try tokenizer.tokenize()
            for token in tokens {
                if case .error = token.type {
                    print("  ❌ \(token) <- Error at line \(token.position.line), column \(token.position.column)")
                } else if case .eof = token.type {
                    print("  📄 \(token)")
                } else {
                    print("  ✅ \(token)")
                }
            }
        } catch {
            print("Error during tokenization: \(error)")
        }
        
        print()
    }
    
    /// Example 8: Building a simple expression evaluator using the tokenizer
    public static func expressionEvaluatorExample() {
        print("=== Expression Evaluator Example ===")
        
        let expressions = [
            "3 + 4 * 2",
            "(5 - 3) * 2",
            "x = 10",
            "result = x + 5"
        ]
        
        for expression in expressions {
            print("Expression: \(expression)")
            let tokenizer = Tokenizer(input: expression)
            
            do {
                let tokens = try tokenizer.tokenize()
                
                // Simple classification of expression types
                var hasAssignment = false
                var hasOperators = false
                var hasIdentifiers = false
                
                for token in tokens {
                    switch token.type {
                    case .assign:
                        hasAssignment = true
                    case .operator:
                        hasOperators = true
                    case .identifier:
                        hasIdentifiers = true
                    default:
                        break
                    }
                }
                
                if hasAssignment {
                    print("  Type: Assignment expression")
                } else if hasOperators {
                    print("  Type: Mathematical expression")
                } else if hasIdentifiers {
                    print("  Type: Identifier expression")
                } else {
                    print("  Type: Simple value")
                }
                
                print("  Token count: \(tokens.count - 1) (excluding EOF)")
                
            } catch {
                print("  ❌ Failed to tokenize: \(error)")
            }
            
            print()
        }
    }
    
    // MARK: - Performance Example
    
    /// Example 9: Processing large input efficiently
    public static func performanceExample() {
        print("=== Performance Example ===")
        
        // Generate a large mathematical expression
        var largeExpression = ""
        for i in 1...1000 {
            if i > 1 {
                largeExpression += " + "
            }
            largeExpression += "x\(i)"
        }
        
        print("Processing large expression with \(largeExpression.count) characters...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let tokenizer = Tokenizer(input: largeExpression)
        
        do {
            let tokens = try tokenizer.tokenize()
            let endTime = CFAbsoluteTimeGetCurrent()
            let processingTime = endTime - startTime
            
            print("  ✅ Successfully tokenized \(tokens.count - 1) tokens")
            print("  ⏱️  Processing time: \(String(format: "%.4f", processingTime)) seconds")
            print("  📊 Tokens per second: \(String(format: "%.0f", Double(tokens.count) / processingTime))")
            
        } catch {
            print("  ❌ Failed to tokenize: \(error)")
        }
        
        print()
    }
    
    // MARK: - Main Example Runner
    
    /// Runs all examples to demonstrate tokenizer capabilities
    public static func runAllExamples() {
        print("SwiftCalcTokenizer Usage Examples")
        print("==================================\n")
        
        basicTokenization()
        sequentialTokenization()
        iteratorExample()
        invalidCharacterHandling()
        malformedNumberHandling()
        comprehensiveErrorHandling()
        positionTrackingExample()
        expressionEvaluatorExample()
        performanceExample()
        
        print("All examples completed!")
    }
}