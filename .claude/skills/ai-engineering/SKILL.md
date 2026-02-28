---
name: ai-engineering
description: Designs AI/ML feature architectures including LLM integration, RAG pipelines, prompt engineering, and AI cost optimization. Use when building features that involve AI/ML components.
allowed-tools: Read, Grep, Glob, Bash, Write
---

# AI Engineering

## Reference
- **ID**: S-ENG-13
- **Category**: Engineering
- **Inputs**: approved PRD, company.config.yaml (ai.* section), existing RFCs, standards/engineering/ai-patterns.md
- **Outputs**: AI architecture section → artifacts/rfcs/ (as section within RFC)
- **Used by**: Engineering Agent (Staff Engineer level — not delegated to sub-agents)
- **Tool scripts**: ./tools/artifact/validate.sh

## Purpose

Design the AI/ML architecture for features that involve language models, retrieval-augmented generation, agent systems, or other AI components. This skill produces the AI-specific section of an RFC, covering model selection, integration patterns, prompt engineering, cost modeling, evaluation strategy, and ethical safeguards.

AI architecture is a cross-cutting concern that affects backend (API design, data pipelines), frontend (streaming UX, latency handling), and infrastructure (model hosting, vector databases, cost management). The Staff Engineer owns this skill directly rather than delegating to a sub-agent, ensuring architectural coherence across all domains.

## When to Use

- PRD or feature involves LLM integration (chat, summarization, classification, generation)
- Feature requires retrieval-augmented generation (RAG) with a knowledge base
- Building an agent system with tool use, multi-step reasoning, or orchestration
- Feature involves embeddings, semantic search, or vector databases
- Prompt engineering or structured output design is needed
- AI cost estimation or optimization is required for budgeting
- Feature needs AI safety review (guardrails, bias assessment, PII handling)

## AI Engineering Procedure

### Step 1: Load Context

Before designing any AI architecture:

1. **Read `company.config.yaml`** — extract `ai.*` section (llm_provider, llm_model, embedding_provider, vector_db, guardrails, cost_budget_monthly)
2. **Read the PRD** — identify all AI-related acceptance criteria and user-facing AI behaviors
3. **Read existing RFCs** in `artifacts/rfcs/` — check for prior AI architecture decisions, existing model integrations, or shared AI infrastructure
4. **Read `standards/engineering/ai-patterns.md`** — load reference patterns for LLM integration, RAG, cost optimization, and safety
5. **Check tech stack compatibility** — verify that the configured database, queue, and hosting can support the AI workload (e.g., pgvector requires PostgreSQL, streaming requires WebSocket or SSE support)

### Step 2: Classify AI Pattern

Determine which AI pattern(s) the feature requires. A feature may combine multiple patterns.

| Pattern | Description | Key Concerns |
|---------|-------------|--------------|
| **LLM API Call** | Direct call to a language model API (chat, completion, classification) | Latency, cost, fallback, streaming |
| **RAG Pipeline** | Retrieval-augmented generation with external knowledge | Chunking, embedding, retrieval quality, freshness |
| **Agent System** | Multi-step reasoning with tool use and orchestration | State management, tool design, loop control, cost caps |
| **Fine-tuning** | Custom model training on domain-specific data | Data pipeline, evaluation, versioning, cost |
| **Computer Vision** | Image/video analysis, OCR, visual understanding | Multimodal models, preprocessing, latency |
| **Recommendation** | Personalized content or action suggestions | Embedding similarity, feedback loops, cold start |

Document which patterns apply and why. If the pattern is unclear, default to the simplest option (LLM API Call) and note the uncertainty.

### Step 3: Design AI Architecture

For each classified pattern, produce the architecture design following these guidelines.

#### LLM Integration

1. **API Wrapper Design** — define the abstraction layer between your application and the LLM provider
   - Provider-agnostic interface (swap Anthropic/OpenAI/Google without code changes)
   - Request/response types with structured validation
   - Configuration: model name, temperature, max tokens, stop sequences
2. **Streaming vs Batch** — determine the delivery mode
   - Streaming (SSE/WebSocket): use for user-facing generation where perceived latency matters
   - Batch: use for background processing, classification, or bulk operations
   - Hybrid: stream to user, batch for internal processing
3. **Fallback Chains** — define behavior when the primary model fails
   - Primary model → fallback model → cached response → graceful error
   - Timeout thresholds per model tier (e.g., 30s for opus, 15s for sonnet, 5s for haiku)
   - Circuit breaker pattern for sustained failures
4. **Model Routing** — select the right model for the task
   - Simple tasks (classification, extraction) → smaller/faster model
   - Complex tasks (reasoning, generation) → larger model
   - Route based on: task complexity, latency requirement, cost sensitivity

