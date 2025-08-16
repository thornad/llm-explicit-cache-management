// MARK: - ECMFramework/Sources/ECMFramework/ECMFramework.swift

import Foundation

// MARK: - Protocol for MLX Context Abstraction

/// Protocol that abstracts MLX functionality for ECMFramework
public protocol ECMModelContext {
    /// Encode text to tokens
    func encode(text: String) async throws -> [Int]
    
    /// Decode tokens to text  
    func decode(tokens: [Int]) -> String
}

// MARK: - Public Framework Interface

/// The main ECM framework interface
public class ECMFramework {
    public static let shared = ECMFramework()
    private init() {}
    
    /// Process a message with ECM directives and return the result
    public func processMessage<T: ECMModelContext>(_ message: String, 
                                                  context: T) async throws -> ECMResult {
        let (directives, cleanInput) = ExplicitCacheParser.parse(message)
        
        // Process cache directives
        for directive in directives {
            try await ExplicitCacheManager.shared.processDirective(directive, context: context)
        }
        
        return ECMResult(
            directives: directives,
            cleanInput: cleanInput,
            finalPrompt: try await assembleFinalPrompt(cleanInput)
        )
    }
    
    /// Get current cache status
    public var cacheStatus: ECMCacheStatus {
        return ECMCacheStatus(
            caches: ExplicitCacheManager.shared.caches,
            stats: ExplicitCacheManager.shared.cacheStats
        )
    }
    
    /// Clear all caches
    public func clearAllCaches() {
        ExplicitCacheManager.shared.clearAll()
    }
}

// MARK: - Cache Directive Types

public struct CacheDirective {
    public enum Operation {
        case cache(id: String, content: String)
        case reference(id: String)
        case clean(id: String?)
        case startSession
    }
    
    public let operation: Operation
    
    public init(operation: Operation) {
        self.operation = operation
    }
}

// MARK: - ECM Result Types

public struct ECMResult {
    public let directives: [CacheDirective]
    public let cleanInput: String
    public let finalPrompt: String
    
    public var hasCacheOperations: Bool {
        return !directives.isEmpty
    }
    
    public var hasCleanInput: Bool {
        return !cleanInput.isEmpty
    }
}

public struct ECMCacheStatus {
    public let caches: [String: String]
    public let stats: [String: Int]
    
    public var count: Int { caches.count }
    public var isEmpty: Bool { caches.isEmpty }
    
    public func preview(for id: String, maxLength: Int = 100) -> String {
        guard let content = caches[id] else { return "Cache not found" }
        let preview = content.prefix(maxLength)
        return preview.count < content.count ? "\(preview)..." : String(preview)
    }
}

// MARK: - Cache Directive Parser

