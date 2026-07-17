# SKATE Memory Architecture and Differentiation

## Executive summary

SKATE does **not** currently use Mem0, LangChain, LlamaIndex, a hosted vector database, or another packaged agent-memory framework.

SKATE uses a **custom, local-first memory architecture** designed specifically for workshops, consulting engagements, and facilitated work. Open-source components provide file parsing and optional embedding generation, while SKATE owns the domain model, retrieval policy, context assembly, graph construction, governance, and design-thinking synthesis.

The simplest accurate description is:

> SKATE is a markdown-native, human-governed organizational memory engine with hybrid retrieval, typed evidence relationships, token-bounded agent context, and a design-thinking synthesis layer called The GRIND.

This approach implements many of the strongest concepts found in modern agent-memory systems without making an opaque memory service the source of truth.

---

## What memory system does SKATE use?

SKATE's memory system is composed of five layers:

1. **Markdown and YAML frontmatter as durable memory**
2. **A SKATE-owned typed memory schema**
3. **Hybrid lexical and semantic retrieval**
4. **Token-bounded context assembly for agents**
5. **The GRIND for graph-based consolidation and synthesis**

No single external product provides this complete system. It is a purpose-built architecture assembled around open standards and optional open-source embedding tools.

### Component map

| Layer | Current technology | Role | Local/open-source status |
|---|---|---|---|
| Durable memory | Markdown files plus YAML frontmatter | Human-readable source of truth | Local and open format |
| Metadata parser | [`python-frontmatter`](https://github.com/eyeseast/python-frontmatter) | Reads and writes YAML metadata and markdown content | Open source |
| Domain model | SKATE `Entry` model and memory-object schema | Sessions, types, status, themes, participants, sources, and relationships | SKATE-owned code |
| Lexical retrieval | SKATE weighted keyword retrieval | Exact names, terminology, tags, themes, and title matching | SKATE-owned code |
| Local semantic option 1 | [Ollama](https://github.com/ollama/ollama) plus `nomic-embed-text` | Local embedding generation | Ollama is MIT; Nomic Embed is Apache-2.0 |
| Local semantic option 2 | [FastEmbed](https://github.com/qdrant/fastembed) with `BAAI/bge-small-en-v1.5` | Lightweight CPU/ONNX embedding generation | FastEmbed is Apache-2.0 |
| Optional cloud fallback | OpenAI `text-embedding-3-small` | Embeddings when an OpenAI key is configured | Cloud and proprietary; not required |
| Similarity calculation | SKATE cosine similarity | Scores query and note vectors | SKATE-owned, Python standard-library math |
| Embedding cache | Content-hash JSON cache | Avoids re-embedding unchanged notes | Local, rebuildable cache |
| Agent context | SKATE Top-K context builder | Sends a small evidence set to Spotter instead of the whole vault | SKATE-owned code |
| Associative memory | Typed relationships and shared themes | Preserves causal, evidentiary, and semantic connections | SKATE-owned code |
| Consolidation | The GRIND | Converts connected evidence into design-thinking outputs | SKATE-owned code |

### Best-of-breed does not mean one dependency

SKATE is not claiming that a single library is the universally best memory framework. Its best-of-breed approach is architectural:

- Use **plain markdown** for durability and portability.
- Use **structured metadata** for reliable filtering and governance.
- Use **local embedding tools** when semantic retrieval adds value.
- Preserve **lexical matching** for exact client names and project language.
- Keep embeddings as a **rebuildable index**, not the source of truth.
- Retrieve a **small Top-K evidence set** instead of dumping the vault into a prompt.
- Keep every generated conclusion connected to **human-readable evidence**.
- Allow a human to activate, deactivate, edit, and correct organizational memory.

This is closer to a governed organizational-memory system than a generic vector-store chatbot.

---

## The memory model

### Episodic memory

Sessions provide the episode around a memory: which workshop it came from, when it occurred, and what engagement it belongs to.

This prevents an observation from becoming an unqualified global fact. A volunteer's statement remains evidence from a particular workshop rather than being silently generalized across every client or project.

### Semantic memory

Every memory object can carry:

- An object type
- Themes
- Tags
- A summary
- Participants
- Source and provenance
- Active or inactive status

The current schema includes 14 object types, including notes, observations, pains, quotes, hypotheses, decisions, recommendations, actions, risks, questions, opportunities, solutions, insights, and processes.

### Associative and causal memory

SKATE supports explicit typed relationships:

- `supports`
- `contradicts`
- `causes`
- `leads_to`
- `references`
- `similar_to`

These links preserve more meaning than a generic backlink. They make it possible to represent an evidence chain:

```text
Observation
    causes
Pain point
    supports
Insight
    leads_to
Recommendation
```

Shared themes create an additional associative layer, while degree caps prevent highly reused themes from overwhelming the graph.

### Consolidated memory

SKATE has two consolidation levels:

1. **Compress Note** reduces noisy notes or transcripts into a more useful, high-signal memory object.
2. **The GRIND** combines evidence across an active session into higher-order pain points, How-Might-We prompts, and solution starters.

Consolidation does not replace the original notes. Outputs remain connected to their source evidence.

---

## Hybrid retrieval and token efficiency

Spotter does not need every note in a session for every question.

SKATE first limits retrieval to the selected session. It then calculates:

- **60% semantic similarity**, when an embedding backend is available
- **40% normalized lexical relevance**

Lexical relevance weights titles, tags, and themes more heavily than general body text. If embeddings are unavailable, SKATE falls back to lexical retrieval. If no lexical result matches, it falls back to recent notes so the agent still receives grounded context.

### What enters embedding space

SKATE represents a note using:

- Title
- Themes
- Tags
- Up to 800 characters of its summary or body

The resulting vector is cached by a content hash. Unchanged notes do not need to be embedded again.

### What enters the agent prompt

For a typical Spotter question, SKATE currently:

- Retrieves the top five notes
- Uses a short excerpt of approximately 320 characters from each note
- Caps retrieved session context at approximately 3,500 characters
- Keeps the separate workshop-methodology context bounded as well

This does not magically make model tokens free. It reduces token use by avoiding this pattern:

```text
Every full note and transcript -> model on every request
```

and replacing it with:

```text
Question -> retrieve five relevant memories -> bounded evidence context -> model
```

Benefits include:

- Fewer repeated input tokens
- Lower latency and cost
- Less irrelevant context
- Better grounding
- Reduced accidental disclosure of unrelated notes
- More stable performance as the vault grows

The submission should not claim a precise token-saving percentage until SKATE runs a repeatable before-and-after benchmark.

---

## Agent loops and reasoning-based retrieval

SKATE does **not** need a swarm of autonomous agents to be competitive. Agent loops are a control pattern, not a substitute for a strong memory model. Adding several agents that repeatedly call one another would increase latency, token use, failure modes, and demo risk without necessarily improving the product.

The valuable addition is one **bounded, inspectable evidence loop**:

```text
Understand the request
    -> apply session, date, status, and type filters
    -> retrieve candidate memories
    -> inspect whether the evidence is sufficient
    -> follow relationships or retrieve once more if needed
    -> synthesize an answer or GRIND output
    -> verify citations against source notes
    -> return the result with provenance
```

The loop should have a maximum number of retrieval passes, a token budget, visible progress, and an evidence requirement. It should stop or say that evidence is insufficient rather than inventing an answer.

### Recommended bounded loops

1. **Spotter evidence loop:** Retrieve, assess sufficiency, optionally expand once through typed relationships, then answer with source-note links.
2. **GRIND synthesis loop:** Collect evidence, identify patterns and tensions, generate divergent How-Might-We prompts and ideas, rank them through desirability/feasibility/viability, then run a citation check.
3. **Memory consolidation loop:** Detect duplicate or contradictory candidates, propose a merge or relationship, and require human approval before changing durable memory.

These are meaningful agent behaviors because each pass has a distinct job and produces a trace. An open-ended “keep thinking” loop is not recommended for the hackathon.

### PageIndex assessment

[VectifyAI PageIndex](https://github.com/VectifyAI/PageIndex) is an MIT-licensed, reasoning-based retrieval project for long, hierarchical documents. It creates a table-of-contents-like tree and lets a model navigate that tree instead of relying only on vector similarity. It is especially relevant to long PDFs, reports, manuals, and other documents whose section structure carries meaning. The project supports PDF and markdown indexing and also publishes an MCP implementation.

PageIndex should **not replace SKATE's current memory system**:

- SKATE memories are already small, typed, session-scoped objects rather than hundreds of pages inside one document.
- SKATE must retrieve exact names, tags, dates, status, types, and relationships; vectorless tree search alone does not replace those filters.
- SKATE's graph contains evidence and causal relationships that a document table of contents does not express.
- PageIndex tree construction and reasoning can require model calls, adding latency, cost, and privacy considerations to a local-first product.
- Replacing the existing retrieval path before the hackathon would add integration risk without proving that retrieval improved.

The best approach is a **retrieval router**, not a winner-take-all memory backend:

| Information need | Preferred retrieval path |
|---|---|
| Exact person, project, tag, date, type, or status | Structured filters plus lexical retrieval |
| Conceptually related workshop memories | Current hybrid lexical and semantic retrieval |
| Evidence connected by `supports`, `causes`, or another typed rail | Relationship traversal |
| A long imported PDF, policy, report, manual, or research document | Optional PageIndex-style hierarchical retrieval |
| Complex question spanning several sources | Bounded evidence loop across the relevant paths |

### What SKATE should borrow from PageIndex now

- **Hierarchical summaries:** Maintain compact summaries at vault, project, session, and note level.
- **Reasoning traces:** Record why each memory or section was selected, not only its similarity score.
- **Natural boundaries:** Retrieve complete note sections or structured objects rather than arbitrary text fragments whenever possible.
- **Progressive disclosure:** Give the agent a small overview first, then allow it to open only the evidence it needs.
- **Traceable references:** Preserve session, note, section, and source links in every answer and GRIND output.

### PageIndex-related checklist

- [ ] **Create a project/session memory tree.** Generate short project and session summaries above the existing note objects so an agent can choose a branch before opening individual notes.
- [ ] **Add a retrieval-reason field.** Return the matching filters, keywords, semantic score, relationship path, or hierarchy decision with each retrieved result.
- [ ] **Add one bounded second-pass retrieval step.** Permit Spotter or The GRIND to expand through relationships when the first evidence set is insufficient.
- [ ] **Add a citation validator.** Confirm that generated factual claims are supported by the cited note text before returning them.
- [ ] **Evaluate an optional PageIndex adapter after the core demo is stable.** Use it only for imported long-form documents and keep markdown memory as SKATE's source of truth.
- [ ] **Benchmark the adapter before shipping it.** Compare answer accuracy, latency, token use, local/privacy behavior, and citation quality against SKATE's hybrid baseline.

### Hackathon priority decision

For the competitive submission, the implementation order should be:

1. Working GPT-5.6 path
2. Working MCP server and Codex retrieval demo
3. Retrieval evaluation and measured context reduction
4. One bounded, visible evidence loop with citations
5. GRIND idea-generation and experiment workflow
6. Optional project/session hierarchy
7. PageIndex adapter for long documents only if the preceding work is stable

A working MCP retrieval call with a visible evidence trace is more valuable to judges than claiming several agents or installing another retrieval library. PageIndex becomes strategically useful when SKATE needs to ingest long professional documents; it is not required to validate SKATE's primary workshop-memory architecture.

---

## Why SKATE does not use Mem0

[Mem0](https://github.com/mem0ai/mem0) is an agent-memory framework intended to extract, store, and retrieve personalized memories for AI applications. SKATE currently implements its memory behavior directly instead.

That choice is intentional for the hackathon architecture:

- SKATE requires a workshop-specific typed schema rather than generic preference memories.
- Markdown must remain the durable source of truth.
- Human review and provenance are central requirements.
- Sessions and active/inactive controls govern analytical scope.
- Causal and evidence relationships power The GRIND.
- The app must remain useful even when AI and embedding services are unavailable.

Mem0 could potentially become an optional adapter later, but it is not necessary to validate SKATE's core product. Adding it merely for branding would introduce another abstraction without strengthening the differentiated workflow.

The accurate statement is:

> SKATE implements modern agent-memory patterns directly, adapted to governed workshop and organizational memory; it does not currently depend on Mem0.

---

## Where MCP fits

MCP is **not** the memory engine. MCP is the implemented interface through which ChatGPT Work, Codex, and other agents can use the memory engine.

The repository contains a functioning, read-only SKATE MCP server that has been protocol-tested over STDIO and Streamable HTTP. Local Codex, ChatGPT desktop, and hosted ChatGPT Work connections are working and included in releases.

The SKATE MCP server exposes:

- `list_active_sessions`
- `search_memory`
- `get_memory_object`
- `get_session_context`
- `trace_evidence`
- `get_grind_outputs`
- ChatGPT-compatible `search` and `fetch` wrappers

The intended flow is:

```text
ChatGPT Work or Codex
        |
        | MCP tool request
        v
SKATE session governance and hybrid retrieval
        |
        | small evidence-backed result
        v
Agent context and response
```

This lets an external agent retrieve only the permitted, relevant evidence rather than receiving an entire notebook or transcript. Every tool is read-only, excludes inactive memory, bounds result size, and blocks arbitrary filesystem access.

---

## Why SKATE is not another Obsidian

SKATE intentionally shares one excellent property with Obsidian: the user's knowledge remains in portable markdown files. The product objective is different.

Obsidian is a flexible, general-purpose personal knowledge environment. SKATE is an opinionated workshop-memory and design-thinking system for consultants, facilitators, project managers, and organizational teams.

| Capability | Obsidian's general model | SKATE's native model |
|---|---|---|
| Primary purpose | General personal knowledge management | Workshop capture, organizational learning, and facilitated change |
| Structure | User-defined notes and links | Typed memory objects with sessions, themes, status, provenance, and evidence relationships |
| Capture | Primarily user-authored notes and plugins | Manual notes, meeting transcripts, Spotter, Spotter Live, and structured signal buttons |
| Relationships | Links and backlinks | Typed evidence rails: supports, contradicts, causes, leads to, references, and similar to |
| Graph | Navigation and exploration | Evidence exploration plus session-scoped analytical input |
| AI context | Depends on plugins and user configuration | Built-in hybrid retrieval and token-bounded session context |
| Governance | Flexible user conventions | Active/inactive sessions and notes define GRIND scope |
| Synthesis | Not a core native workflow | The GRIND generates grounded design-thinking outputs |
| Physical interaction | Keyboard, mouse, and community extensions | Spotter microphone puck plus Stream Deck Neo facilitation controls |
| Deliverables | Notes and knowledge navigation | Pain points, How-Might-We prompts, solution starters, traceable sources, and Excel export |

Obsidian can be extended through plugins, and SKATE does not claim those extensions are impossible. The distinction is that SKATE makes this complete facilitation workflow the product's native, opinionated experience.

### The differentiated loop

```text
Room conversation
        v
Structured workshop signals
        v
Durable, governed markdown memory
        v
Hybrid agent retrieval
        v
Typed evidence graph
        v
The GRIND
        v
Traceable design-thinking deliverables
```

The GRIND is the central differentiator. It is not simply a visualization of backlinks. It uses active session evidence to produce ranked workshop synthesis while keeping the original notes available for inspection.

Spotter extends that system into the physical workshop. A conference microphone-array puck housed in a custom 3D-printed skateboard wheel acts as the room capture device. The Stream Deck Neo acts as a human-machine interface, allowing a facilitator to activate coaching stances without breaking eye contact or returning to a keyboard.

---

## Current implementation boundaries

The following distinctions should remain explicit in the README, demo, and Devpost submission:

### Implemented

- Markdown and YAML memory objects
- Session, type, theme, tag, source, participant, and status metadata
- Typed relationships
- Hybrid semantic and lexical retrieval
- Local content-hash embedding cache
- Top-five bounded Spotter context
- Active/inactive filtering for The GRIND
- The GRIND 2D/3D graph and design-thinking synthesis
- Source-note traceability and Excel export
- Spotter and Spotter Live
- Stream Deck Neo hotkeys and custom icons
- Custom skateboard-wheel microphone housing and documentation
- Read-only MCP server with nine tools
- STDIO and Streamable HTTP transports
- Active-session and active-note MCP governance
- Bounded search with context-reduction estimates
- Cached GRIND output retrieval for external agents
- Codex and ChatGPT connection instructions

### Further evaluation and enhancement opportunities

- A multi-query token-reduction and retrieval-quality benchmark
- Consistent inactive-note filtering in Spotter retrieval
- Graph-aware traversal as part of retrieval ranking
- Automated long-term memory evaluation such as recall-at-K testing

These gaps are opportunities for focused implementation rather than reasons to weaken the current memory story.

---

## Competitive build checklist

The objective is not to add the largest possible feature count. The objective is to prove one differentiated system:

```text
Human workshop
        v
Spotter + physical HMI capture
        v
Governed SKATE memory
        v
MCP retrieval for Codex and ChatGPT Work
        v
The GRIND design-thinking engine
        v
Traceable ideas, experiments, and client-ready outputs
```

Every checklist item below should produce visible evidence in the application, repository, README, or demo video.

### Priority 0: eligibility and credibility

- [x] **Integrate GPT-5.6 as a real application model.** SKATE calls GPT-5.6 through the OpenAI Responses API. Settings exposes only the GPT-5.6 family; Spotter defaults to Terra with low reasoning for responsiveness, while The GRIND is pinned in code to Sol with high reasoning for quality-first synthesis. OpenRouter and local LLM routing are excluded from the hackathon build.
  - Acceptance evidence: request-payload and routing tests pass, Settings visibly identifies the fixed GRIND route, and a live end-to-end GRIND verification on July 16, 2026 returned four pain points, four How-Might-We prompts, and four solution starters with `provider=openai`, `model=gpt-5.6`, and `reasoning_effort=high`.
- [x] **Document the GPT-5.6 architecture decision.** SKATE uses explicit reasoning levels to match the workload instead of displaying a model name without meaningful behavior: low for interactive workshop coaching, high for evidence-heavy design-thinking synthesis, and a configurable general default.
  - Acceptance evidence: README section, code comments at the integration boundary, and a concrete demo example.
- [ ] **Preserve verifiable Codex build evidence.** Keep the primary `/feedback` session ID, meaningful commits, and a short list of decisions Codex helped implement or debug.
  - Acceptance evidence: README build story plus the required Devpost session ID.
- [ ] **Make the application effortless to test.** Produce a clean Windows installer or judge-ready package that launches SKATE without requiring judges to manually assemble Python dependencies.
  - Acceptance evidence: fresh-machine installation test, installation instructions, and a tested uninstall path.
- [ ] **Run a clean-vault privacy test.** Confirm the distributed package contains only fictional Harborlight demo content and no API keys, personal transcripts, client names, local settings, caches, or private paths.
  - Acceptance evidence: release checklist and repository scan.

### Priority 1: demonstrate the MCP memory connection

- [x] **Implement a local SKATE MCP server.** The server exposes governed memory rather than unrestricted filesystem access.
- [x] **Add `list_active_sessions`.** Returns only sessions available for agent retrieval.
- [x] **Add `search_memory`.** Accepts a query, optional session, and result limit; returns ranked memory objects with source identifiers and context estimates.
- [x] **Add `get_memory_object`.** Returns one complete active memory object, including provenance and relationships.
- [x] **Add `get_session_context`.** Returns a bounded context package using SKATE's hybrid retrieval policy.
- [x] **Add `trace_evidence`.** Follows typed relationships so an agent can explain what supports, contradicts, causes, or leads to a conclusion.
- [x] **Add `get_grind_outputs`.** Lets Codex or ChatGPT Work retrieve the latest saved GRIND output or a clearly labeled local preview.
- [x] **Add ChatGPT-compatible `search` and `fetch`.** Supports knowledge and research retrieval surfaces without duplicating the memory engine.
- [x] **Create MCP installation instructions.** Provides configuration examples for Codex and ChatGPT Work without committing user-specific paths or secrets.
- [x] **Connect Secure MCP Tunnel.** Complete the account-side connection for ChatGPT Work on the web without exposing the private server publicly.
- [x] **Add an MCP demo script.** Ask Codex a realistic question, show it calling SKATE rather than receiving a pasted vault, and open the returned source note.
  - Acceptance evidence: a working external agent call shown in the demo video and reproducible from the README.

### Priority 1: prove token and retrieval efficiency

- [ ] **Create a small retrieval evaluation set.** Write at least 20 realistic workshop questions and identify the expected evidence notes for each.
- [ ] **Measure recall at five.** Report how often the expected evidence appears in SKATE's top-five results.
- [ ] **Compare lexical-only and hybrid retrieval.** Demonstrate where semantic retrieval improves recall without hiding cases where exact keywords perform better.
- [ ] **Measure context reduction.** Compare the characters and estimated tokens in a full-session prompt against SKATE's bounded Top-K context.
- [ ] **Measure response grounding.** Review a small sample of agent responses and record whether each material claim is supported by a retrieved memory object.
- [ ] **Display retrieval provenance.** MCP results and Spotter responses should show which notes were retrieved and why they were relevant.
- [ ] **Exclude inactive memory consistently.** Apply active/inactive governance to Spotter retrieval as well as The GRIND and MCP.
  - Acceptance evidence: a repeatable benchmark such as, “SKATE reduced a 40,000-character session to a 3,200-character evidence package while retaining the expected evidence in four of the top five results.” Use measured numbers only.

### Priority 1: establish The GRIND as an IDEO-style idea-generation engine

- [ ] **Rename and describe The GRIND consistently.** Present it as a design-thinking synthesis and idea-generation engine, not merely a knowledge graph.
- [ ] **Make the input contract visible.** Show the selected active session, included note count, excluded inactive count, and signal counts before synthesis begins.
- [ ] **Preserve the evidence chain.** Every pain point, How-Might-We prompt, insight, and solution starter must link back to one or more source notes.
- [ ] **Add an ideation stage beyond summarization.** Generate multiple solution directions or experiment concepts from the evidence, while labeling generated ideas separately from observed facts.
- [ ] **Add desirability, feasibility, and viability framing.** Let The GRIND organize solution candidates through a recognizable design-thinking lens.
- [ ] **Add an experiment canvas.** Convert a selected solution starter into a hypothesis, intended user, smallest test, success measure, owner, and next action.
- [ ] **Make outputs reusable.** Preserve Excel export and consider a markdown workshop readout containing findings, evidence, ideas, experiments, and decisions.
- [ ] **Demonstrate evolution across two sessions.** Show how patterns from two separate workshops remain distinct but can inform a broader organizational insight.
- [ ] **Avoid presenting generated ideas as discovered truth.** Clearly label evidence, interpretation, and generation.
  - Acceptance evidence: the demo visibly travels from a raw meeting note to a source-grounded pain point, a How-Might-We prompt, several ideas, and one testable experiment.

### Priority 1: make Spotter a unique workshop agent with a physical HMI

- [ ] **Complete the end-to-end Stream Deck workflow.** A physical key should select a facilitation stance, activate listening, capture the response, and return to the expected state without keyboard interaction.
- [ ] **Verify every mapped stance.** Test Observe, Find Waste, Five Whys, How Might We, Frame, Test, and navigation controls.
- [ ] **Show active stance feedback in SKATE.** The facilitator should see which mode the Stream Deck selected.
- [ ] **Demonstrate the microphone puck in the room.** Show the custom skateboard-wheel housing on the table and explain that it contains the conference microphone array rather than claiming custom microphone electronics.
- [ ] **Demonstrate room-safe interaction.** The facilitator should be able to maintain eye contact while using the Stream Deck HMI.
- [ ] **Clarify transcription choices.** Local Whisper is private and near-live without speaker labels; ElevenLabs is the cloud realtime option and may provide speaker labels when returned by the service.
- [ ] **Add graceful failure states.** Missing microphones, API keys, network connectivity, or local models should produce clear recovery guidance.
- [ ] **Record a continuous physical demo.** Show one unbroken sequence from Stream Deck key press to Spotter response or captured signal.
  - Acceptance evidence: judges see that the physical interface changes workshop behavior rather than serving as decorative hardware.

### Priority 2: strengthen the best-of-breed memory claim

- [ ] **Add a memory architecture panel or diagnostic page.** Show the active embedding backend, model, retrieval mode, cache status, Top-K limit, and session scope.
- [ ] **Explain the open-source stack in the README.** Distinguish SKATE-owned memory code from Ollama, Nomic Embed, FastEmbed, BGE, and `python-frontmatter`.
- [ ] **Add schema documentation and examples.** Include one fully annotated memory object and one relationship chain.
- [ ] **Add memory lifecycle guidance.** Document capture, review, activation, consolidation, retrieval, correction, and retirement.
- [ ] **Add contradiction and duplicate detection.** Flag potential conflicts or repeated memories for human review rather than merging silently.
- [ ] **Add graph-aware retrieval after baseline evaluation.** Combine hybrid scoring with relationship traversal when it measurably improves results.
- [ ] **Keep markdown as the source of truth.** Treat embeddings and indexes as disposable, rebuildable accelerators.

### Priority 2: prove impact with real users

- [ ] **Test with at least three target users.** Include a consultant, facilitator, project manager, nonprofit leader, or workshop participant.
- [ ] **Give each user the same short workflow.** Capture a note, retrieve evidence, run The GRIND, and inspect an output.
- [ ] **Record usability results.** Track completion, confusion points, time required, and whether the outputs were considered useful.
- [ ] **Capture permissioned quotes.** Add one or two concise reactions to the README or demo.
- [ ] **State a measurable impact hypothesis.** Examples include reduced synthesis time, fewer lost decisions, improved evidence traceability, or less repeated context sent to agents.
- [ ] **Avoid claiming proven organizational impact from fictional data.** Harborlight demonstrates the product; user testing supplies credibility.

### Priority 2: make “not another Obsidian” obvious in the demo

- [ ] **Do not lead with the note editor.** Lead with the workshop problem and the full transformation from conversation to action.
- [ ] **Show one realistic mixed meeting note.** Plain human notes should coexist with typed workshop signals rather than resembling a synthetic database record.
- [ ] **Show The GRIND producing an actionable output.** The graph is supporting evidence; the insight, idea, and experiment are the payoff.
- [ ] **Show the physical HMI.** Obsidian comparisons become much less relevant when the agent is visibly operating in a live workshop.
- [ ] **Show an MCP retrieval call.** Prove SKATE is a governed memory service for external agents, not only a desktop notebook.
- [ ] **Use a precise positioning line.** Recommended: “SKATE is a local-first workshop memory and design-thinking engine with a physical agent interface.”

### Priority 3: submission quality and judge experience

- [ ] **Keep the public demo below three minutes.** Show working software and retain the specific GPT-5.6 and Codex explanation.
- [ ] **Make the first 20 seconds decisive.** State the problem, audience, and differentiated loop.
- [ ] **Use a clean release build.** Hide personal vault paths, notifications, keys, private transcripts, and unrelated applications.
- [ ] **Test every planned click before recording.** Preload local models and final synthesis results.
- [ ] **Include a public repository license.** Confirm third-party notices and installation documentation are present.
- [ ] **Provide sample data and a judge test path.** Judges should be able to experience the main loop without creating a workshop from scratch.
- [ ] **Run a release-candidate freeze.** Stop adding secondary features once the core loop is reliable.
- [x] **Perform a fresh-machine test.** Install, launch, explore the demo, run The GRIND, test MCP, and uninstall.

---

## Recommended implementation sequence

Complete the checklist in this order:

1. Genuine GPT-5.6 integration and Codex evidence
2. Consistent active/inactive memory governance
3. Minimal read-focused MCP server
4. MCP connection to Codex with a reproducible demo
5. Retrieval and token-reduction benchmark
6. The GRIND evidence-to-idea-to-experiment workflow
7. End-to-end Stream Deck and microphone-puck demonstration
8. Real-user validation
9. Installer and fresh-machine testing
10. Three-minute video, README, repository, and Devpost submission QA

This sequence prioritizes eligibility, technical differentiation, and proof before secondary polish.

---

## Competitiveness after completing the checklist

No feature checklist can make winning likely in a hackathon with more than 20,000 registered participants and only two Work and Productivity prizes. Registrations are not the same as eligible completed submissions, so the true denominator will be smaller but is not currently known.

If the Priority 0 and Priority 1 items are genuinely working and demonstrated—not merely described—SKATE would have a credible argument across all four judging criteria:

| Criterion | Estimated competitive position after completion | Why |
|---|---:|---|
| Technological Implementation | 8.5-9.0 / 10 | Non-trivial native app, meaningful GPT-5.6 use, Codex build evidence, MCP tools, hybrid memory, physical controls, and measurable retrieval behavior |
| Design | 8.0-8.8 / 10 | Coherent product loop spanning capture, governed memory, agent interaction, synthesis, traceability, and export |
| Potential Impact | 7.5-8.5 / 10 | Specific professional audience plus measured token/context reduction and real-user evidence |
| Quality of the Idea | 8.5-9.0 / 10 | Unusual combination of organizational memory, MCP, design-thinking synthesis, voice, and physical HMI |

### Estimated probability ranges

These are subjective planning estimates, not statistical guarantees:

- **Serious judging consideration or shortlist:** approximately **8-15%**
- **Any Work and Productivity prize:** approximately **2-4%**
- **Specifically second place in Work and Productivity:** approximately **1-2.5%**
- **Specifically first place in Work and Productivity:** approximately **0.7-2%**

The second-place estimate assumes:

- GPT-5.6 is genuinely integrated and visible in the repository.
- The MCP connection works live with Codex or ChatGPT Work.
- The GRIND demonstrates idea generation and experiment design rather than only summarization.
- The physical HMI works in an uninterrupted demo.
- At least limited real-user validation exists.
- Installation and judge testing are reliable.
- The three-minute video communicates one memorable transformation without visible failures.

Without working GPT-5.6 and MCP evidence, the architecture may still look ambitious, but the submission would be judged on promises instead of implementation. In that state, the estimated chance of second place remains below 1%.

### What would make the submission memorable

The strongest possible demonstration is one continuous story:

```text
A facilitator presses a Stream Deck stance key.
Spotter hears the room through the skate-wheel microphone puck.
A messy conversation becomes governed SKATE memory.
Codex retrieves only the relevant evidence through MCP.
The GRIND turns that evidence into a How-Might-We prompt and several ideas.
The facilitator selects one idea and creates a testable experiment.
Every conclusion opens back to its original source note.
```

That is not another Obsidian. It is an AI-assisted workshop operating system.

---

## Submission-ready positioning

> SKATE is not another AI notebook or Obsidian clone. It is a local-first memory and design-thinking engine for facilitated work.
>
> Every workshop memory remains a human-readable markdown object with an episode, semantic type, themes, provenance, status, and typed evidence relationships. SKATE combines exact lexical retrieval with optional local semantic embeddings, then supplies agents with only a bounded set of the most relevant evidence instead of repeatedly sending an entire vault into the model.
>
> The GRIND is SKATE's differentiated consolidation engine. It transforms connected, active workshop evidence into traceable pain points, How-Might-We prompts, and solution starters while preserving links to the original notes.
>
> Spotter brings that memory system into the room through voice, a custom skateboard-wheel microphone housing, and a Stream Deck Neo human-machine interface. SKATE's read-only MCP layer exposes governed memory to Codex and ChatGPT-compatible clients without surrendering the vault or flooding the context window. Local Codex and hosted ChatGPT Work connections are working and included in releases.

---

## Technical references

- SKATE memory model: `ui/skate_lib.py`
- Hybrid retrieval: `ui/embeddings.py`
- Spotter context assembly: `ui/app.py::_spotter_session_context`
- The GRIND: `ui/skate_lib.py` and `ui/templates/graph.html`
- MCP server: `mcp_server/server.py` and `mcp_server/service.py`
- MCP connection guide: `docs/MCP-CONNECTION.md`
- Stream Deck controls: `streamdeck-neo-icons/HOTKEYS.md`
- Microphone housing: `hardware-spotter-mic-puck/`
- [Ollama](https://github.com/ollama/ollama)
- [Nomic Embed Text](https://huggingface.co/nomic-ai/nomic-embed-text-v1.5)
- [FastEmbed](https://github.com/qdrant/fastembed)
- [python-frontmatter](https://github.com/eyeseast/python-frontmatter)
- [Mem0](https://github.com/mem0ai/mem0) — comparison only; not a current dependency