#### RAG Pipeline

1. **Chunking Strategy** — how to split source documents
   - Chunk size: 512-1024 tokens for most use cases; smaller for precise retrieval, larger for context-heavy
   - Overlap: 10-20% overlap between chunks to preserve context boundaries
   - Strategy: semantic chunking (by heading/paragraph) preferred over fixed-size
2. **Embedding Model Selection** — choose based on configured `ai.embedding_provider`
   - Define embedding dimensions and distance metric (cosine similarity standard)
   - Plan for embedding model upgrades (versioned embedding collections)
3. **Vector Database Schema** — design based on configured `ai.vector_db`
   - Collection/index design: namespace by tenant (if multi-tenant), partition by document type
   - Metadata schema: source_id, chunk_index, created_at, tenant_id, document_type
   - Index configuration: HNSW parameters, quantization if needed
4. **Retrieval and Re-ranking** — define the retrieval pipeline
   - Initial retrieval: top-K (typically K=10-20) from vector search
   - Re-ranking: cross-encoder or LLM-based re-ranking for top results
   - Hybrid search: combine vector similarity with keyword search (BM25) when available
   - Context window assembly: order chunks, deduplicate, fit within token budget

#### Agent Systems

1. **Tool Design** — define the tools the agent can use
   - Each tool: name, description, input schema (JSON Schema), output format
   - Tool categories: read-only (safe to retry) vs write (idempotent or not)
   - Error handling: tool failure should not crash the agent loop
2. **Orchestration Patterns** — define how the agent operates
   - Single-turn: one tool call per request (simplest)
   - Multi-turn: iterative tool use with intermediate reasoning (ReAct pattern)
   - Multi-agent: specialized agents coordinated by an orchestrator
3. **State Management** — define how agent state is tracked
   - Conversation history: full vs windowed vs summarized
   - Tool call history: log all calls for debugging and audit
   - Checkpointing: save state at key decision points for recovery
4. **Safety Controls** — prevent runaway agent behavior
   - Maximum iterations per request (hard cap)
   - Maximum total tokens per request (cost cap)
   - Human-in-the-loop for destructive actions
   - Timeout per agent execution

### Step 4: Prompt Engineering

Design the prompt architecture for each AI interaction.

1. **System Prompt Design**
   - Define the role, capabilities, and constraints
   - Include output format specification (especially for structured outputs)
   - Specify what the model should NOT do (negative constraints)
   - Keep system prompts version-controlled and testable
2. **Few-Shot Examples**
   - Include 2-5 representative examples for classification or extraction tasks
   - Examples should cover: typical case, edge case, and negative case
   - Store examples alongside prompt templates for easy iteration
3. **Chain-of-Thought**
   - Use for complex reasoning tasks (multi-step math, logic, analysis)
   - Request explicit reasoning before the final answer
   - Consider whether reasoning should be visible to end users or hidden
4. **Structured Outputs**
   - Define JSON Schema for all machine-consumed outputs
   - Use constrained generation when available (tool_use, response_format)
   - Validate outputs against schema before processing downstream
   - Define fallback behavior for malformed outputs

### Step 5: Cost Model

Estimate and plan for AI operational costs.

1. **Token Estimation Per Request**
   - Input tokens: system prompt + user input + context (RAG chunks, history)
   - Output tokens: expected response length (cap with max_tokens)
   - Calculate per-request cost at current provider pricing
2. **Monthly Budget Projection**
   - Estimate requests per day/month based on expected usage patterns
   - Multiply by per-request cost for baseline monthly spend
   - Add buffer (2-3x) for growth and retries
   - Compare against `ai.cost_budget_monthly` from config
3. **Cost Optimization Strategies**
   - **Semantic caching**: cache responses for semantically similar inputs (embedding similarity > threshold)
   - **Model tier routing**: route simple tasks to cheaper models, reserve expensive models for complex tasks
   - **Batching**: group multiple small requests into batch API calls where latency allows
   - **Prompt optimization**: minimize system prompt tokens, compress context, use efficient few-shot formats
   - **Token budgets**: set per-request and per-user token limits to prevent cost spikes
   - **Response caching**: cache deterministic outputs (classification, extraction) with TTL

### Step 6: Evaluation Plan

Define how to measure AI feature quality.

1. **Accuracy Metrics**
   - Define task-specific metrics: precision/recall (classification), BLEU/ROUGE (generation), MRR/nDCG (retrieval)
   - Establish baseline from manual evaluation or existing system
   - Set target thresholds for production readiness
2. **Latency SLOs**
   - Define acceptable latency for each AI operation (p50, p95, p99)
   - Streaming: time to first token (TTFT) and tokens per second (TPS)
   - End-to-end: total request time including retrieval, generation, and post-processing
