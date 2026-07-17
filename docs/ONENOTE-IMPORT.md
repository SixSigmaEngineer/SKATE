# OneNote → SKATE Import

**Bottom line:** The cleanest path is to **export your OneNote to Word (.docx) from the OneNote desktop app**, copy those files to your SKATE machine, then run **Settings → Import from OneNote** and point it at the folder. SKATE turns each **Notebook into a session** and each **page into a note** — no extra software, no pip installs. If you only have a locked client laptop with browser-only access, use the **Office 365 web → Print to PDF** path instead (lossier, optional PDF support).

_Last updated: 2026-06-09_

---

## The mapping

| OneNote | SKATE |
|---|---|
| Notebook (or top-level export folder) | Session (`sessions/<slug>/README.md`) |
| Section / page | Note (`conversations/<class>/<date>-<slug>.md`) |
| Page title | Note title + first heading |

Imported notes are tagged `onenote-import`, `source: onenote import`, `type: note`, `status: imported`, and are attached to the session named after their notebook.

---

## How to get your OneNote out

You can't read a raw `.one` file directly — it's a proprietary binary. You have to **export** first. Pick the method that matches the machine you're on.

### Method 1 — OneNote desktop → Word (recommended, best fidelity)

Use this when you can open the notebooks in the OneNote desktop app (your own machine, or a client laptop where OneNote desktop is installed).

1. Open OneNote desktop.
2. `File → Export`.
3. Choose **Notebook** or **Section** (export one section/notebook at a time — OneNote can't bulk-export everything at once).
4. Format: **Word Document (`*.docx`)**.
5. Save. Repeat per notebook/section.
6. Move the `.docx` files to your SKATE computer (USB drive, email to yourself, or your personal OneDrive — **not** the client's).
7. Put each notebook's files in its own folder, e.g. `OneNote Export\Client Discovery\Section A.docx`.

Each exported `.docx` holds all the pages of a section, with each page title as a Heading 1. SKATE's importer splits those back into one note per page automatically.

### Method 2 — `onenote-md-exporter` → Markdown (power path, cleanest hierarchy)

If you can install a small tool on a machine that has OneNote desktop + your notebooks, the open-source **OneNote MD Exporter** converts the full `Notebook → Section → Page` tree straight into Markdown files (with attachments). The folder structure it produces maps 1:1 onto SKATE sessions and notes. Point the importer at its output folder. Best option when you have many notebooks.

### Method 3 — Office 365 web → PDF (locked client laptop, browser only)

Use this when the **only** thing you can do on the client machine is sign in to Office on the web. OneNote-for-the-web has **no bulk Word export**, so you fall back to PDF:

1. Go to `office.com` or `onedrive.com` and sign in.
2. Open the notebook in **OneNote for the web**.
3. `Print` → destination **Save as PDF** (do this per section or per page).
4. Transfer the PDFs to your SKATE computer.
5. PDF import needs the optional `pypdf` package on the SKATE machine: `pip install pypdf`. (Word/Markdown/HTML need nothing.)

PDF is the lossiest route — images and complex tables may not survive as clean text. Prefer Word export whenever you have desktop OneNote.

### Method 4 — raw `.one` files from OneDrive (not recommended)

You can download the `.one` files that back a notebook from OneDrive, but they're binary and SKATE can't parse them. The importer will list them as **skipped** with a reminder to export to Word or Markdown instead.

> **Client-data note:** OneNote on a client laptop often contains the client's confidential material. Get explicit permission before exporting anything off their device, and move it over a channel you're allowed to use.

---

## Using the importer (Settings → Import from OneNote)

1. **Export folder (full path)** — paste the path to the folder you copied your export into, e.g. `C:\Users\you\Desktop\OneNote Export`.
2. **Grouping**
   - *Each top-level folder is a Notebook → session* (default): every immediate subfolder becomes its own session. Use this for Method 1/2 exports organized by notebook.
   - *Put everything in one session*: dumps all files into a single session you name. Use this for a loose pile of files.
3. **Session name** — used for loose files sitting directly in the export folder, or for single-session mode.
4. **Split into one note per page** (default on) — for Word/HTML files, splits on each top-level heading so each OneNote page becomes its own note. Turn off to keep one note per file.
5. **Preview** — dry run. Shows exactly which notebooks → sessions and which notes would be created, plus anything skipped. **Nothing is written yet.**
6. **Import** — converts and writes the notes into the vault, creating session READMEs as needed. Reports how many notes and sessions were created.

Supported file types: `.docx`, `.md` / `.markdown`, `.html` / `.htm`, `.txt`, and `.pdf` (PDF only if `pypdf` is installed).

---

## How it works under the hood

- `ui/onenote_import.py` — dependency-light converters (Word/Markdown/HTML/TXT use only the Python standard library; PDF uses optional `pypdf`). `build_plan()` walks the folder, groups files into notebooks, and turns each file/page into a `{title, body}` note. Splitting is by Heading 1 / Title.
- `ui/app.py` — two endpoints:
  - `POST /api/onenote-preview` → dry-run plan (no writes).
  - `POST /api/onenote-import` → writes notes via the existing `_write_entry`, creating sessions with `_ensure_session`.
- The importer never touches your originals — it only reads the export folder and writes new notes into the SKATE vault.

---

## Limitations / future work

- **Images & attachments** aren't pulled in yet (Word/PDF text only). Tracked on the roadmap.
- **PDF fidelity** depends on the export; prefer Word.
- **Page hierarchy / subpages** are flattened to notes under the notebook's session.
- Re-running an import creates new, de-duplicated filenames (it won't overwrite) — so importing the same folder twice will create second copies. Clean up or import once.
