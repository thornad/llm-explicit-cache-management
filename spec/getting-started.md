# Getting Started with LLM Explicit Cache Management

This guide will help you quickly implement explicit cache management in your LLM applications.

## Quick Start (5 Minutes)

### 1. Basic Document Caching

The simplest use case - cache a document and ask questions about it:

```python
# Python example with OpenAI-compatible API
import openai

client = openai.OpenAI(base_url="your-llm-endpoint")

# Start a clean session
messages = [
    {"role": "user", "content": "[System Start Session]"}
]

# Cache your document
document_content = """
COMPANY POLICY DOCUMENT
1. Remote Work Policy
   - Employees may work remotely up to 3 days per week
   - Manager approval required for full remote work
   - Core hours: 10 AM - 3 PM in company timezone
   
2. Vacation Policy  
   - 20 days paid vacation annually
   - Must be approved 2 weeks in advance
   - Cannot carry over more than 5 days to next year
   
[... rest of your document ...]
"""

messages.append({
    "role": "user", 
    "content": f"[System Cache: company_policy] {document_content}"
})

# Now ask questions - document is cached and reused
messages.append({
    "role": "user",
    "content": "[System Cache Reference: company_policy] How many remote work days are allowed?"
})

response = client.chat.completions.create(
    model="your-model",
    messages=messages
)

print(response.choices[0].message.content)
```

### 2. Multi-Turn Conversation

Continue the conversation efficiently:

```python
# Add the AI's response to conversation
messages.append({
    "role": "assistant", 
    "content": response.choices[0].message.content
})

# Ask another question - still reusing cached document
messages.append({
    "role": "user",
    "content": "[System Cache Reference: company_policy] What about vacation approval process?"
})

response = client.chat.completions.create(
    model="your-model", 
    messages=messages
)
```

### 3. Clean Up When Done

```python
# Clean up cache when conversation ends
messages.append({
    "role": "user",
    "content": "[System Clean Cache: company_policy]"
})
```

## JavaScript/Node.js Example

```javascript
// Node.js with OpenAI library
import OpenAI from 'openai';

const client = new OpenAI({
    baseURL: 'your-llm-endpoint',
    apiKey: 'your-api-key'
});

async function documentChat() {
    const conversation = [
        { role: "user", content: "[System Start Session]" }
    ];
    
    // Cache document
    const document = `
    USER MANUAL - Smart Thermostat v2.1
    
    Installation:
    1. Turn off power at circuit breaker
    2. Remove old thermostat
    3. Connect wires according to diagram
    [... detailed manual content ...]
    `;
    
    conversation.push({
        role: "user",
        content: `[System Cache: thermostat_manual] ${document}`
    });
    
    // Ask questions about cached document
    const questions = [
        "How do I install this thermostat?",
        "What should I do if the display doesn't turn on?",
        "How do I set up a weekly schedule?"
    ];
    
    for (const question of questions) {
        conversation.push({
            role: "user",
            content: `[System Cache Reference: thermostat_manual] ${question}`
        });
        
        const response = await client.chat.completions.create({
            model: 'your-model',
            messages: conversation
        });
        
        console.log(`Q: ${question}`);
        console.log(`A: ${response.choices[0].message.content}\n`);
        
        // Add response to conversation
        conversation.push({
            role: "assistant",
            content: response.choices[0].message.content
        });
    }
    
    // Cleanup
    conversation.push({
        role: "user",
        content: "[System Clean Cache: thermostat_manual]"
    });
}

documentChat();
```

## React/Web Application Example