3. **Regression Testing**
   - Build an evaluation dataset (golden set) of input-output pairs
   - Run regression tests on prompt changes, model upgrades, or pipeline modifications
   - Automate evaluation in CI where possible (deterministic checks first, LLM-as-judge for subjective quality)
4. **A/B Testing**
   - Define the experiment: which AI variation to test (model, prompt, retrieval strategy)
   - Define the success metric: user satisfaction, task completion, accuracy
   - Plan the rollout: feature flag with percentage-based allocation

### Step 7: Ethical AI Checklist

Assess and mitigate AI-specific risks.

1. **Prompt Injection Protection**
   - Input validation: sanitize user inputs before including in prompts
   - System/user message separation: never concatenate user input into system prompts
   - Output validation: verify outputs match expected format and constraints
   - Indirect injection: assess risk from RAG content containing adversarial instructions
2. **Content Filtering**
   - Define output filtering rules: no harmful content, no PII generation, no hallucinated citations
   - Implement pre-response filtering (keyword blocklist, classifier, or LLM-based filter)
   - Configure guardrails based on `ai.guardrails` config setting
3. **Transparency and Explainability**
   - Clearly indicate AI-generated content to users (labeling requirement)
   - Provide source attribution for RAG-based answers when possible
   - Allow users to provide feedback on AI outputs (thumbs up/down, corrections)
4. **PII Handling in Prompts**
   - Audit all data flows: what user/customer data enters the LLM prompt?
   - Apply PII redaction before sending to external LLM providers
   - If PII must be sent: verify DPA (Data Processing Agreement) with provider
   - Log what data was sent to which model for compliance auditing
5. **Output Guardrails**
   - Define acceptable output boundaries (topic, format, length, tone)
   - Implement response validation before returning to users
   - Define fallback responses for when guardrails are triggered
   - Monitor guardrail trigger rate for threshold anomalies

### Step 8: Produce AI Architecture Section for RFC

Integrate the above into the RFC being produced by the architecture-draft skill. The AI architecture should appear as a dedicated section within the RFC, containing:

1. **AI Pattern Classification** — which patterns apply and why
2. **Architecture Diagram** — showing data flow through the AI pipeline
3. **Model Selection and Routing** — which models for which tasks, fallback chains
4. **Data Pipeline** — how data flows from source to embedding to retrieval to generation
5. **Prompt Specifications** — system prompts, structured output schemas (reference versioned prompt files)
6. **Cost Projection** — per-request and monthly cost estimates with optimization plan
7. **Evaluation Strategy** — metrics, baselines, targets, regression test plan
8. **AI Safety Measures** — prompt injection protection, guardrails, PII handling, bias assessment
9. **Infrastructure Requirements** — vector database, model hosting, caching layer, queue for async AI tasks

This section should be self-contained enough that a backend engineer can implement the AI pipeline without additional context.

### Step 9: Validate

Run artifact validation on the RFC containing the AI architecture section.

- [ ] AI pattern classification is explicit and justified
- [ ] Model selection matches `ai.llm_provider` and `ai.llm_model` from config (or deviation is documented)
- [ ] RAG pipeline design includes chunking, embedding, retrieval, and re-ranking (if RAG pattern)
- [ ] Prompt specifications are detailed enough to implement (system prompt, output schema)
- [ ] Cost model includes per-request and monthly estimates
- [ ] Cost stays within `ai.cost_budget_monthly` (or overrun is flagged with justification)
- [ ] Evaluation plan has concrete metrics and targets
- [ ] Ethical AI checklist is addressed (all 5 areas: injection, filtering, transparency, PII, guardrails)
- [ ] Infrastructure requirements are compatible with configured tech stack
- [ ] Artifact frontmatter is complete (`./tools/artifact/validate.sh`)

## Quality Checklist

- [ ] `company.config.yaml` `ai.*` section was read and respected
- [ ] `standards/engineering/ai-patterns.md` was consulted for reference patterns
- [ ] AI pattern correctly classified (not over-engineered for the use case)
- [ ] Architecture supports provider swapping (not locked to one LLM vendor)
- [ ] Streaming vs batch decision is justified by UX requirements
- [ ] Fallback chain handles provider outages gracefully
- [ ] Cost model is realistic and within budget (or overrun explicitly flagged)
- [ ] Prompt engineering follows best practices (structured outputs, few-shot, CoT where appropriate)
- [ ] Evaluation plan includes both automated and human assessment
- [ ] All ethical AI checklist items are addressed (not skipped)
- [ ] PII handling is documented and compliant
- [ ] AI architecture section integrates cleanly into the RFC structure
