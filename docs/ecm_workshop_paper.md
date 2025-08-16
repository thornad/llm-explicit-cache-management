# Explicit Cache Management for Large Language Models: A User-Controlled Approach to Inference Optimization

**Workshop Paper Submission**

## Abstract

Large Language Models (LLMs) suffer from a fundamental inefficiency: every inference request requires complete reprocessing of the entire input context, even when users repeatedly reference the same documents or content. We introduce **Explicit Cache Management (ECM)**, a novel user-controlled caching system that enables fine-grained content reuse through simple prompt-level directives. Users can explicitly cache content with semantic identifiers (`[System Cache: doc_id] content...`) and reference it in subsequent queries (`Based on cache reference: doc_id, question?`), eliminating redundant computation while maintaining full context awareness. Our proof-of-concept implementation in MLX demonstrates successful cache operations with clean prompt-response cycles, validating the core concept. ECM requires minimal changes to existing inference engines (typically <200 lines of code) and is framework-agnostic. We present this work to solicit community feedback and encourage adoption across inference frameworks, as ECM addresses a universal inefficiency in current LLM deployment that affects every multi-turn conversation involving repeated content.

**Keywords:** Large Language Models, Inference Optimization, Caching, User Control, Computational Efficiency

## 1. Introduction

### 1.1 The Redundant Computation Problem

Consider a common scenario: a user uploads a 50,000-token legal contract and asks five questions about different clauses. Current LLM systems process the entire document five separate times, requiring 250,000 tokens of computation instead of the theoretical minimum of ~51,000 tokens (document + 5 small queries). This inefficiency scales linearly with query count and affects every domain involving document analysis, code review, academic research, and iterative content exploration.

### 1.2 Limitations of Current Approaches

Existing optimization techniques operate at the infrastructure level without user control:

- **KV Caching**: Optimizes within single inference passes but doesn't persist across requests
- **Prompt Caching**: Some systems cache entire prompt-response pairs, but lack granular reuse
- **RAG Systems**: Retrieve relevant chunks but don't eliminate recomputation of processed content

None provide users explicit control over what gets cached or how cached content is referenced.

### 1.3 Our Contribution

We propose **Explicit Cache Management (ECM)**, the first user-controlled, prompt-level caching system for LLMs. ECM enables:

- **Direct user control** over cache operations through simple directives
- **Semantic organization** of cached content with user-defined identifiers  
- **Framework-agnostic design** requiring minimal integration effort
- **Immediate deployment** in existing inference pipelines

## 2. Approach

### 2.1 Cache Directive Design

ECM extends standard prompting with four simple operations:

```
[System Cache: doc_id] Large document content here...
Based on cache reference: doc_id, what is the contract duration?
[System Clean Cache: doc_id]
[System Clean Cache]
```

These directives are:
- **Human-readable**: No complex syntax or encoding
- **Framework-agnostic**: Work with any tokenizer/model combination
- **Backward-compatible**: Invalid directives are ignored, degrading gracefully

### 2.2 Processing Pipeline

ECM implementation follows a four-stage pipeline:

1. **Directive Parsing**: Extract cache operations using regex pattern matching
2. **Cache Management**: Execute store/retrieve/cleanup operations  
3. **Context Assembly**: Replace cache references with stored content
4. **Standard Inference**: Process assembled prompt through existing LLM pipeline

### 2.3 Integration Requirements

Framework integration requires three components:

- **Directive Parser**: ~50 lines to extract and interpret cache directives
- **Cache Manager**: ~100 lines for content storage and retrieval
- **Context Assembler**: ~50 lines to substitute references with content

Total integration effort: typically under 200 lines of code.

## 3. Proof of Concept Implementation

### 3.1 MLX Framework Integration

We implemented ECM in Apple's MLX framework as a native Swift application with full iOS/macOS compatibility. The implementation demonstrates:

**Successful Cache Operations**:
```swift
// Cache storage
[System Cache: legal_doc] This comprehensive legal agreement...
// Result: ✅ Cache operation completed successfully.

// Cache reference  
Based on cache reference: legal_doc, what is the contract duration?
// Result: The contract duration is 3 years.
```

**Clean Generation Quality**: The system produces coherent, accurate responses that properly reference cached content without artifacts or degradation.

**Efficient Memory Management**: Cached content is tokenized once and reused across references, with configurable memory limits and LRU eviction.

### 3.2 Technical Validation

Our MLX implementation validates key technical assumptions:

- **Tokenization Consistency**: Content tokenized once produces identical tokens across references
- **Prompt Assembly**: Cache references are cleanly substituted without context confusion  
- **Error Handling**: Missing cache references produce helpful error messages
- **Performance**: Cache operations complete with minimal overhead

