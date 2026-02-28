# AI Engineering Patterns Reference

This document defines standard patterns, best practices, and decision guides for AI/ML feature development. Agents and engineers reference this when designing, implementing, or reviewing AI features.

---

## LLM Integration Patterns

### Direct API Call

The simplest pattern: application sends a request to an LLM API and receives a response.

```
[Application] → [LLM Provider API] → [Response]
```

**When to use**: Classification, extraction, summarization, single-turn generation.

**Implementation guidance**:
- Wrap the provider SDK in an abstraction layer (provider-agnostic interface)
- Define request/response types with validation (never pass raw API responses upstream)
- Set explicit timeouts per model tier
- Log request metadata (model, tokens, latency) for cost tracking and debugging

```
interface LLMRequest {
  model: string
  messages: Message[]
  temperature?: number
  max_tokens?: number
  response_format?: JSONSchema
}

interface LLMResponse {
  content: string
  usage: { input_tokens: number, output_tokens: number }
  model: string
  latency_ms: number
}
```

### Streaming

Server-sent events (SSE) or WebSocket delivery of partial responses as they are generated.

```
[Application] → [LLM API] → [SSE/WS stream] → [Client renders incrementally]
```

**When to use**: User-facing chat interfaces, long-form generation, any interaction where perceived latency matters.

**Implementation guidance**:
- Use SSE for unidirectional streaming (most common)
- Use WebSocket only if bidirectional communication is needed
- Buffer partial tokens before sending to client (avoid sending incomplete words)
- Track time-to-first-token (TTFT) as a key latency metric
- Implement client-side abort: user should be able to stop generation mid-stream
- Handle stream interruptions gracefully (network errors, provider timeouts)

### Function Calling / Tool Use

The model selects and invokes structured tools based on the conversation context.

```
[User message] → [LLM] → [Tool selection + arguments] → [Tool execution] → [LLM] → [Response]
```

**When to use**: When the AI needs to take actions (database queries, API calls, calculations) or access real-time information.

**Implementation guidance**:
- Define tools with precise JSON Schema input specifications
- Categorize tools: read-only (safe to retry) vs write (require confirmation or idempotency)
- Validate tool arguments before execution (the model may produce invalid inputs)
- Return tool results in a structured format the model can interpret
- Set a maximum number of tool calls per request to prevent infinite loops
- Log all tool calls for debugging and audit

### Structured Outputs

Force the model to produce responses conforming to a specific JSON Schema.

**When to use**: Any machine-consumed output (data extraction, classification labels, API response generation).

**Implementation guidance**:
- Use provider-native structured output features when available (Anthropic tool_use, OpenAI response_format)
- Define the schema explicitly with required fields, types, and descriptions
- Always validate the output against the schema after generation (defense in depth)
- Define fallback behavior for schema validation failures (retry with clearer prompt, return error)

```json
{
  "type": "object",
  "properties": {
    "sentiment": { "type": "string", "enum": ["positive", "negative", "neutral"] },
    "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
    "reasoning": { "type": "string" }
  },
  "required": ["sentiment", "confidence"]
}
```

---

## RAG Architecture Patterns

### Naive RAG

Basic retrieval-augmented generation: embed query, find similar chunks, stuff into context.

```
[Query] → [Embed] → [Vector Search (top-K)] → [Stuff into prompt] → [LLM] → [Response]
```

**When to use**: Simple knowledge base Q&A, documentation search, FAQ answering.

**Limitations**: No re-ranking, no hybrid search, retrieval quality depends entirely on embedding similarity.

**Implementation guidance**:
- Chunk size: 512 tokens for precise retrieval, 1024 for more context
- Top-K: start with K=5, tune based on retrieval quality evaluation
- Include chunk metadata (source, section title) in the prompt for attribution
- Monitor retrieval relevance with user feedback

### Advanced RAG with Re-ranking

Adds a re-ranking step to improve retrieval quality beyond embedding similarity.

```
[Query] → [Embed] → [Vector Search (top-K=20)] → [Re-ranker (top-N=5)] → [LLM] → [Response]
```

**When to use**: When naive RAG retrieval quality is insufficient, domain-specific knowledge bases, high-stakes answers.