```jsx
// React component for document chat
import React, { useState } from 'react';

function DocumentChatbot() {
    const [conversation, setConversation] = useState([
        { role: "user", content: "[System Start Session]" }
    ]);
    const [document, setDocument] = useState('');
    const [question, setQuestion] = useState('');
    const [isDocumentCached, setIsDocumentCached] = useState(false);

    const cacheDocument = async () => {
        if (!document) return;
        
        const newMessage = {
            role: "user",
            content: `[System Cache: user_document] ${document}`
        };
        
        setConversation(prev => [...prev, newMessage]);
        setIsDocumentCached(true);
        
        // Call your LLM API here
        // const response = await callLLM([...conversation, newMessage]);
    };

    const askQuestion = async () => {
        if (!question || !isDocumentCached) return;
        
        const questionMessage = {
            role: "user",
            content: `[System Cache Reference: user_document] ${question}`
        };
        
        const newConversation = [...conversation, questionMessage];
        setConversation(newConversation);
        
        // Call your LLM API
        // const response = await callLLM(newConversation);
        // setConversation(prev => [...prev, { role: "assistant", content: response }]);
        
        setQuestion('');
    };

    const clearCache = () => {
        const clearMessage = {
            role: "user",
            content: "[System Clean Cache: user_document]"
        };
        
        setConversation(prev => [...prev, clearMessage]);
        setIsDocumentCached(false);
        setDocument('');
    };

    return (
        <div>
            <div>
                <h3>Upload Document</h3>
                <textarea
                    value={document}
                    onChange={(e) => setDocument(e.target.value)}
                    placeholder="Paste your document here..."
                    rows={8}
                    cols={80}
                />
                <br />
                <button onClick={cacheDocument} disabled={!document}>
                    Cache Document
                </button>
                {isDocumentCached && (
                    <button onClick={clearCache}>Clear Cache</button>
                )}
            </div>
            
            {isDocumentCached && (
                <div>
                    <h3>Ask Questions</h3>
                    <input
                        type="text"
                        value={question}
                        onChange={(e) => setQuestion(e.target.value)}
                        placeholder="Ask a question about your document..."
                        style={{ width: '500px' }}
                    />
                    <button onClick={askQuestion} disabled={!question}>
                        Ask Question
                    </button>
                </div>
            )}
            
            <div>
                <h3>Conversation</h3>
                {conversation.map((msg, idx) => (
                    <div key={idx} style={{ margin: '10px 0' }}>
                        <strong>{msg.role}:</strong> {msg.content}
                    </div>
                ))}
            </div>
        </div>
    );
}

export default DocumentChatbot;
```

## Implementation Checklist

Before implementing explicit cache management, ensure your system can:

### ✅ Basic Requirements

- [ ] **Parse cache commands**: Extract `[System Cache: id]` syntax from messages
- [ ] **Store content**: Keep both raw text and tokenized versions
- [ ] **Reference handling**: Inject cached content when `[System Cache Reference: id]` is used
- [ ] **Session isolation**: Separate cache storage per user/session
- [ ] **Graceful fallback**: Handle unsupported operations without crashing

### ✅ Recommended Features

- [ ] **Memory limits**: Configurable maximum cache size
- [ ] **TTL support**: Time-based cache expiration
- [ ] **LRU eviction**: Remove oldest caches when memory is full
- [ ] **Cache statistics**: Monitor hit rates and memory usage
- [ ] **Error handling**: Robust handling of malformed commands

### ✅ Advanced Features (Optional)

- [ ] **Priority caching**: Keep important caches longer
- [ ] **Compression**: Reduce memory usage for large documents
- [ ] **Persistence**: Maintain caches across application restarts  
- [ ] **Multi-document**: Efficient handling of multiple cache references
- [ ] **Mobile optimization**: Special handling for resource constraints

## Testing Your Implementation

### 1. Basic Functionality Test

```python
def test_basic_caching():
    # Test session start
    response = send_message("[System Start Session]")
    assert "session" in response.lower()
    
    # Test caching
    doc = "Test document content for caching functionality."
    response = send_message(f"[System Cache: test_doc] {doc}")
    assert "cached" in response.lower()
    
    # Test reference
    response = send_message("[System Cache Reference: test_doc] What is this about?")
    assert "test document" in response.lower()
    
    # Test cleanup
    response = send_message("[System Clean Cache: test_doc]")
    assert "removed" in response.lower() or "cleared" in response.lower()
```

### 2. Performance Test