### 3.3 User Experience Validation

The demo app includes an intuitive interface with example cache directives, demonstrating that users can quickly adopt the ECM interaction pattern. Cache status is visualized in real-time, showing active caches with token counts and content previews.

## 4. Discussion

### 4.1 Theoretical Performance Benefits

ECM provides computational savings proportional to content reuse frequency:

- **Document Analysis**: N questions about a document require ~1x document processing + N query processing (vs. N×document processing)
- **Code Review**: Multiple questions about a codebase eliminate repeated parsing overhead
- **Educational Content**: Students referencing the same materials across sessions benefit from persistent caching

For scenarios with high content reuse, ECM should provide order-of-magnitude efficiency improvements.

### 4.2 Advantages Over Existing Approaches

**vs. Infrastructure Caching**: ECM provides semantic organization and user control, enabling selective reuse that automatic systems cannot achieve.

**vs. RAG Systems**: ECM eliminates recomputation of processed content, while RAG focuses on content retrieval. These approaches are complementary.

**vs. Fine-tuning**: ECM provides immediate knowledge integration without expensive model retraining.

### 4.3 Current Limitations

**Evaluation Scope**: Our current evaluation is limited to proof-of-concept validation in MLX. Comprehensive benchmarking across frameworks and model sizes is needed.

**Cache Management**: The current system provides basic cache operations. Advanced features like automatic cache suggestions, hierarchical organization, and cross-session persistence require future development.

**Content Freshness**: The system lacks automatic staleness detection for cached content that may become outdated.

### 4.4 Framework Compatibility

ECM's design principles ensure broad compatibility:

- **Any Tokenizer**: Works with any encode/decode tokenizer implementation
- **Any Model**: Compatible with any transformer-based architecture
- **Any Framework**: Minimal integration requirements enable adoption across inference engines

However, some models with rigid prompt formats or built-in conversation management may require adaptation.

## 5. Community Impact and Future Work

### 5.1 Call for Community Adoption

ECM addresses a universal inefficiency affecting every LLM deployment. We encourage the community to:

- **Integrate ECM** into popular inference frameworks (Transformers, llama.cpp, vLLM, etc.)
- **Conduct comprehensive benchmarking** across model sizes and use cases
- **Extend the directive syntax** with advanced features (conditional caching, hierarchies, etc.)
- **Develop tooling** for cache management and optimization

### 5.2 Research Directions

**Performance Analysis**: Systematic evaluation of efficiency gains across model sizes, content types, and usage patterns.

**Advanced Cache Management**: Automatic cache suggestions, intelligent eviction policies, and cross-session persistence.

**Integration Studies**: Framework-specific optimizations and compatibility assessments.

**User Experience Research**: Usability studies and interface design for cache management.

### 5.3 Standardization Opportunity

ECM could evolve into a standard interface for LLM caching, similar to how prompt engineering patterns have become widely adopted. Early community adoption and feedback are crucial for establishing effective conventions.

## 6. Implementation Availability

We provide open-source implementations to facilitate community adoption:

- **MLX Implementation**: Native Swift app with iOS/macOS support (working proof-of-concept)
- **Framework Integration Guide**: Documentation for adding ECM to existing inference engines
- **Example Applications**: Demonstration scenarios for common use cases

All code and documentation are available at: https://github.com/[username]/llm-explicit-cache-management

## 7. Conclusion

Explicit Cache Management introduces user-controlled, prompt-level caching for Large Language Models, addressing a fundamental inefficiency in current deployment approaches. Our proof-of-concept implementation validates the core concept and demonstrates successful cache operations with maintained generation quality.

ECM's framework-agnostic design and minimal integration requirements make it immediately adoptable across the LLM ecosystem. The approach democratizes advanced optimization techniques by making them available through simple prompt modifications, enabling all users to benefit from efficiency improvements without infrastructure expertise.

We present this work to encourage community adoption and collaboration. ECM's potential for substantial efficiency gains, combined with its implementation simplicity, makes it a valuable addition to any LLM deployment focused on multi-turn conversations or document analysis workflows.

The success of ECM depends on community validation across diverse frameworks and use cases. We invite researchers and practitioners to integrate, evaluate, and extend our approach, working together to address one of the most pressing efficiency challenges in current LLM deployment.

---

**Acknowledgments**

We thank the open-source community for MLX framework development and the broader LLM optimization research community for foundational work in inference acceleration.

**Code Availability**

Implementation code, integration guides, and demonstration applications are available under open-source license at the project repository.