**Implementation guidance**:
- Retrieve more candidates than needed (K=20), re-rank to top N (N=3-5)
- Re-ranking options: cross-encoder model, LLM-based re-ranking, Cohere Rerank API
- Re-ranking adds latency (50-200ms) — factor into SLO budget
- Evaluate re-ranking impact: compare MRR/nDCG before and after

### Hybrid Search

Combines vector similarity search with keyword search (BM25) for better recall.

```
[Query] → [Embed + Tokenize] → [Vector Search + BM25 Search] → [Reciprocal Rank Fusion] → [Re-rank] → [LLM]
```

**When to use**: When queries contain specific terms (product names, error codes, technical jargon) that embedding similarity may miss.

**Implementation guidance**:
- Use reciprocal rank fusion (RRF) to merge results from both search methods
- Weight tuning: start with 0.5/0.5, adjust based on evaluation
- BM25 availability: pgvector + pg_trgm (PostgreSQL), native in Elasticsearch/Weaviate
- Hybrid search is most valuable for technical documentation and domain-specific corpora

### RAG Data Pipeline

The ingestion side of RAG: how documents become searchable chunks.

```
[Source Documents] → [Extract Text] → [Chunk] → [Embed] → [Store in Vector DB] → [Index]
```

**Implementation guidance**:
- **Text extraction**: handle PDF, HTML, Markdown, DOCX — use appropriate parsers
- **Chunking strategies**:
  - Fixed-size: simple, predictable, but may split sentences/concepts
  - Semantic: split by headings, paragraphs, or topic boundaries — better quality, more complex
  - Recursive: split large chunks into smaller ones until they fit the size target
- **Chunk overlap**: 10-20% overlap preserves context at boundaries
- **Metadata enrichment**: attach source URL, document title, section heading, date, author
- **Incremental updates**: support adding/updating/deleting individual documents without full re-index
- **Embedding versioning**: track which embedding model version was used — re-embed when upgrading models

---

## Vector Database Selection Guide

Choose based on the configured `ai.vector_db` value. All options support the core operations: insert, search (ANN), filter, delete.

### pgvector (PostgreSQL Extension)

**Best for**: Teams already using PostgreSQL who want to avoid a separate vector database.

| Aspect | Details |
|--------|---------|
| **Hosting** | Runs inside your existing PostgreSQL instance |
| **Scale** | Good for up to ~5M vectors; performance degrades beyond that without partitioning |
| **Hybrid search** | Combine with pg_trgm for BM25-like keyword search in the same query |
| **Multi-tenancy** | Native — use RLS or tenant_id column, same as your application data |
| **Cost** | No additional infrastructure cost |
| **Limitations** | Slower than purpose-built vector DBs at scale; HNSW index tuning required for large collections |

**When to choose**: MVP/early-stage products, PostgreSQL already in stack, less than 1M vectors, want simplicity.

### Pinecone

**Best for**: Teams that want a fully managed vector database with minimal operational burden.

| Aspect | Details |
|--------|---------|
| **Hosting** | Fully managed SaaS |
| **Scale** | Handles billions of vectors with automatic scaling |
| **Hybrid search** | Supports sparse-dense hybrid via sparse vectors |
| **Multi-tenancy** | Namespace-based isolation within an index |
| **Cost** | Usage-based pricing; can be expensive at scale |
| **Limitations** | Vendor lock-in; no self-hosted option; limited query flexibility |

**When to choose**: Production-scale RAG, need high availability without ops overhead, budget allows SaaS pricing.

### Weaviate

**Best for**: Teams that need a feature-rich vector database with built-in ML modules.

| Aspect | Details |
|--------|---------|
| **Hosting** | Self-hosted (Docker/K8s) or Weaviate Cloud |
| **Scale** | Good horizontal scaling; handles millions to billions of vectors |
| **Hybrid search** | Native BM25 + vector hybrid search |
| **Multi-tenancy** | Native multi-tenancy support with tenant-level isolation |
| **Cost** | Open-source core; cloud pricing for managed |
| **Limitations** | More complex to operate self-hosted; learning curve for GraphQL-like API |

**When to choose**: Need hybrid search natively, want self-hosted option, building a complex search application.

### Chroma

**Best for**: Prototyping and development; lightweight embedding database.

| Aspect | Details |
|--------|---------|
| **Hosting** | In-process (Python) or client-server |
| **Scale** | Suitable for up to ~1M vectors; not designed for production scale |
| **Hybrid search** | Basic metadata filtering; no native keyword search |
| **Multi-tenancy** | Collection-based separation |
| **Cost** | Free, open-source |
| **Limitations** | Not production-grade for high-throughput or large-scale deployments |

