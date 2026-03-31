# Homebrew Tap — moravio-pdf

[Homebrew](https://brew.sh) tap for installing
[moravio-pdf](https://github.com/Moravio/md-pdf), a CLI that turns Markdown
into branded PDFs.

## Installation

```bash
brew tap moravio/md-pdf
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

## Updating

```bash
brew update
brew upgrade md-pdf
```

## How it works

- The formula installs `@moravio/md-pdf` from a release tarball hosted on
  this repo into an isolated `libexec` prefix.
- Puppeteer's bundled Chromium download is skipped — the wrapper scripts
  resolve your locally installed Chrome or Chromium instead.
- Node.js 22 (LTS) is installed as a Homebrew dependency.
- The formula and release tarballs are updated automatically by the
  [release workflow](https://github.com/Moravio/md-pdf/blob/main/.github/workflows/release.yml)
  in the source repo whenever a new version is tagged.
