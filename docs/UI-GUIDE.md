# SKATE UI Guide

A tour of the interface: the top bar, every page behind it, and how the core workflows fit together. SKATE runs locally at **http://127.0.0.1:8765**.

## Layout

Every page shares the same shell: a **top bar** (brand, navigation, zoom, search), a **left sidebar** (vault stats, recent sessions, object types, themes), and the main content area.

## The top bar

| Item | Where it goes | What it does |
|---|---|---|
| **SKATE logo / brand** | `/` | Returns to the Library from anywhere. |
| **New Note** | `/new` | Opens the note form to capture a structured note. |
| **Library** | `/` | Browses every entry in the vault. |
| **Grind** | `/grind` | The 3D/2D mind map and synthesis engine. |
| **Spotter** | `/spotter` | Chat with the AI workshop co-pilot (text or voice). |
| **Spotter Live** | `/spotter-live` | Always-on room listening with live transcription. |
| **Sessions** | `/sessions` | Lists workshop sessions; create new ones here. |
| **Stats** | `/stats` | Vault analytics — counts by type, top tags. |
| **About** | `/about` | What SKATE is and how the memory tech works. |
| **Settings** | `/settings` | AI providers, voice, Spotter persona, integrations. |
| **Zoom controls** | — | Zoom out / slider / reset / zoom in (75%–140%). The setting persists between visits. |
| **Search box** | `/search` | Full-text search across the vault; also reachable from theme links in the sidebar. |

## The sidebar

Shows total entry count and the vault path, quick tabs for Library and Sessions, the ten most recent sessions (with note counts and a **+** to create one), and a memory tree: click an **Object Type** to open the Grind filtered to that type, or a **Theme** to search for it.

## Making notes

Click **New Note** (or the **New note** button on a session page, which pre-fills the session). The form captures a structured markdown object: Title, Date, Object Type (observation, pain, insight, recommendation, decision, quote, and more), Workshop/Session (pick one or type a new session name), Themes, Tags, typed Relationships to other notes (supports, contradicts, causes, leads_to, references, similar_to), Status, Source, and a free markdown body. Every note is saved as a plain `.md` file in the vault — open any entry to view it, and use **Edit** to change it.

**Tabbable notes (required):** notes must open in tabs like Obsidian — multiple notes open side by side in the main content area, switchable without losing your place, so a facilitator can compare a pain point against the insight it supports while writing a third note.

## Spotter

Spotter is the AI facilitation co-pilot. Type a question or paste a workshop capture, or press **Start talking** to dictate; **Send** submits. Spotter answers with workshop-grade coaching (Lean, Kaizen, design thinking, process analysis) grounded in the most relevant notes from the selected session, and can speak responses aloud. Scope it with the session picker, and use **Export MD** to save the conversation as markdown.

## Spotter Live

The always-on version for a live room. Press the toggle to start listening: it writes a timestamped markdown transcript as people talk (browser speech for live text, ElevenLabs Scribe for the clean final, or fully local Whisper). You can also ask Spotter questions mid-session by voice or text without stopping the transcript.

**Voice diarization (required):** a workshop transcript is only useful if it records *who* said what. Spotter Live needs speaker diarization — separating and labeling each voice in the room — via the **ElevenLabs Scribe API**, which returns per-speaker segments. Transcript lines should carry a speaker label (e.g., `Speaker 2 [00:14:32]: ...`), ideally mappable to participant names for the session.

## The Grind (mind map + synthesis)

Select a session and press **Start the Grind**. Every note becomes a node in a force-directed graph (3D or 2D toggle), colored by object type, connected by relationship rails and shared-theme rails. **Fit** frames the whole map, **Bail** stops the simulation, checkboxes filter rail types, and the legend isolates object types. Hover or click a node to inspect it. **Generated workshop synthesis** runs an IDEO/Lean pass over the visible session and produces Pain Points, How-Might-We prompts, and Solution Starters — each with a **capture** button that files it back into the vault as a new typed note, and the results export to Excel.

## Sessions

Lists every workshop session with its notes. A session page shows its entries and offers **New note** (pre-scoped to the session) and a jump into **Spotter** scoped to that session's memory.

## Library, Search, and Stats

The **Library** lists all entries newest-first. **Search** runs full-text queries with theme filtering. **Stats** summarizes the vault: entry counts and top tags.

## Settings

The app uses exactly **two external APIs**: **OpenAI** (all LLM work — Spotter, Grind synthesis, classification — plus optional embeddings, STT, and TTS) and **ElevenLabs** (Scribe speech-to-text with diarization, and text-to-speech). Nothing else calls out.

Four sections: **General AI / API** — configure the GPT-5.6 family, reasoning levels, max output, and the OpenAI API key. GRIND is visibly fixed to GPT-5.6 Sol/high reasoning; Spotter defaults to GPT-5.6 Terra/low reasoning. **Spotter** — agent name, subtitle, persona, methodology stack, and response style. **Voice** — microphone selection, local Whisper or ElevenLabs speech-to-text, voices, and speak-aloud controls. **Stream Deck Trigger** — port and auto-send for hardware capture buttons. Settings also hosts the **OneNote import**: point it at exported OneNote files and each notebook becomes a session, each page a note (with a dry-run preview).