**When to choose**: Local development, prototyping, proof-of-concept RAG applications, small datasets.

### Decision Matrix

| Factor | pgvector | Pinecone | Weaviate | Chroma |
|--------|----------|----------|----------|--------|
| Setup complexity | Low (if using PG) | Low (SaaS) | Medium | Low |
| Production readiness | High | High | High | Low |
| Scale ceiling | Medium | Very high | High | Low |
| Hybrid search | With pg_trgm | Sparse vectors | Native | No |
| Multi-tenancy | Native (RLS) | Namespaces | Native | Collections |
| Cost at scale | Low | High | Medium | Free |
| Operational burden | Low (existing PG) | None | Medium-High | Low |

---

## Prompt Engineering Best Practices

### System Prompts

The system prompt defines the AI's role, capabilities, constraints, and output format.

**Structure**:
1. **Role definition** — who the AI is and what it does
2. **Capabilities** — what the AI can do (tools, knowledge scope)
3. **Constraints** — what the AI must NOT do (boundaries, refusals)
4. **Output format** — how to structure responses (especially for structured outputs)
5. **Context** — any persistent context (company name, product details, user role)

**Best practices**:
- Keep system prompts as concise as possible (every token costs money)
- Use clear section headers within the system prompt
- Test system prompts with adversarial inputs (prompt injection attempts)
- Version control system prompts alongside application code
- Monitor prompt performance: track when the model ignores instructions

### Few-Shot Examples

Include input-output examples in the prompt to guide model behavior.

**Best practices**:
- Use 2-5 examples for most tasks (diminishing returns beyond 5)
- Include: typical case, edge case, and negative/rejection case
- Format examples consistently with the expected output format
- Store examples in a retrievable format (database or file) for easy iteration
- For classification: include examples from each class, especially underrepresented ones

### Chain-of-Thought (CoT)

Request step-by-step reasoning before the final answer.

**When to use**: Multi-step reasoning, mathematical calculations, complex classification, decision-making.

**Patterns**:
- Explicit CoT: "Think step by step before answering"
- Structured CoT: "First analyze X, then consider Y, then conclude Z"
- Hidden CoT: Request reasoning in a separate field, show only the conclusion to users

**Best practices**:
- CoT increases output tokens (and cost) — use only when reasoning quality matters
- Verify that the reasoning actually improves output quality (A/B test)
- For structured outputs, put the reasoning field BEFORE the answer field (the model reasons sequentially)

### Structured Output Design

Design JSON schemas for machine-consumed outputs.

**Best practices**:
- Use enums for categorical fields (forces model to choose from valid options)
- Include a `confidence` field when classification certainty matters
- Include a `reasoning` or `explanation` field for debuggability
- Set `required` fields explicitly — optional fields may be omitted unpredictably
- Test schema with edge cases: what happens with empty input, ambiguous input, adversarial input?
- Use nested objects sparingly (increases schema complexity and error rate)

---

## Cost Optimization Strategies

### Semantic Caching

Cache LLM responses and serve cached results for semantically similar future queries.

```
[Query] → [Embed query] → [Search cache (similarity > threshold)] → [Cache hit: return cached] / [Cache miss: call LLM, cache result]
```

**Implementation guidance**:
- Similarity threshold: 0.95+ for high-precision caching (conservative), 0.90 for broader caching
- Cache TTL: set based on content freshness requirements (hours for dynamic content, days for static)
- Cache key: query embedding + relevant context hash (different context = different cache entry)
- Monitor: cache hit rate, false positive rate (serving stale/wrong cached responses)
- Estimated savings: 20-40% reduction in LLM API calls for typical SaaS applications

### Model Tier Routing

Route requests to the cheapest model that can handle the task adequately.

```
[Request] → [Complexity classifier] → [Simple: haiku/mini] / [Medium: sonnet/4o] / [Complex: opus/o1]
```

**Implementation guidance**:
- Define task complexity heuristics: input length, required reasoning depth, output format complexity
- Start with a simple rule-based router (task type → model), evolve to ML-based routing if needed
- Monitor quality metrics per model tier to detect when a cheaper model is insufficient
- Estimated savings: 50-80% cost reduction when most traffic is simple tasks