```python
import time

def test_performance():
    large_doc = "Large document content... " * 1000  # ~25KB
    
    # Measure without caching (baseline)
    start = time.time()
    for i in range(5):
        response = send_message(f"{large_doc} Question {i}")
    baseline_time = time.time() - start
    
    # Measure with caching
    send_message("[System Start Session]")
    send_message(f"[System Cache: large_doc] {large_doc}")
    
    start = time.time()
    for i in range(5):
        response = send_message(f"[System Cache Reference: large_doc] Question {i}")
    cached_time = time.time() - start
    
    improvement = baseline_time / cached_time
    print(f"Performance improvement: {improvement:.2f}x faster")
    assert improvement > 1.5  # Should be at least 50% faster
```

### 3. Memory Management Test

```python
def test_memory_management():
    # Cache multiple documents
    for i in range(10):
        doc = f"Document {i} content... " * 100
        send_message(f"[System Cache: doc_{i}] {doc}")
    
    # Check cache info
    response = send_message("[System Cache Info]")
    assert "doc_0" in response and "doc_9" in response
    
    # Test selective cleanup
    send_message("[System Clean Cache: doc_0,doc_1,doc_2]")
    response = send_message("[System Cache Info]")
    assert "doc_0" not in response
    assert "doc_3" in response  # Should still exist
    
    # Test full cleanup
    send_message("[System Clean Cache]")
    response = send_message("[System Cache Info]")
    assert "no cached content" in response.lower() or response.strip() == ""
```

## Common Integration Patterns

### Pattern 1: Session-Based Applications

```python
class CacheAwareSession:
    def __init__(self, llm_client):
        self.client = llm_client
        self.conversation = []
        self.cached_items = set()
        self.start_session()
    
    def start_session(self):
        self.conversation = [{"role": "user", "content": "[System Start Session]"}]
        self.cached_items.clear()
    
    def cache_document(self, doc_id, content):
        message = {"role": "user", "content": f"[System Cache: {doc_id}] {content}"}
        self.conversation.append(message)
        self.cached_items.add(doc_id)
        return self._send_message()
    
    def ask_question(self, question, cache_refs=None):
        if cache_refs:
            refs = ",".join(cache_refs)
            content = f"[System Cache Reference: {refs}] {question}"
        else:
            content = question
        
        message = {"role": "user", "content": content}
        self.conversation.append(message)
        return self._send_message()
    
    def cleanup(self, doc_ids=None):
        if doc_ids:
            refs = ",".join(doc_ids)
            content = f"[System Clean Cache: {refs}]"
            for doc_id in doc_ids:
                self.cached_items.discard(doc_id)
        else:
            content = "[System Clean Cache]"
            self.cached_items.clear()
        
        message = {"role": "user", "content": content}
        self.conversation.append(message)
        return self._send_message()
    
    def _send_message(self):
        response = self.client.chat.completions.create(
            model="your-model",
            messages=self.conversation
        )
        
        self.conversation.append({
            "role": "assistant",
            "content": response.choices[0].message.content
        })
        
        return response.choices[0].message.content
```

### Pattern 2: Mobile-Optimized Usage