public class ExplicitCacheParser {
    public static func parse(_ input: String) -> (directives: [CacheDirective], cleanInput: String) {
        var directives: [CacheDirective] = []
        var cleanInput = input
        
        // Regex patterns for cache directives
        let patterns = [
            (#"\[System Cache: ([^\]]+)\]\s*(.+?)(?=\[System|\Z)"#, "cache"),
            (#"\[System Cache Reference: ([^\]]+)\]"#, "reference"),
            (#"\[System Clean Cache: ([^\]]+)\]"#, "cleanSpecific"),
            (#"\[System Clean Cache\]"#, "cleanAll"),
            (#"\[System Start Session\]"#, "startSession")
        ]
        
        for (pattern, type) in patterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
            
            for match in matches.reversed() { // Reverse to maintain string indices
                let matchRange = Range(match.range, in: input)!
                
                switch type {
                case "cache":
                    if match.numberOfRanges >= 3 {
                        let idRange = Range(match.range(at: 1), in: input)!
                        let contentRange = Range(match.range(at: 2), in: input)!
                        let id = String(input[idRange])
                        let content = String(input[contentRange])
                        directives.append(CacheDirective(operation: .cache(id: id, content: content)))
                    }
                case "reference":
                    if match.numberOfRanges >= 2 {
                        let idRange = Range(match.range(at: 1), in: input)!
                        let id = String(input[idRange])
                        directives.append(CacheDirective(operation: .reference(id: id)))
                    }
                case "cleanSpecific":
                    if match.numberOfRanges >= 2 {
                        let idRange = Range(match.range(at: 1), in: input)!
                        let id = String(input[idRange])
                        directives.append(CacheDirective(operation: .clean(id: id)))
                    }
                case "cleanAll":
                    directives.append(CacheDirective(operation: .clean(id: nil)))
                case "startSession":
                    directives.append(CacheDirective(operation: .startSession))
                default:
                    break
                }
                
                // Remove directive from input
                cleanInput = String(cleanInput.prefix(matchRange.lowerBound.utf16Offset(in: input))) + 
                           String(cleanInput.suffix(from: matchRange.upperBound))
            }
        }
        
        return (directives, cleanInput.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - Cache Manager

public class ExplicitCacheManager: ObservableObject {
    public static let shared = ExplicitCacheManager()
    
    @Published public private(set) var caches: [String: String] = [:] // ID -> Original content
    @Published public private(set) var cacheStats: [String: Int] = [:] // ID -> Token count
    
    private var tokenCaches: [String: [Int]] = [:] // ID -> Tokens
    
    private init() {}
    
    public func processDirective<T: ECMModelContext>(_ directive: CacheDirective, 
                                                    context: T) async throws {
        switch directive.operation {
        case .cache(let id, let content):
            // Store original content for display
            await MainActor.run {
                caches[id] = content
            }
            
            // Tokenize and store
            let tokens = try await context.encode(text: content)
            tokenCaches[id] = tokens
            
            await MainActor.run {
                cacheStats[id] = tokens.count
            }
            
        case .reference(let id):
            // Reference will be handled in prompt assembly
            break
            
        case .clean(let id):
            if let id = id {
                await MainActor.run {
                    caches.removeValue(forKey: id)
                    cacheStats.removeValue(forKey: id)
                }
                tokenCaches.removeValue(forKey: id)
            } else {
                clearAll()
            }
            
        case .startSession:
            // Could load from persistent storage here
            break
        }
    }
    
    public func getCachedTokens(for id: String) -> [Int]? {
        return tokenCaches[id]
    }
    
    public func getCachedContent(for id: String) -> String? {
        return caches[id]
    }
    
    public func clearAll() {
        Task { @MainActor in
            caches.removeAll()
            cacheStats.removeAll()
        }
        tokenCaches.removeAll()
        // Note: GPU cache clearing is handled by the consuming app
    }
}

// MARK: - Prompt Assembly Helper

extension ECMFramework {
    private func assembleFinalPrompt(_ cleanInput: String) async throws -> String {
        guard !cleanInput.isEmpty else {
            return ""
        }
        
        // Check for cache references and prepend cached content
        var finalInput = cleanInput
        let referencePattern = #"cache reference: ([^\s,]+)"#
        let regex = try NSRegularExpression(pattern: referencePattern, options: .caseInsensitive)
        let matches = regex.matches(in: cleanInput, options: [], range: NSRange(location: 0, length: cleanInput.utf16.count))
        
        for match in matches {
            if match.numberOfRanges >= 2 {
                let idRange = Range(match.range(at: 1), in: cleanInput)!
                let id = String(cleanInput[idRange])
                
                if let cachedContent = ExplicitCacheManager.shared.getCachedContent(for: id) {
                    // Better prompt formatting for higher quality output
                    let cleanQuestion = cleanInput
                        .replacingOccurrences(of: "Based on cache reference: \(id),", with: "")
                        .replacingOccurrences(of: "based on cache reference: \(id),", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    finalInput = """
                    Context: \(cachedContent)
                    
                    Q: \(cleanQuestion)
                    A:
"""
                    break
                } else {
                    throw ECMError.cacheNotFound(id: id, available: Array(ExplicitCacheManager.shared.caches.keys))
                }
            }
        }
        
        return finalInput
    }
}

// MARK: - Error Types

public enum ECMError: Error, LocalizedError {
    case cacheNotFound(id: String, available: [String])
    case malformedDirective(String)
    case processingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .cacheNotFound(let id, let available):
            return "Cache '\(id)' not found. Available caches: \(available.joined(separator: ", "))"
        case .malformedDirective(let directive):
            return "Malformed cache directive: \(directive)"
        case .processingError(let message):
            return "ECM processing error: \(message)"
        }
    }
}
