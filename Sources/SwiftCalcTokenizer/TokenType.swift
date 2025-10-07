/// Represents the different types of mathematical operators supported by the tokenizer
/// 
/// This enumeration defines all the mathematical operators that can be recognized
/// and tokenized. Each case corresponds to a specific operator symbol and mathematical operation.
/// 
/// Example usage:
/// ```swift
/// let plusOperator = OperatorType.plus
/// print(plusOperator) // Prints: +
/// 
/// // Used within TokenType
/// let operatorToken = TokenType.operator(.multiply)
/// ```
public enum OperatorType {
    /// Addition operator (+)
    case plus       
    
    /// Subtraction operator (-)
    case minus      
    
    /// Multiplication operator (*)
    case multiply   
    
    /// Division operator (/)
    case divide     
    
    /// Modulo operator (%)
    case modulo     
    
    /// Exponentiation operator (^)
    case power      
}

// MARK: - Equatable
extension OperatorType: Equatable {}

// MARK: - Hashable
extension OperatorType: Hashable {}

// MARK: - CustomStringConvertible
extension OperatorType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .plus: return "+"
        case .minus: return "-"
        case .multiply: return "*"
        case .divide: return "/"
        case .modulo: return "%"
        case .power: return "^"
        }
    }
}

/// Represents the different types of tokens that can be recognized by the tokenizer
/// 
/// This enumeration defines all possible token types that the tokenizer can produce.
/// Each token type represents a different category of lexical element in the calculator language.
/// 
/// Example usage:
/// ```swift
/// let numberType = TokenType.number
/// let operatorType = TokenType.operator(.plus)
/// let identifierType = TokenType.identifier
/// 
/// // Pattern matching
/// switch token.type {
/// case .number:
///     print("Found a number: \(token.value)")
/// case .operator(let op):
///     print("Found operator: \(op)")
/// case .identifier:
///     print("Found identifier: \(token.value)")
/// default:
///     print("Other token type")
/// }
/// ```
public enum TokenType {
    /// Numeric literals (integers and decimals)
    /// 
    /// Examples: `42`, `3.14`, `0`, `123.456`
    case number                     
    
    /// Variable names and function identifiers
    /// 
    /// Examples: `x`, `result`, `sin`, `myVariable`, `_temp`
    case identifier                 
    
    /// Mathematical operators with associated operator type
    /// 
    /// Examples: `+`, `-`, `*`, `/`, `%`, `^`
    case `operator`(OperatorType)   
    
    /// Left parenthesis `(`
    /// 
    /// Used for grouping expressions and function calls
    case leftParen                  
    
    /// Right parenthesis `)`
    /// 
    /// Used for grouping expressions and function calls
    case rightParen                 
    
    /// Assignment operator `=`
    /// 
    /// Used for variable assignment: `x = 5`
    case assign                     
    
    /// End of file marker
    /// 
    /// Indicates that the tokenizer has reached the end of the input
    case eof                        
    
    /// Comments starting with //
    /// 
    /// Single-line comments that extend to the end of the line
    case comment
    
    /// Invalid or malformed tokens
    /// 
    /// Generated when the tokenizer encounters invalid characters or malformed syntax
    case error                      
}

// MARK: - Equatable
extension TokenType: Equatable {}

// MARK: - Hashable
extension TokenType: Hashable {}

// MARK: - CustomStringConvertible
extension TokenType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .number: return "NUMBER"
        case .identifier: return "IDENTIFIER"
        case .operator(let op): return "OPERATOR(\(op))"
        case .leftParen: return "LPAREN"
        case .rightParen: return "RPAREN"
        case .assign: return "ASSIGN"
        case .comment: return "COMMENT"
        case .eof: return "EOF"
        case .error: return "ERROR"
        }
    }
}