```javascript
class MobileCacheManager {
    constructor(client, maxCacheSize = 50 * 1024 * 1024) { // 50MB limit
        this.client = client;
        this.maxCacheSize = maxCacheSize;
        this.currentCacheSize = 0;
        this.conversation = [];
        this.startSession();
    }
    
    async startSession() {
        this.conversation = [{ role: "user", content: "[System Start Session]" }];
        this.currentCacheSize = 0;
    }
    
    async cacheDocument(docId, content, ttl = 3600) {
        // Check memory constraints
        const contentSize = new Blob([content]).size;
        if (this.currentCacheSize + contentSize > this.maxCacheSize) {
            await this.cleanup(); // Auto-cleanup to free memory
        }
        
        const message = {
            role: "user",
            content: `[System Cache: ${docId}, ttl: ${ttl}] ${content}`
        };
        
        this.conversation.push(message);
        this.currentCacheSize += contentSize;
        
        return await this._sendMessage();
    }
    
    async askQuestion(question, cacheRefs = []) {
        let content = question;
        if (cacheRefs.length > 0) {
            const refs = cacheRefs.join(',');
            content = `[System Cache Reference: ${refs}] ${question}`;
        }
        
        this.conversation.push({ role: "user", content });
        return await this._sendMessage();
    }
    
    async cleanup(docIds = null) {
        const content = docIds 
            ? `[System Clean Cache: ${docIds.join(',')}]`
            : "[System Clean Cache]";
        
        this.conversation.push({ role: "user", content });
        
        if (!docIds) {
            this.currentCacheSize = 0; // Full cleanup
        }
        
        return await this._sendMessage();
    }
    
    async getCacheStats() {
        this.conversation.push({ role: "user", content: "[System Cache Stats]" });
        return await this._sendMessage();
    }
    
    async _sendMessage() {
        try {
            const response = await this.client.chat.completions.create({
                model: 'your-mobile-optimized-model',
                messages: this.conversation,
                max_tokens: 500 // Limit response size for mobile
            });
            
            this.conversation.push({
                role: "assistant",
                content: response.choices[0].message.content
            });
            
            return response.choices[0].message.content;
        } catch (error) {
            console.error('LLM request failed:', error);
            // Graceful degradation - try without cache references
            return await this._fallbackRequest();
        }
    }
    
    async _fallbackRequest() {
        // Remove cache references and try again
        const lastMessage = this.conversation[this.conversation.length - 1];
        const fallbackContent = lastMessage.content.replace(
            /\[System Cache Reference: [^\]]+\]\s*/g, 
            ''
        );
        
        this.conversation[this.conversation.length - 1] = {
            role: "user",
            content: fallbackContent
        };
        
        const response = await this.client.chat.completions.create({
            model: 'your-mobile-optimized-model',
            messages: this.conversation
        });
        
        return response.choices[0].message.content;
    }
}
```

## Troubleshooting

### Common Issues and Solutions

**1. Cache commands treated as regular text**
- **Cause**: Inference engine doesn't support explicit caching
- **Solution**: Implement parser in your application layer
- **Workaround**: Use traditional context inclusion as fallback

**2. Memory issues with large documents**
- **Cause**: Insufficient memory management
- **Solution**: Implement TTL and LRU eviction
- **Workaround**: Split large documents into smaller chunks

**3. Inconsistent behavior across sessions**  
- **Cause**: Cache bleeding between users
- **Solution**: Ensure proper session isolation
- **Workaround**: Always start with `[System Start Session]`

**4. Poor performance on mobile**
- **Cause**: Memory constraints not handled properly
- **Solution**: Implement mobile-specific optimizations
- **Workaround**: Use shorter TTL and aggressive cleanup

### Debugging Tips

```python
# Enable verbose logging
def debug_cache_operations(conversation):
    for msg in conversation:
        if msg['content'].startswith('[System'):
            print(f"Cache operation: {msg['content'][:50]}...")
    
# Monitor memory usage
def check_memory_usage():
    response = send_message("[System Cache Stats]")
    print(f"Cache stats: {response}")

# Test fallback behavior
def test_graceful_degradation():
    # Disable cache support temporarily
    original_message = "[System Cache Reference: doc1] Question?"
    fallback_message = expand_cache_references(original_message)
    print(f"Fallback: {fallback_message}")
```

## Next Steps

1. **Read the specification**: [Core Specification](../spec/core-specification.md)
2. **Explore examples**: [Use Cases](../spec/use-cases.md)  
3. **Check implementations**: [Reference Implementations](../implementations/)
4. **Join the community**: [GitHub Discussions](https://github.com/your-repo/discussions)
5. **Contribute**: Help improve the specification and implementations

## Need Help?

- **Documentation**: Browse the `/docs` folder for detailed guides
- **Examples**: Check `/examples` for complete working examples
- **Issues**: Report bugs and request features on GitHub
- **Discussions**: Ask questions and share ideas in GitHub Discussions

---

**Quick Reference:**
- `[System Start Session]` - Initialize clean session
- `[System Cache: id] content` - Cache content with identifier  
- `[System Cache Reference: id]` - Reference cached content
- `[System Clean Cache: id]` - Remove specific cache
- `[System Clean Cache]` - Remove all caches