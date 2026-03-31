# Homebrew Tap — @moravio/md-pdf

Private [Homebrew](https://brew.sh) tap for installing
[moravio-pdf](https://github.com/Moravio/md-pdf), a CLI that turns Markdown
into branded PDFs.

## Installation

```bash
# Authenticate Homebrew for private GitHub repos (one-time)
export HOMEBREW_GITHUB_API_TOKEN="<your-token>"

# Add the tap
brew tap moravio/md-pdf https://github.com/Moravio/homebrew-md-pdf.git

# Install
brew install md-pdf
```

### Prerequisites

`moravio-pdf` renders PDFs via headless Chromium. Install a Chromium-based
browser if you don't have one already:

```bash
brew install --cask google-chrome
```

The wrapper script auto-detects Chrome and Chromium at standard macOS paths.
To use a custom location:

```bash
export PUPPETEER_EXECUTABLE_PATH="/path/to/chrome"
```

## Usage

```bash
moravio-pdf document.md                    # → document.pdf
moravio-pdf document.md output.pdf         # explicit output path
moravio-pdf-branding-init ./my-brand       # scaffold a branding folder
moravio-pdf-branding-check ./my-brand      # validate branding config
```

See the [markdown authoring guide](https://github.com/Moravio/md-pdf/blob/main/docs/markdown-authoring.md)
for document format, metadata, and branding options.

## Updating

```bash
brew update
brew upgrade md-pdf
```

## How it works

- The formula installs `@moravio/md-pdf` from a GitHub Release tarball into
  an isolated `libexec` prefix (no global `node_modules` pollution).
- Puppeteer's bundled Chromium download is skipped — the wrapper scripts
  resolve your locally installed Chrome or Chromium instead.
- Node.js 22 (LTS) is installed as a Homebrew dependency.

## For maintainers

After tagging a new release in `Moravio/md-pdf`:

1. The [release workflow](https://github.com/Moravio/md-pdf/blob/main/.github/workflows/release.yml)
   creates a GitHub Release with the npm tarball.
2. Update the formula:
   ```bash
   cd /path/to/md-pdf
   ./homebrew/update-formula.sh v2.1.0
   ```
3. Copy the updated formula here and push:
   ```bash
   cp /path/to/md-pdf/homebrew/Formula/md-pdf.rb Formula/
   git add -A && git commit -m "Update md-pdf to v2.1.0" && git push
   ```
