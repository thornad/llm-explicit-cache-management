// MARK: - ECMFramework/Tests/ECMFrameworkTests/ECMFrameworkTests.swift

import XCTest
@testable import ECMFramework

final class ECMFrameworkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear cache before each test
        ExplicitCacheManager.shared.clearAll()
    }
    
    // MARK: - Cache Directive Parsing Tests
    
    func testParseCacheDirective() {
        let input = "[System Cache: test_doc] This is test content for caching."
        let (directives, cleanInput) = ExplicitCacheParser.parse(input)
        
        XCTAssertEqual(directives.count, 1)
        XCTAssertTrue(cleanInput.isEmpty)
        
        if case .cache(let id, let content) = directives[0].operation {
            XCTAssertEqual(id, "test_doc")
            XCTAssertEqual(content, "This is test content for caching.")
        } else {
            XCTFail("Expected cache directive")
        }
    }
    
    func testParseReferenceDirective() {
        let input = "Based on cache reference: test_doc, what is the main topic?"
        let (directives, cleanInput) = ExplicitCacheParser.parse(input)
        
        XCTAssertEqual(directives.count, 0) // References are handled in prompt assembly
        XCTAssertEqual(cleanInput, input)
    }
    
    func testParseCleanDirective() {
        let input = "[System Clean Cache: test_doc]"
        let (directives, cleanInput) = ExplicitCacheParser.parse(input)
        
        XCTAssertEqual(directives.count, 1)
        XCTAssertTrue(cleanInput.isEmpty)
        
        if case .clean(let id) = directives[0].operation {
            XCTAssertEqual(id, "test_doc")
        } else {
            XCTFail("Expected clean directive")
        }
    }
    
    func testParseCleanAllDirective() {
        let input = "[System Clean Cache]"
        let (directives, cleanInput) = ExplicitCacheParser.parse(input)
        
        XCTAssertEqual(directives.count, 1)
        XCTAssertTrue(cleanInput.isEmpty)
        
        if case .clean(let id) = directives[0].operation {
            XCTAssertNil(id)
        } else {
            XCTFail("Expected clean all directive")
        }
    }
    
    func testParseMultipleDirectives() {
        let input = """
        [System Cache: doc1] First document content.
        [System Cache: doc2] Second document content.
        [System Clean Cache: old_doc]
        """
        
        let (directives, cleanInput) = ExplicitCacheParser.parse(input)
        
        XCTAssertEqual(directives.count, 3)
        XCTAssertTrue(cleanInput.isEmpty)
    }
    
    func testParseWithMixedContent() {
        let input = "[System Cache: doc] Content here. Based on cache reference: doc, what is this about?"
        let (directives, cleanInput) = ExplicitCacheParser.parse(input)
        
        XCTAssertEqual(directives.count, 1)
        XCTAssertEqual(cleanInput, "Based on cache reference: doc, what is this about?")
    }
    
    // MARK: - Cache Manager Tests
    
    func testCacheStatus() {
        let status = ECMFramework.shared.cacheStatus
        XCTAssertTrue(status.isEmpty)
        XCTAssertEqual(status.count, 0)
    }
    
    func testCachePreview() {
        let longContent = String(repeating: "A", count: 200)
        let shortContent = "Short content"
        
        let status = ECMCacheStatus(
            caches: ["long": longContent, "short": shortContent],
            stats: ["long": 50, "short": 5]
        )
        
        let longPreview = status.preview(for: "long", maxLength: 100)
        let shortPreview = status.preview(for: "short", maxLength: 100)
        
        XCTAssertTrue(longPreview.hasSuffix("..."))
        XCTAssertEqual(shortPreview, shortContent)
        
        let missingPreview = status.preview(for: "missing")
        XCTAssertEqual(missingPreview, "Cache not found")
    }
    
    // MARK: - Error Handling Tests
    
    func testCacheNotFoundError() {
        let error = ECMError.cacheNotFound(id: "missing", available: ["doc1", "doc2"])
        
        XCTAssertEqual(error.localizedDescription, "Cache 'missing' not found. Available caches: doc1, doc2")
    }
    
    func testMalformedDirectiveError() {
        let error = ECMError.malformedDirective("[Invalid Directive")
        
        XCTAssertEqual(error.localizedDescription, "Malformed cache directive: [Invalid Directive")
    }
    
    func testProcessingError() {
        let error = ECMError.processingError("Something went wrong")
        
        XCTAssertEqual(error.localizedDescription, "ECM processing error: Something went wrong")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyInput() {
        let (directives, cleanInput) = ExplicitCacheParser.parse("")
        
        XCTAssertTrue(directives.isEmpty)
        XCTAssertTrue(cleanInput.isEmpty)
    }
    
    func testWhitespaceOnlyInput() {
        let (directives, cleanInput) = ExplicitCacheParser.parse("   \n\t   ")
        
        XCTAssertTrue(directives.isEmpty)
        XCTAssertTrue(cleanInput.isEmpty)
    }
    
    func testMalformedDirectives() {
        let inputs = [
            "[System Cache]", // Missing ID and content
            "[System Cache: ]", // Empty ID
            "[System Cache: id", // Missing closing bracket
            "[Invalid Directive]" // Unknown directive
        ]
        
        for input in inputs {
            let (directives, _) = ExplicitCacheParser.parse(input)
            // Malformed directives should be ignored
            XCTAssertTrue(directives.isEmpty, "Malformed directive should be ignored: \(input)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testParsingPerformance() {
        let largeInput = String(repeating: "[System Cache: doc] Large content here. ", count: 1000)
        
        measure {
            let _ = ExplicitCacheParser.parse(largeInput)
        }
    }
}

// MARK: - Mock Context for Testing

class MockModelContext {
    func encode(text: String) async throws -> [Int] {
        // Simple mock tokenization - just return character codes
        return text.utf8.map { Int($0) }
    }
    
    func decode(tokens: [Int]) -> String {
        // Simple mock detokenization
        let bytes = tokens.compactMap { UInt8(exactly: $0) }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
}

// MARK: - Integration Tests

final class ECMIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        ExplicitCacheManager.shared.clearAll()
    }
    
    func testFullWorkflow() async throws {
        // This test would require actual MLX context
        // For now, just test the parsing and assembly logic
        
        let cacheInput = "[System Cache: test] Test document content."
        let (cacheDirectives, _) = ExplicitCacheParser.parse(cacheInput)
        
        XCTAssertEqual(cacheDirectives.count, 1)
        
        let referenceInput = "Based on cache reference: test, what is this about?"
        let (refDirectives, cleanInput) = ExplicitCacheParser.parse(referenceInput)
        
        XCTAssertEqual(refDirectives.count, 0)
        XCTAssertFalse(cleanInput.isEmpty)
        XCTAssertTrue(cleanInput.contains("cache reference: test"))
    }
}