# LLM Explicit Cache Management: Complete Syntax Reference

This document provides a comprehensive reference for all cache management commands and their parameters.

## Command Categories

- [Session Management](#session-management)
- [Cache Creation](#cache-creation)
- [Cache Reference](#cache-reference)
- [Cache Management](#cache-management)
- [Cache Inspection](#cache-inspection)
- [Error Handling](#error-handling)

## Session Management

### `[System Start Session]`

Initializes a clean cache session. MUST be the first command in any conversation.

**Syntax:**
```
[System Start Session]
[System Start Session: session_id]
```

**Parameters:**
- `session_id` (optional): Explicit session identifier for debugging

**Behavior:**
- Clears all existing cache state
- Initializes session isolation boundary
- Resets memory counters
- Returns session confirmation

**Examples:**
```
[System Start Session]
→ "Session initialized. Cache cleared."

[System Start Session: user_123_chat_456]
→ "Session 'user_123_chat_456' initialized. Cache cleared."
```

**Error Conditions:**
- None (always succeeds)

---

## Cache Creation

### `[System Cache: cache_id] content`

Stores content under the specified identifier for later reference.

**Syntax:**
```
[System Cache: cache_id] content
[System Cache: cache_id, ttl: seconds] content
[System Cache: cache_id, priority: level] content
[System Cache: cache_id, ttl: seconds, priority: level] content
```

**Parameters:**
- `cache_id` (required): Unique identifier for the cached content
- `ttl` (optional): Time-to-live in seconds (default: session lifetime)
- `priority` (optional): Priority level (`low`, `normal`, `high`)

**Behavior:**
- Pre-computes KV cache states for efficient reuse
- Replaces existing cache if ID already exists
- Returns confirmation with cache statistics

**Examples:**
```
[System Cache: legal_doc] Here is the employment contract: [CONTENT...]
→ "Content cached as 'legal_doc' (12,845 tokens, 19.2MB KV cache)"

[System Cache: temp_doc, ttl: 3600] Temporary document content...
→ "Content cached as 'temp_doc' with 1 hour TTL (2,156 tokens, 3.1MB KV cache)"

[System Cache: important_doc, priority: high] Critical document...
→ "Content cached as 'important_doc' with high priority (5,432 tokens, 8.7MB KV cache)"
```

**Error Conditions:**
- `cache_id` contains invalid characters → Use alphanumeric + underscore only
- Content exceeds memory limits → Auto-evict oldest caches or fail gracefully
- TTL is negative or zero → Use default session lifetime

---

## Cache Reference

### `[System Cache Reference: cache_id]`

Injects cached content at the current position in the conversation.

**Syntax:**
```
[System Cache Reference: cache_id]
[System Cache Reference: id1,id2,id3]
[System Cache Reference: cache_id] additional_text
```

**Parameters:**
- `cache_id` (required): Single cache identifier to reference
- `id1,id2,id3` (alternative): Multiple cache identifiers (comma-separated)
- `additional_text` (optional): New content to append after cached content

**Behavior:**
- Retrieves cached content and injects at current position
- Reuses pre-computed KV cache states for performance
- Multiple references are concatenated in specified order
- Transparent to the underlying language model

**Examples:**
```
[System Cache Reference: legal_doc] What are the key terms?
→ [Processes with full document context, fast response due to KV cache reuse]

[System Cache Reference: doc1,doc2,doc3] Compare these documents.
→ [Processes with all three documents, concatenated in order]

[System Cache Reference: contract] Based on this contract, here's my analysis: [NEW TEXT]
→ [Processes contract + new analysis text]
```

**Error Conditions:**
- `cache_id` not found → Log warning, continue processing as normal text
- Multiple invalid IDs → Process only valid IDs, warn about invalid ones
- Memory limit exceeded during reference → Auto-evict and retry

---

## Cache Management

### `[System Clean Cache: cache_id]`

Removes cached content and frees associated memory.

**Syntax:**
```
[System Clean Cache: cache_id]
[System Clean Cache: id1,id2,id3]
[System Clean Cache]
```

**Parameters:**
- `cache_id` (optional): Specific cache to remove
- `id1,id2,id3` (alternative): Multiple caches to remove (comma-separated)
- No parameters: Remove all caches

**Behavior:**
- Immediately removes cached content and KV states
- Frees memory resources
- Updates memory usage statistics
- Returns confirmation of cleanup

**Examples:**
```
[System Clean Cache: temp_doc]
→ "Cache 'temp_doc' removed. 3.1MB freed."

[System Clean Cache: doc1,doc2,doc3]
→ "Caches 'doc1', 'doc2', 'doc3' removed. 15.7MB freed."

[System Clean Cache]
→ "All caches cleared. 45.2MB freed."
```

**Error Conditions:**
- `cache_id` not found → Log warning, return "Cache not found"
- No caches to clear → Return "No cached content to clear"

### `[System Cache Update: cache_id] new_content`

Updates existing cached content with new content.

**Syntax:**
```
[System Cache Update: cache_id] new_content
[System Cache Update: cache_id, ttl: seconds] new_content
```

**Parameters:**
- `cache_id` (required): Existing cache identifier to update
- `new_content` (required): Replacement content
- `ttl` (optional): New time-to-live in seconds

**Behavior:**
- Replaces existing cached content
- Recomputes KV cache states
- Preserves cache priority settings
- Returns update confirmation

**Examples:**
```
[System Cache Update: legal_doc] Updated contract with amendments: [NEW CONTENT]
→ "Cache 'legal_doc' updated (13,156 tokens, 19.8MB KV cache)"

[System Cache Update: temp_doc, ttl: 7200] Extended content with new TTL...
→ "Cache 'temp_doc' updated with 2 hour TTL (3,245 tokens, 4.9MB KV cache)"
```

**Error Conditions:**
- `cache_id` not found → Create new cache instead, warn user
- Update exceeds memory limits → Auto-evict oldest caches

---

## Cache Inspection

### `[System Cache Info]`

Provides information about current cached content.

**Syntax:**
```
[System Cache Info]
[System Cache Info: cache_id]
[System Cache Stats]
```

**Parameters:**
- No parameters: List all current caches
- `cache_id` (optional): Info about specific cache
- `Stats` variant: Overall memory usage statistics

**Behavior:**
- Returns metadata about cached content
- Shows memory usage and timestamps
- Provides performance statistics
- Does not affect cache state

**Examples:**
```
[System Cache Info]
→ "Current caches:
   - legal_doc: 12,845 tokens, 19.2MB, created 5m ago
   - temp_doc: 2,156 tokens, 3.1MB, TTL 45m remaining
   - user_prefs: 234 tokens, 0.4MB, priority: high"

[System Cache Info: legal_doc]
→ "Cache 'legal_doc': 12,845 tokens, 19.2MB KV cache, created 5m ago, last accessed 2m ago"

[System Cache Stats]
→ "Total cached: 3 items, 15,235 tokens, 22.7MB KV cache
   Memory usage: 22.7MB / 100MB limit (23%)
   Cache hits: 127, misses: 8, hit rate: 94%"
```

**Error Conditions:**
- `cache_id` not found → Return "Cache 'id' not found"
- No caches exist → Return "No cached content"

---

## Advanced Parameters

### Time-to-Live (TTL)

Controls how long cached content remains available.

**Syntax:**
```
ttl: seconds
```

**Values:**
- Positive integer: Seconds until expiration
- `0`: Use default session lifetime
- `-1` or omitted: No expiration (session lifetime)

**Examples:**
```
[System Cache: doc, ttl: 3600] Content...     # 1 hour
[System Cache: doc, ttl: 86400] Content...    # 24 hours
[System Cache: doc, ttl: 0] Content...        # Default session lifetime
```

### Priority Levels

Influences cache eviction order when memory is constrained.

**Syntax:**
```
priority: level
```

**Values:**
- `low`: First to be evicted
- `normal`: Default priority (if not specified)
- `high`: Last to be evicted

**Examples:**
```
[System Cache: temp, priority: low] Temporary content...
[System Cache: doc, priority: normal] Regular document...
[System Cache: critical, priority: high] Important content...
```

---

## Command Parsing Rules

### Syntax Requirements

1. **Case sensitive**: Commands must use exact capitalization
2. **Whitespace**: Single spaces around colons and commas
3. **Brackets**: Must use square brackets `[` and `]`
4. **Identifiers**: Alphanumeric characters and underscores only
5. **Position**: Commands should be at the beginning of user messages

### Valid Identifier Format

```regex
^[a-zA-Z0-9_]+$
```

**Valid examples:**
- `doc1`, `legal_document`, `user_preferences_2024`

**Invalid examples:**
- `doc-1` (hyphen not allowed)
- `legal document` (space not allowed)
- `file@example` (special characters not allowed)

### Parameter Parsing

**Key-value pairs:**
```
key: value
```

**Multiple parameters:**
```
key1: value1, key2: value2
```

**Parameter order:** Order doesn't matter, but consistency is recommended.

---

## Error Handling

### Malformed Commands

**Incomplete syntax:**
```
Input:  "[System Cache incomplete"
Action: Treat as regular text
Output: [Processed as normal conversation]
```

**Invalid parameters:**
```
Input:  "[System Cache: doc1, invalid_param: value] Content"
Action: Ignore invalid parameter, process valid ones
Output: "Content cached as 'doc1' (warning: unknown parameter 'invalid_param')"
```

### Resource Constraints

**Memory limit exceeded:**
```
Action: Auto-evict oldest caches using LRU policy
Output: "Memory limit reached. Evicted 'old_doc' to make space for 'new_doc'"
```

**Cache not found:**
```
Input:  "[System Cache Reference: nonexistent]"
Action: Log warning, continue processing
Output: [Process as regular text with warning logged]
```

### Graceful Degradation

When cache functionality is not available:
1. Parse commands but don't execute cache operations
2. Process content as regular text
3. Log warnings for debugging
4. Continue normal conversation flow

---

## Implementation Notes

### Performance Considerations

- **Parse early**: Process cache commands before tokenization
- **Store efficiently**: Keep both raw content and computed KV states
- **Memory bounds**: Implement configurable limits and LRU eviction
- **Mobile optimization**: Special handling for resource-constrained devices

### Security Considerations

- **Input validation**: Sanitize cache identifiers and content
- **Memory limits**: Prevent memory exhaustion attacks
- **Session isolation**: Ensure no cross-session cache access
- **Rate limiting**: Limit cache operations per time window

### Compatibility Requirements

- **Backward compatibility**: Gracefully handle unsupported operations
- **Version negotiation**: Optional version headers for capability detection
- **Standard fallback**: Continue processing when caching fails

---

## Quick Reference Card

| Command | Purpose | Example |
|---------|---------|---------|
| `[System Start Session]` | Initialize session | `[System Start Session]` |
| `[System Cache: id] content` | Cache content | `[System Cache: doc1] Text...` |
| `[System Cache Reference: id]` | Use cached content | `[System Cache Reference: doc1] Question?` |
| `[System Clean Cache: id]` | Remove cache | `[System Clean Cache: doc1]` |
| `[System Clean Cache]` | Clear all | `[System Clean Cache]` |
| `[System Cache Update: id] content` | Update cache | `[System Cache Update: doc1] New text...` |
| `[System Cache Info]` | List caches | `[System Cache Info]` |
| `[System Cache Stats]` | Memory stats | `[System Cache Stats]` |

### Common Parameters

| Parameter | Values | Purpose |
|-----------|--------|---------|
| `ttl` | Seconds | Auto-expiration |
| `priority` | `low`, `normal`, `high` | Eviction order |

---

**Related Documentation:**
- [Core Specification](core-specification.md) - Complete technical specification
- [Use Cases](use-cases.md) - Practical examples and patterns
- [Getting Started](../docs/getting-started.md) - Implementation guide