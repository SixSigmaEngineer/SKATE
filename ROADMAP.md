# SKATE — Roadmap & Backlog

Future work for SKATE and the Spotter workshop agent. Ordered roughly by priority.
Lead with the bottom line; each item notes *why*, *what*, and rough *effort*.

_Last updated: 2026-07-03_

---

## Recently shipped (context)

- **Spotter chat UI** — real chat window, Start/Stop talking, stance chip, voice-status indicator.
- **ElevenLabs voice** — Scribe STT + ElevenLabs TTS wired with API key field, voice/model dropdowns, "Load my voices," and a Test voice button. Browser-voice + local-Whisper fallbacks.
- **Live dictation** — browser speech recognition for live transcript, ElevenLabs Scribe for the clean final, auto-submit on pause.
- **Lexical RAG for session memory** — Spotter now retrieves only the most relevant session notes per question instead of dumping all of them (fixes the prompt-size 400 and improves grounding).
- **Stream Deck Neo icon set** — 19 hand-designed, color-coded SVG/PNG icons + hotkey docs.
- **Hybrid semantic retrieval (2026-07-03)** — `ui/embeddings.py`: local-first embedding backends auto-detected (Ollama `nomic-embed-text` → `fastembed` → OpenAI fallback), content-hash disk cache, pure-stdlib cosine, 60/40 semantic+lexical blend. Wired into Spotter session context. Degrades gracefully to lexical-only.
- **LCC removal (2026-07-03)** — legacy classification layer fully removed; organization is relationships + themes + types + sessions.
- **OneNote import (Settings)** — point SKATE at a folder of exported OneNote files; Notebook becomes a session, each page becomes a note. Dependency-light converters for Word (.docx), Markdown, HTML, and TXT (PDF optional via `pypdf`). Includes a Preview/dry-run before writing. See `docs/ONENOTE-IMPORT.md`.

---

## Next up (high priority)

### 1. Retrieval polish (remainder of the shipped items)
- Body-chunk embeddings for long notes (currently title+themes+tags+summary).
- Temporal weighting in retrieval: down-rank notes with status `stale`/`deprecated`, decay old sessions.
- Retrieval eval set: ~20 question/expected-note pairs over a real vault, scored recall@5 (LongMemEval-style), run in CI.

### 2. Two-phase Spotter response — speak first, detail after
**Why:** Today Spotter generates the whole structured note before anything appears, so the spoken one-liner waits behind all the bullets. Splitting it makes the live workshop feel near-instant.

**What:** First a tiny fast call returns just the `spoken_response` → show + speak immediately. Then a second call fills the structured note (EVIDENCE/INSIGHTS/ACTIONS) underneath. Keeps the exact structured note format.

**Effort:** Small–medium (two LLM calls + a JS update to render in two stages).

---

## Later (nice to have)

### 3. ElevenLabs Scribe Realtime STT (toggle)
True low-latency streaming transcription via ElevenLabs WebSocket, as a Settings toggle ("Live STT engine: Browser / ElevenLabs realtime"). All-ElevenLabs accuracy live. Bigger build (raw PCM streaming via AudioWorklet → WS). The browser-live + Scribe-final hybrid covers most needs until then.

### 4. Cowork session capture (the "wedge")
Auto-extract decisions / action items / frameworks / open questions / reference data from a Cowork transcript and write them into the vault as structured memory objects — before context compaction destroys them. This was flagged in the SKATE foundation primer as the killer wedge feature.

### 5. Graph-aware retrieval
The graph view exists (The Grind). Remaining: graph-aware *queries* — "show everything connected to Project X decided after April" — combining relationship traversal with date/status filters, to complement hybrid search for organizational memory.

### 6. Auto-classification on save
Run the existing classify/compress pipeline automatically when a note is created (themes, type, relationships) so capture is one step.

### 7. Voice/model speed presets
A "Fast / Balanced / Quality" preset in Settings that sets model + max_tokens + TTS model together, so switching to a low-latency live config is one click instead of several fields.

---

## Tech debt / hardening

- **Stale path resolver** — `skate_lib._candidate_roots()` still hunts for "Skate V2" and OneDrive Desktop paths; can bind to the wrong/old vault. Make `SKATE_ROOT` explicit and deterministic.
- **Blocking HTTP in async handlers** — LLM/TTS calls use synchronous `urllib` inside FastAPI handlers; fine single-user, but will block under any concurrency. Move to async or a thread pool if usage grows.
- **Local Whisper / torch broken** — `torch_python.dll` (WinError 126), likely a missing VC++ runtime or corrupted torch. Not blocking (ElevenLabs Scribe covers STT), but fix `Install Local Whisper.ps1` if offline transcription is ever wanted.
- **Hand-rolled XLSX export** (GRIND) — works, but consider a real writer if it grows.
- **Stop/Start scripts** — fixed the port bug (8765 vs 8766); keep an eye on multiple-instance handling.

---

## Guiding principles (from the SKATE foundation primer)

- **Markdown-first vault** + frontmatter metadata = portable, git-able, human-readable.
- **Buy + wrap** the hard memory parts; SKATE's differentiation is the workflow, governance, and agent UX — not the embeddings engine itself.
- **Local-first**, with a cloud/sync path later.