### Batching

Group multiple requests into a single batch API call for reduced per-request cost.

**When to use**: Background processing, bulk classification, document processing, non-real-time tasks.

**Implementation guidance**:
- Use provider batch APIs where available (typically 50% cost discount)
- Set batch size limits and timeouts (do not wait indefinitely to fill a batch)
- Ensure idempotent processing (retries should not produce duplicates)
- Monitor batch processing latency vs real-time SLOs

### Token Budget Management

Set explicit limits on token usage per request, per user, and per billing period.

**Implementation guidance**:
- **Per-request**: set `max_tokens` on every LLM call; truncate context to fit input budget
- **Per-user**: track cumulative token usage per user per day/month; enforce soft limits (warnings) and hard limits (denial)
- **Per-billing-period**: alert at 50%, 75%, 90% of `ai.cost_budget_monthly`; auto-degrade to cheaper models at 90%
- **Context compression**: summarize conversation history instead of sending full history; use RAG to inject only relevant context

---

## AI Safety and Ethics Checklist

Use this checklist when designing or reviewing any AI feature. All items should be addressed in the RFC's AI architecture section.

### 1. Prompt Injection Protection

Prompt injection occurs when user input is crafted to override system instructions.

**Mitigations**:
- [ ] User input is placed in clearly delimited user message blocks (never concatenated into system prompts)
- [ ] Input validation: reject or sanitize inputs containing suspicious patterns (e.g., "ignore previous instructions")
- [ ] Output validation: verify outputs match expected format and do not contain system prompt content
- [ ] For RAG: assess risk of indirect injection from ingested documents
- [ ] Test with known prompt injection attacks before launch

### 2. Output Filtering

Prevent the AI from generating harmful, inappropriate, or incorrect content.

**Mitigations**:
- [ ] Content classifier on outputs (harmful content, PII, profanity) before returning to users
- [ ] Blocklist for known problematic output patterns
- [ ] Hallucination mitigation: for factual claims, require source attribution or confidence scores
- [ ] Configurable filtering level based on use case (strict for public-facing, relaxed for internal tools)
- [ ] Guardrails framework configured (`ai.guardrails` from config)

### 3. Bias Assessment

AI systems can perpetuate or amplify biases present in training data.

**Mitigations**:
- [ ] Evaluate outputs across demographic groups for fairness (if applicable to use case)
- [ ] Document known biases and limitations of the chosen model
- [ ] For recommendation/ranking features: test for popularity bias, position bias, demographic bias
- [ ] Establish a process for users to report biased outputs
- [ ] Regular bias audits as part of model/prompt updates

### 4. PII Handling

Personal Identifiable Information requires special care in AI pipelines.

**Mitigations**:
- [ ] Audit all data flows: map exactly what user data enters each LLM prompt
- [ ] Apply PII redaction before sending to external LLM providers (names, emails, addresses, SSNs)
- [ ] If PII must be sent: verify Data Processing Agreement (DPA) with the LLM provider
- [ ] Log what data categories were sent to which model (for compliance auditing)
- [ ] Implement data retention policies for LLM interaction logs
- [ ] For RAG: ensure source documents do not contain PII that should not be retrievable

### 5. Transparency and User Control

Users should understand when they are interacting with AI and have control over it.

**Mitigations**:
- [ ] AI-generated content is clearly labeled (e.g., "Generated by AI" indicator)
- [ ] Users can provide feedback on AI outputs (thumbs up/down, corrections, reporting)
- [ ] Source attribution provided for RAG-based answers when possible
- [ ] Users can opt out of AI features where feasible
- [ ] AI decision explanations available for consequential decisions (e.g., content moderation, recommendations)

### 6. Cost Guardrails

Prevent unexpected cost spikes from AI API usage.

**Mitigations**:
- [ ] Per-request token limits set on all LLM calls (`max_tokens`)
- [ ] Per-user rate limiting on AI-powered endpoints
- [ ] Monthly budget monitoring with alerts at 50%, 75%, 90% thresholds
- [ ] Auto-degradation to cheaper models when approaching budget limits
- [ ] Circuit breaker: disable AI features entirely if budget is exhausted (graceful fallback to non-AI behavior)
- [ ] Cost anomaly detection: alert on sudden usage spikes (potential abuse or bug)
