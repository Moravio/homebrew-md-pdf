# typed: false
# frozen_string_literal: true

require "json"

# Homebrew formula for @moravio/md-pdf
#
# Usage:
#   brew tap moravio/md-pdf
#   brew install md-pdf
#
# Requires a Chromium-based browser (Google Chrome or Chromium) for PDF
# rendering.  The formula does NOT bundle Chromium — it expects one of the
# common macOS install locations or the PUPPETEER_EXECUTABLE_PATH env var.

class MdPdf < Formula
  desc "CLI to turn Markdown into branded PDFs — title page, TOC, Mermaid, slides"
  homepage "https://github.com/Moravio/md-pdf"
  # url and sha256 are updated automatically by the release workflow.
  url "https://github.com/Moravio/homebrew-md-pdf/releases/download/v4.0.0/moravio-md-pdf-4.0.0.tgz",
      using: :nounzip
  sha256 "d2886f003ad93cce2f52a244c1a0d2ab1caadd0559977276f76717295c6027e8"
  license :cannot_represent
  # Packaging-only fix: the wrapper now resolves Node dynamically instead of
  # pinning the node@22 keg path. Bump so existing installs pick it up on
  # `brew upgrade` without a new upstream release. The release workflow only
  # rewrites url+sha256, never this line, so remove it by hand on the next
  # `version` bump (a lingering revision is harmless but cosmetic: e.g. 4.1.0_1).
  revision 1

  depends_on arch: :arm64
  depends_on "node@22"

  def install
    # Install the npm package from the downloaded tarball into a private libexec
    # tree so it does not pollute the global node_modules.
    ENV["PUPPETEER_SKIP_DOWNLOAD"] = "1"
    # NOTE: std_npm_args is intentionally NOT used here. It calls
    # Language::Node.pack_for_installation, which runs `npm pack` in the build
    # directory and requires a package.json there. This formula installs from a
    # pre-packed release tarball (see `url ... using: :nounzip`) via
    # cached_download — the tarball is never unpacked into the build dir, so
    # there is nothing to pack. The FormulaAudit/StdNpmArgs cop is therefore
    # skipped via `--except-cops` in .github/workflows/brew-test.yml.
    system "npm", "install", "--prefix", libexec,
           "--production", "--no-audit", "--no-fund",
           cached_download.to_s

    pkg_path = libexec/"node_modules/@moravio/md-pdf"

    # Discover bin map from package.json so that future bin additions
    # (e.g. md-pdf-init in 3.18.0) are picked up automatically without
    # touching this formula. Each entry maps a CLI name to its JS
    # entry-point relative to the package root.
    pkg_json = JSON.parse((pkg_path/"package.json").read)
    bins = pkg_json.fetch("bin", {})
    odie "package.json has no bin entries" if bins.empty?

    bins.each do |cmd, script|
      (bin/cmd).write <<~SH
        #!/bin/bash
        set -euo pipefail

        # Resolve Chromium — prefer explicit override, then common macOS paths.
        if [ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ]; then
          for candidate in \\
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \\
            "/Applications/Chromium.app/Contents/MacOS/Chromium" \\
            "$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \\
            "$HOME/Applications/Chromium.app/Contents/MacOS/Chromium"; do
            if [ -x "$candidate" ]; then
              export PUPPETEER_EXECUTABLE_PATH="$candidate"
              break
            fi
          done
        fi

        if [ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ]; then
          echo "Error: No Chromium-based browser found." >&2
          echo "Install Google Chrome or Chromium, or set PUPPETEER_EXECUTABLE_PATH." >&2
          exit 1
        fi

        # Resolve Node — prefer explicit override, then the node@22 keg, then an
        # unversioned keg, then PATH. The fallbacks keep the wrapper working if
        # the node@22 keg is later upgraded away or removed (e.g. Node comes from
        # nvm, or Homebrew moves to a newer node formula), mirroring the Chromium
        # resolver above. The keg prefix is fixed: the formula is arm64-only.
        NODE_BIN="${MD_PDF_NODE:-}"
        if [ -z "$NODE_BIN" ]; then
          for candidate in \\
            "/opt/homebrew/opt/node@22/bin/node" \\
            "/opt/homebrew/opt/node/bin/node" \\
            "$(command -v node 2>/dev/null || true)"; do
            if [ -n "$candidate" ] && [ -x "$candidate" ]; then
              NODE_BIN="$candidate"
              break
            fi
          done
        fi

        if [ -z "$NODE_BIN" ]; then
          echo "Error: Node.js not found." >&2
          echo "Install Node (brew install node) or set MD_PDF_NODE to a node binary." >&2
          exit 1
        fi

        exec "$NODE_BIN" "#{pkg_path}/#{script}" "$@"
      SH
    end
  end

  def caveats
    <<~EOS
      md-pdf needs a Chromium-based browser for PDF rendering.
      Install one of these if you haven't already:

        brew install --cask google-chrome
        brew install --cask chromium

      If Chrome is installed in a non-standard location, set:
        export PUPPETEER_EXECUTABLE_PATH="/path/to/chrome"

      md-pdf finds Node automatically (Homebrew keg or PATH). To pin a specific
      Node binary, set:
        export MD_PDF_NODE="/path/to/node"
    EOS
  end

  test do
    # Set a dummy Chrome path to bypass the wrapper's browser check —
    # the CLI prints usage and exits before Puppeteer is actually launched.
    ENV["PUPPETEER_EXECUTABLE_PATH"] = "/usr/bin/true"
    output = shell_output("#{bin}/md-pdf 2>&1", 1)
    assert_match "Usage: md-pdf", output
  end
end
