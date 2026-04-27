# Authoring Markdown for @moravio/md-pdf

This guide explains how to write `.md` files so the `md-pdf` pipeline turns them into PDFs in **document** or **slides** layout. To install the tool in another codebase: see **[consuming-in-other-projects.md](consuming-in-other-projects.md)**.

## Tool versions (what to expect)

| Component               | Version / source                              | Notes                                                                                      |
| ----------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **Mermaid** (prerender) | **11.x** from the direct `mermaid` dependency | Defined in `prerender-mermaid.js`. Prefer syntax you verify against the installed version. |
| **Markdown → HTML**     | **marked 9.x**                                | GFM tables, fenced code, and most classic syntax work out of the box.                      |
| **Code highlighting**   | **highlight.js 11.x**                         | Unknown languages render as plain text.                                                    |
| **PDF from HTML**       | **Puppeteer 24.x**                            | Requires local Chromium / Chrome.                                                          |

Official diagram reference: [Mermaid documentation](https://mermaid.js.org/).

## Required files

- **`document.md`** — body content.
- **`document.meta.json`** — title-page metadata (same basename as `.md`). **Optional** — without it, md-pdf generates a simple PDF (no title page, TOC, or pagination). See **Simple mode** below.

## Metadata (`.meta.json`)

With an explicit title-page date:

```json
{
  "title": "Title",
  "subtitle": "Subtitle",
  "date": "27 March 2026",
  "author": "Name",
  "email": "you@example.com",
  "phoneNumber": "+420 …",
  "client": "Client",
  "customFields": {
    "Field label": "Value"
  },
  "layout": "document",
  "language": "en"
}
```

Minimal **document** metadata (no email, phone, or extra lines under the client):

```json
{
  "title": "Title",
  "subtitle": "Subtitle",
  "author": "Name",
  "client": "Client",
  "layout": "document",
  "language": "en"
}
```

**`date` is optional.** You can omit the `date` key entirely or set `"date": ""`. In both cases the pipeline uses **today’s date** on the title page, formatted according to **`language`** (`en` → long English date, `cs` → e.g. `27. března 2026`).

- **`email`**: optional. When set, it appears on the author line as a `mailto:` link. When omitted or empty, no email segment is shown (no stray `/`).
- **`phoneNumber`**: optional. When set, it appears after the author name and optional email, separated by **`/`**, as a `tel:` link. Omitted segments are skipped so you never get empty slashes.
- **`customFields`**: optional object whose **keys** are label text and **values** are plain text. Entries are rendered **below the client** on the title page, one per line, using the same label styling as **Client** (document) or stacked blocks (slides). Keys should be strings; values are stringified. Empty keys or values are skipped. If `customFields` is not a plain object (e.g. an array), it is ignored and a warning is printed. In **`document`** layout, date/author/client/custom rows share a **two-column grid**: the label column is at least the **`width`** set in **`titlePage.document.labelStyle`** in **`branding.json`** (often 80px) and **expands** if a label (including a long **`customFields`** key) needs more room, so values stay aligned and do not overlap the label.

- **`layout`**: omit or `"document"` for a standard report; `"slides"` for a slide deck (different title page, A4 landscape, different PDF merge path).
- **`language`**: `"en"` (default) or `"cs"`. Controls the **default date** format (when **`date`** is omitted or empty), **title-page labels** (Date, Author, Client, Presentation, …), and the **table of contents** heading (`Contents` vs `Obsah`).
- **`pagination`**: optional boolean, default **`true`**. Set **`false`** to turn off **automatic** slide breaks in **`slides`** layout (content flows like a continuous document; manual `<div class="page-break"></div>` still works). In **`slides`** layout with **`false`**, the merged PDF has **no footer** (no **“n / total”** page strip or eagle logo). With **`false`**, the content PDF uses a **slightly smaller bottom margin** so the body can extend a bit lower. **`document`** layout keeps the usual footer; only the bottom-margin tweak applies when **`pagination`** is **`false`**.
- **`titlePage`**: optional boolean, default **`true`**. Set **`false`** to **skip the title page entirely**. The PDF starts directly with the content. Branding CSS, TOC, and page numbering still work — page numbers start from 1 on the first content page. Useful for short documents, appendices, or when the title is included directly in the Markdown.
- **`toc`**: optional boolean, default **`true`**. Set **`false`** in **`document`** layout to **skip the generated table of contents** — the PDF is **title page + body** only (no TOC pages or measurement pass). Ignored for **`slides`**. Page footers (**`n / total`** + eagle) behave like the normal document merge.
- **`branding`**: optional string id, default **`moravio-default`**. Must match a folder `brandings/<id>/` **inside the installed package** with **`branding.json`** plus assets. Ignored when **`brandingDir`** is set. See **Branding** below.
- **`brandingDir`**: optional string path to a **folder** that contains **`branding.json`** (and the SVG assets listed there). Resolved relative to the **directory of your `.meta.json`** file (not the shell’s current working directory). Absolute paths are allowed. When present, **`branding`** is ignored — use this from **another repository** so your brand is **not** stored under **`node_modules`**. See **External branding (consumer projects)** below.
- **`pageFormat`**: optional string, one of **`A3`**, **`A4`** (default), **`A5`**, **`Letter`**, **`Legal`**, **`Tabloid`**. Overrides the branding's default page size on **both** the title page and the content body so the whole PDF stays one paper size. Unknown values fail fast with a clear error. Equivalent CLI flag: **`--page-format <fmt>`** — the CLI flag wins over the meta-level field.
- **`watermark`**: optional object that stamps a text watermark on every page (title, TOC, and body). Overrides a `watermark` default set in `branding.json`. Set to **`false`** to disable a brand default for this document. See **Watermark** below.

## Branding

### Built-in brands (package)

Brands shipped with the tool live under **`brandings/<id>/`** at the **package root** (the same directory that contains `convert-to-pdf.js`). The **`branding`** value in `.meta.json` is the folder name **`<id>`**; the loader opens `brandings/<id>/branding.json`. Keep **`"id"`** inside `branding.json` equal to that folder name so paths and errors stay clear.

### User-installed brands (`~/.md-pdf/brands/<id>/`)

For brands you reuse across many projects, install them under **`~/.md-pdf/brands/<id>/`** (cross-platform via `os.homedir()`). Reference them from any **`.meta.json`** by id, exactly like a built-in:

```json
{ "branding": "my-brand" }
```

Resolution order for **`branding: "<id>"`**:

1. **`~/.md-pdf/brands/<id>/`** (user-installed) — takes precedence; lets you shadow a built-in like **`moravio-default`** without forking.
2. Bundled **`<package>/brandings/<id>/`** — fallback.

Override the user dir with the **`MD_PDF_BRANDS_DIR`** env var (useful for tests, CI, or project-scoped overrides). Each user brand folder must contain a **`branding.json`** plus the assets it references; scaffold one with **`npx md-pdf-branding-init ~/.md-pdf/brands/my-brand`**.

### External branding (consumer projects)

Use this when you depend on **`@moravio/md-pdf`** from Git in **your own repo** and want a brand that survives **`npm install`** without forking.

1. **Scaffold** a copy of **`moravio-default`** next to your docs (from your project root, with the package installed):

   ```bash
   npx md-pdf-branding-init ./docs/brand/my-company
   ```

   Or run **`md-pdf-branding-init`** via an npm script so `node_modules/.bin` is on `PATH`.

2. **Edit** **`branding.json`**, **`logo.svg`**, **`decoration.svg`**, **`footer-mark.svg`**. The init template now copies **`fonts/InterVariable.ttf`** and **`fonts/inter-variable.css`** into the new brand so the default scaffold renders offline. If you switch to another family, update **`fonts.fontCssDocument`** / **`fonts.fontCssSlides`** and adjust **`toc.fontRegular`** / **`fontBold`** accordingly. The older **`googleImport…`** keys still work as a deprecated fallback, but **`md-pdf-branding-check`** warns when they are the active source.

3. **Validate** before building PDFs:

   ```bash
   npx md-pdf-branding-check ./docs/brand/my-company
   ```

   This checks JSON + assets and runs the same **CSS vars / title-page / resolved runtime** steps as a real conversion (without Chromium).

4. In **`.meta.json`**, point at the folder **relative to the meta file**:

   ```json
   "brandingDir": "../brand/my-company"
   ```

   If **`sample.md`** and **`sample.meta.json`** sit in **`docs/`** and the brand is **`docs/brand/my-company`**, use **`"brandingDir": "brand/my-company"`**.

**CLI binaries** (after install): **`md-pdf-branding-init`**, **`md-pdf-branding-check`**. Example in this repo: **`examples/consumer-brand/`**.

### Quick start (new brand)

1. Copy **`brandings/moravio-default/`** to **`brandings/<your-id>/`** (or copy **`duckbyte-advisory`** if you want a second real-world example).
2. In **`branding.json`**, set **`"id"`** to **`"<your-id>"`** (same as the folder).
3. Replace **`logo.svg`**, **`decoration.svg`**, and **`footer-mark.svg`** (or keep filenames and point **`assets`** at your names).
4. Adjust **`fonts`** (stacks + local **`fontCssDocument`** / **`fontCssSlides`**; avoid the deprecated **`googleImport…`** fallback) and **`contentCss`** colors to match the brand.
5. Tune **`titlePage.document`** and **`titlePage.slides`** inline styles (especially **`decorationImgStyle`** and **`logoImgStyle`**) so the title page matches your artwork.
6. In **`.meta.json`**, set **`"branding": "<your-id>"`** and run a test PDF.

Validation is strict: **`version`** must be **`1`**, **`assets.logo`**, **`assets.decoration`**, and **`assets.footerMark`** must each name a file that exists next to **`branding.json`**.

### `branding.json` structure (version 1)

| Section                 | Purpose                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`version`**, **`id`** | Must be **`1`** and a non-empty string; **`id`** should match the parent folder name.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **`assets`**            | **`logo`**, **`decoration`**, **`footerMark`** — paths relative to the brand folder (usually SVG).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| **`fonts`**             | **`sansStack`**, **`monoStack`**, optional **`fontCssDocument`** / **`fontCssSlides`**, optional deprecated fallback **`googleImportDocument`** / **`googleImportSlides`**. Local `fontCss…` paths are resolved relative to `branding.json` and imported into generated content CSS; prefer them for offline/stable builds. **`md-pdf-branding-check`** warns when a network font import is still active.                                                                                                                                                                                                                                                                                                                                                                                            |
| **`contentMargins`**    | **`document`** and **`slides`**, each with **`paginationOn`** and **`paginationOff`** (CSS **`margin`** shorthand strings for `@page`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| **`contentCss`**        | **`document`** and **`slides`** — camelCase token names become CSS variables **`--brand-<kebab-case>`** in **`brand-vars.css`** (e.g. **`linkColor`** → **`--brand-link-color`**). Used by **`moravio-style.css`** / **`moravio-slides.css`**.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **`footer`**            | Page footer after merge: **`marginSideMm`**, **`bottomPt`**, **`fontSize`**, **`textColor`**, **`markHeightPt`**, **`markRenderScale`** (optional, default **`3`** — scales **`footerMark`** rasterization).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **`toc`**               | Generated TOC (HTML + Chromium): margins, typography, **`textColor`**, **`ruleColor`**, optional **`background`** (CSS color for **`.moravio-toc-root`** — use e.g. **`"#ffffff"`** when **`contentCss`** **`bodyBg`** is tinted and you want a clean TOC panel), entry/title sizes and indents. TOC body text uses the **document sans stack** from **`fonts`** / **`contentCss`**. **`fontRegular`** / **`fontBold`** file paths are **unused** for the Chromium TOC (kept for config compatibility).                                                                                                                                                                                                                                                                                              |
| **`titlePage`**         | **`document`** / **`slides`**: **`pdfOptions`**, **`linkColor`**, layout **`…Style`** strings. Use **`min-height`** (not fixed **`height`**) and **`overflow: visible`** on **`containerStyle`** / **`outerStyle`**, with **`display: flex; flex-direction: column`**, so long titles are not clipped. When **`pdfOptions.margin`** has **zero right** and **non‑zero left**, the engine adds an inner column (**`padding-right`** = left margin, **`padding-bottom`** reserves the footer/meta band, **`flex: 1 1 auto; min-height: 0`**). Optional **`contentColumnBottomPad`** (CSS length, e.g. **`"62mm"`**) adjusts that reserve. Optional **`contentColumnStyle`** replaces the whole inner wrapper (then you must supply matching flex/padding yourself if you keep the same footer layout). |

**Assets:** **`decoration`** is only used on the **title page** (large backdrop, **`decorationImgStyle`**). **`footerMark`** is the small mark beside **“n / total”** in merged document PDFs.

**Title-page fonts:** the title page pulls in the generated **`brand-vars.css`**, so **`@font-face`** rules from **`fontCssDocument`** / **`fontCssSlides`** are available there too. You can reference the branded family directly from **`titlePage.*Style`** inline styles (e.g. **`font-family: 'Montserrat', sans-serif`**) and it will render identically to body text and the TOC.

### Using a custom brand inside the package

The installed package includes **`brandings/`** (see **`package.json`** → **`files`**). Only folders shipped there are available via **`"branding": "<id>"`**. To ship a **private** id inside the tarball, use a **fork** or **Git dependency** that adds **`brandings/<id>/`**; ad-hoc edits under **`node_modules`** are lost on reinstall. Prefer **`brandingDir`** in consumer repos instead of forking when you only need custom visuals.

### Examples in this repo

- **`examples/document/sample-document-duckbyte.meta.json`** — **`"branding": "duckbyte-advisory"`** (built-in id). Compare **`brandings/duckbyte-advisory/`** to **`brandings/moravio-default/`**.
- **`examples/consumer-brand/`** — **`"brandingDir": "my-corp"`** with the brand folder beside the Markdown files.

## Watermark

Use the **`watermark`** block (in `.meta.json` or under the top-level `watermark` key in `branding.json`) to stamp a repeated or single text marker behind the content — useful for labeling work-in-progress documents as **DRAFT**, **CONFIDENTIAL**, and similar.

```json
{
  "watermark": {
    "text": "DRAFT",
    "size": "72pt",
    "color": "rgba(198, 40, 40, 0.18)",
    "weight": 800,
    "angle": -30,
    "repeat": { "spacingX": "9cm", "spacingY": "7cm" }
  }
}
```

- **`text`** _(required)_ — the label drawn behind the content.
- **`font`** — any CSS `font-family` value. Defaults to the brand's resolved sans stack (whatever `branding.json` → `fonts.sansStack` evaluates to), falling back to `sans-serif` if that is unavailable. The watermark SVG is served as a `data:` URI, which is an isolated document — CSS custom properties (`var(--brand-font-sans, …)`) from the host page do **not** cascade in, so the resolved stack is inlined at build time. If you override this field, pass a concrete font-family string, not a `var()` reference.
- **`size`** — CSS size, default **`56pt`**.
- **`color`** — CSS color including alpha, default **`rgba(0, 0, 0, 0.055)`** (deliberately faint so the mark does not overwhelm the content).
- **`weight`** — numeric `1`–`1000` or a CSS keyword (`bold`, `normal`, …), default **`600`**.
- **`angle`** — rotation in degrees. Default **`-30`** when `repeat` is set, **`0`** otherwise.
- **`position`** — either a preset (**`center`**, **`top`**, **`bottom`**, **`left`**, **`right`**, **`top-left`**, **`top-right`**, **`bottom-left`**, **`bottom-right`**) or an explicit **`{ "x": "2cm", "y": "50%" }`** object. Accepts any CSS length or percentage.
- **`repeat`** — when present, tiles the watermark with **`spacingX`** × **`spacingY`** step (both required, CSS lengths). Omit for a **single** watermark per page, positioned via `position`.

Validation is **strict**: unknown keys in **`watermark`**, **`repeat`**, or **`position`** throw an error. Priority is **`.meta.json`** > **`branding.json`** > disabled; setting **`"watermark": false`** (or **`null`**) in `.meta.json` turns off a brand default.

The watermark is drawn as an SVG data-URI background via `body::before` with `position: fixed`, so Chromium replicates it on every printed page (title page, TOC, and body) across the full paper. The page background must be printable — all built-in brandings set **`printBackground: true`** in their title-page **`pdfOptions`**.

Content and TOC renders always run with `pdf_options.margin: "0"` and get their per-page margins from a paged-media frame table (`<table class="mp-page-frame">` with `<thead>`/`<tfoot>` spacers) that Chromium replicates on every page. The frame margins come straight from the brand's **`contentMargins.<layout>`** — no change to author-visible fields.

> **Brand authors (external `brandingDir`):** any CSS in your brand that targets `td` / `th` / `thead` / `tbody` / `tfoot` without scoping must exclude the frame — suffix selectors with `:not(.mp-page-frame)` (e.g. `table:not(.moravio-toc-table):not(.mp-page-frame) td { … }`). Otherwise your cell padding, borders, or zebra rows will leak into the page-frame spacers and distort per-page margins. The built-in brandings already follow this rule; external `branding.json` folders need to audit their CSS once before enabling the watermark.

**Title-page layout note.** When a watermark is active, the pipeline renders the title page with `pdf_options.margin: "0"` (instead of the brand's original margin) and moves that margin into a `body { padding }` rule so the SVG background can cover the full paper. That change enlarges the Chromium viewport from the brand's original content area to the full paper, which shifts any `position: fixed` title-page decoration visually. To restore the decoration's original visual position, set an optional brand field:

```jsonc
"titlePage": {
  "document": {
    "decorationImgStyle": "position: fixed; right: -364px; top: 100mm; width: 1800px; z-index: -1;",
    "watermarkDecorationTransform": "translate(0, 20mm)"
  }
}
```

The string is emitted verbatim as `.brand-title-decoration { transform: <value> }` in the generated watermark CSS when the watermark is active (the `<img>` that `renderTitleMarkdown` emits for the decoration carries that class). Tune it empirically per brand by generating the title with and without a watermark and comparing the decoration position — different brands use different reference sides (`top`/`right`/`bottom`/`left`) for their decoration, so there is no single formula. Leave the field unset to skip the override entirely.

## Typography normalization

Since v3.7.0 md-pdf runs the Markdown source through a small typography rule table before rendering. The rules target characters that AI assistants commonly emit but that are easy tells and frequently unwanted in client-facing documents.

**Current rules (v3.7.0):**

| Rule id   | What it does                                                                                                                                                         |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `em-dash` | Replaces em-dash (`—`, U+2014) and any surrounding horizontal whitespace with a spaced hyphen (`-`). Matches `word—word`, `word — word`, `word —word`, `word— word`. |

**Where rules do NOT apply** (contents are preserved verbatim):

- Fenced code blocks (` ``` `)
- Inline code (`` ` ``)
- HTML `<pre>` and `<code>` blocks
- Markdown link targets `[text](url)` and image targets `![alt](url)`
- Bare URLs (`https://…`, `http://…`)

**Opt-out via `.meta.json`:**

```jsonc
{
  "typography": {
    "preserve": true, // kill switch — skip all rules
    // or: "disable": ["em-dash"]  // disable specific rules only
  },
}
```

`preserve: true` bypasses the entire pipeline. `disable` accepts an array of rule ids (currently only `em-dash`). Unknown ids are warned about and ignored — they will not break the build. Invalid shapes (`preserve` not boolean, `disable` not an array of strings) fall back to defaults with a warning.

**Examples** demonstrating the feature:

- `examples/document/typography-test.md` — default (normalization **on**). The PDF shows hyphens everywhere except code and URLs.
- `examples/document/typography-preserve-test.md` — `"typography": { "preserve": true }` (normalization **off**). The PDF keeps every em-dash from the source.

**Adding a new rule** is a code change in `lib/typography.js` — extend the `TYPOGRAPHY_RULES` array with a new `{ id, pattern, replacement }` entry. The `pattern` must carry the `g` flag. The skip logic in `applyTypographyRulesToMarkdown` applies to every rule uniformly, so you do not have to re-implement code-block masking per rule.

## Layout, pagination, and TOC at a glance

| Layout     | `titlePage` | `pagination` | `toc`   | Auto slide breaks | Page footer (n/total + mark) | TOC generated | Bottom margin    |
| ---------- | ----------- | ------------ | ------- | ----------------- | ---------------------------- | ------------- | ---------------- |
| `document` | `true`      | `true`       | `true`  | n/a               | Yes (from p.2)               | Yes           | Standard         |
| `document` | `true`      | `true`       | `false` | n/a               | Yes (from p.2)               | No            | Standard         |
| `document` | `false`     | `true`       | `true`  | n/a               | Yes (from p.1)               | Yes           | Standard         |
| `document` | `false`     | `true`       | `false` | n/a               | Yes (from p.1)               | No            | Standard         |
| `document` | any         | `false`      | `true`  | n/a               | Yes                          | Yes           | Slightly smaller |
| `document` | any         | `false`      | `false` | n/a               | Yes                          | No            | Slightly smaller |
| `slides`   | `true`      | `true`       | n/a     | Yes               | Yes                          | No            | Standard         |
| `slides`   | `false`     | `true`       | n/a     | Yes               | Yes (from p.1)               | No            | Standard         |
| `slides`   | any         | `false`      | n/a     | No                | No                           | No            | Slightly smaller |

### Simple mode (no `.meta.json`)

When the `.meta.json` file is missing, md-pdf offers two choices:

1. **Continue without it** — generates a simple PDF with default typography, no title page, TOC, or pagination
2. **Create a `.meta.json` template** — for full control over branding and layout

In non-interactive mode (CI/CD, pipes) or during `--watch` re-runs, simple mode is used automatically.

Example: `examples/simple/simple-document.md` (no sibling `.meta.json`).

## Layout: document vs slides

### Document (`layout`: `document` or omitted)

- A4 portrait, styles from `moravio-style.css`.
- After the title page a **table of contents** is generated from headings in the **original** `.md` file, unless **`toc`** is **`false`** in `.meta.json`. The TOC is rendered by **Chromium** (same engine as the body): the pipeline runs a **measurement pass** on the body PDF, prepends a TOC HTML block to the Markdown, then prints **TOC + body** in one content PDF.
- Page numbers and logo are drawn in the footer (except on the title page).

### Slides (`layout`: `slides`)

- A4 landscape, larger type (`moravio-slides.css`).
- **No TOC** — PDF is title page + slides.
- When **`pagination`** is **`true`** (default): if the Markdown has **no** manual `<div class="page-break"></div>`, automatic breaks are inserted **before every second and subsequent heading at the same level**: either all `#`, or (if there is no `#` in the file) all `##` as slide boundaries. `###` headings do not start a new slide.
- When **`pagination`** is **`false`**: no automatic breaks; headings behave like normal document structure unless you add manual **`page-break`** blocks.

## Headings and table of contents

- Only line-start headings **`#`**, **`##`**, **`###`** (levels 1–3) appear in the generated TOC.
- Headings `####` and below are **not** listed.
- In **`document`** layout, those headings are converted to self-linked HTML **`<h1>`–`<h3>` with stable `id` attributes** before PDF render. The measurement PDF uses those internal destinations to assign TOC page numbers, and the merged PDF uses the same slugs for TOC links. Write headings in normal ATX Markdown; do not hand-edit the generated IDs.
- **`#` lines that are not real headings are ignored** — the extractor tracks CommonMark block context and skips `#` lines inside fenced code blocks (`` ` `` ```or`~~~`, up to 3 spaces of indent), HTML comments (`<!-- … -->`, even across lines), and raw-text HTML blocks (`<script>`, `<pre>`, `<style>`, `<textarea>`). So shell comments like `# build`inside a`bash`block, preprocessor directives inside`c`, etc. stay out of the TOC and don't trigger slide breaks.

## YAML front matter (`---` at the top)

If you start the file with:

```markdown
---
title: Internal note
---

# Real content
```

the pipeline **strips the entire block before processing**. It never appears in the PDF. Use **only** `.meta.json` for document metadata. A `---` block in Markdown is only for notes you want excluded — the tool does not read it.

## Forcing a page break

On its own line:

```html
<div class="page-break"></div>
```

Works in document and slides mode. In slides with **`pagination: true`**, manual page breaks and automatic heading breaks coexist: the tool still auto-injects breaks at heading boundaries where no manual break already exists. Trailing “hanging” `page-break` blocks at the end of the file are trimmed.

## Mermaid diagrams

1. Use a **`mermaid`** fence and a newline right after the opening fence (lowercase, no stray spaces before the closing backticks on the first line):

   ````markdown
   ```mermaid
   flowchart LR
     A --> B
   ```
   ````

2. Before PDF render, blocks are replaced with static SVG inside `<div class="mermaid-diagram">`. `prerender-mermaid.js` uses the Mermaid bundle already installed in `node_modules`, so it does **not** need external CDN access.

3. Invalid or incompatible diagram code: errors go to the console; the block may be missing or broken in the PDF.

4. Do not rely on raw `<div class="mermaid">` without prerender — this package expects pre-generated SVG from the workflow above.

### Controlling diagram size

Diagrams are automatically constrained to **`max-height: 200mm`** in document layout and **`106mm`** in slides. Tall vertical diagrams (e.g. `flowchart TD` with many nodes) scale down automatically to fit within a page.

To control size manually, wrap the Mermaid block in a `<div>` with size classes. Classes follow a Tailwind-like naming convention.

**Height classes** (`mermaid-h{mm}`) — absolute millimeters, reliable in print CSS:

| Class            | max-height |
| ---------------- | ---------- |
| `mermaid-h20`    | 20mm       |
| `mermaid-h40`    | 40mm       |
| `mermaid-h60`    | 60mm       |
| `mermaid-h80`    | 80mm       |
| `mermaid-h100`   | 100mm      |
| `mermaid-h120`   | 120mm      |
| `mermaid-h160`   | 160mm      |
| `mermaid-h200`   | 200mm      |
| `mermaid-h-auto` | no limit   |

**Width classes** (`mermaid-w{%}`) — percentage of content area:

| Class          | max-width |
| -------------- | --------- |
| `mermaid-w25`  | 25%       |
| `mermaid-w33`  | 33%       |
| `mermaid-w50`  | 50%       |
| `mermaid-w66`  | 66%       |
| `mermaid-w75`  | 75%       |
| `mermaid-w100` | 100%      |

Classes can be combined. Example:

````markdown
<div class="mermaid-h80 mermaid-w50">

```mermaid
flowchart TD
    A --> B --> C --> D
```

</div>
````

For one-off sizes outside the predefined steps, use a `style` attribute:

````markdown
<div style="text-align: center;">

```mermaid
flowchart TD
    A --> B --> C
```

</div>
````

### Per-diagram configuration

Mermaid supports YAML frontmatter inside the code block to override defaults per diagram. The config block goes between `---` markers before the diagram type keyword:

````markdown
```mermaid
---
config:
  gantt:
    fontSize: 14
    barHeight: 28
    sectionFontSize: 14
---
gantt
    title Project timeline
    dateFormat YYYY-MM-DD
    axisFormat %b
    section Phase 1
    Task A :a1, 2026-01-01, 30d
```
````

**Available gantt config options:**

| Option            | Type              | Description                                       |
| ----------------- | ----------------- | ------------------------------------------------- |
| `fontSize`        | number            | Font size for axis labels and task text           |
| `sectionFontSize` | string \| number  | Font size for section headers                     |
| `barHeight`       | number            | Height of task bars (px)                          |
| `barGap`          | number            | Gap between bars (px)                             |
| `topPadding`      | number            | Margin between title and diagram                  |
| `leftPadding`     | number            | Space for section names on the left               |
| `rightPadding`    | number            | Space for section names on the right              |
| `titleTopMargin`  | number            | Margin above the title                            |
| `axisFormat`      | string            | Date format on axis (`%b`, `%d. %m.`, `%Y-%m-%d`) |
| `tickInterval`    | string            | Axis tick spacing (e.g. `1month`, `1week`)        |
| `displayMode`     | `""` \| `compact` | Compact layout with overlapping tasks             |
| `useMaxWidth`     | boolean           | Scale to available width (default: true)          |
| `weekday`         | string            | Start day of week (`monday`, `sunday`, etc.)      |

> **Locale:** Mermaid has no built-in `locale` option, but md-pdf **automatically translates** month abbreviations on the gantt axis based on the `language` field in `.meta.json` (currently `en` and `cs`). Use `tickInterval 1month` in the gantt definition to avoid repeated labels.

> **Tip:** Always add `tickInterval 1month` (or `1week`) when using `axisFormat %b` to ensure clean one-label-per-interval axis.

Other diagram types also support per-diagram config. See the [Mermaid configuration docs](https://mermaid.js.org/config/schema-docs/config.html) for the full list.

## Markdown and HTML — what usually works

Typical **GFM** behavior via **marked** (tables with `gfm`, lists, links, images, `**bold**`, `*italic*`, inline code, fenced code).

- **Images**: relative paths are resolved from the `.md` file’s directory during render.
- **Raw HTML** block tags (e.g. `<div class="page-break">`) usually pass through marked — verify complex HTML in the PDF.
- **Horizontal rule** `---` on its own line: hidden in print CSS (`hr { display: none; }`), so you will not see it in the PDF.

## Limitations and caveats

- Document **TOC** uses **Chromium** for layout and links. Page numbers come from internal PDF destinations emitted by the measurement pass, so no external PDF text utility is required.
- Very long tables may split across pages; CSS tries to avoid row breaks, but extreme cases may need content changes.
- External font imports still depend on network availability while generating the PDF. Prefer local `fontCss…` files for offline/stable builds; **`md-pdf-branding-check`** warns when a legacy network import is active.

## Examples in the repository

The [`examples/`](../examples/) folder has ready-made `.md` + `.meta.json` pairs for document and slides. After installing the package they are also under `node_modules/@moravio/md-pdf/examples/`.

Quick test from the repo root:

```bash
node ./convert-to-pdf.js examples/document/sample-document.md
node ./convert-to-pdf.js examples/document/no-title-page.md
node ./convert-to-pdf.js examples/simple/simple-document.md
node ./convert-to-pdf.js examples/slides/sample-slides.md
```

- **`examples/document/no-title-page.md`** — document with `"titlePage": false` (no title page, TOC and pagination still active).
- **`examples/simple/simple-document.md`** — Markdown without `.meta.json` (simple mode — no title page, TOC, or pagination).

Default output is `<basename>.pdf` next to the input `.md`.
