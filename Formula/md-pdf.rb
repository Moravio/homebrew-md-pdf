# typed: false
# frozen_string_literal: true

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
  url "https://github.com/Moravio/homebrew-md-pdf/releases/download/v3.5.7/moravio-md-pdf-3.5.7.tgz",
      using: :nounzip
  sha256 "034e5c980b99777b81de5642b3be4a06a8371559bbc31ff37722fbcf8dcb27f7"
  license :cannot_represent

  depends_on "node@22"
  depends_on arch: :arm64

  def install
    # Install the npm package from the downloaded tarball into a private libexec
    # tree so it does not pollute the global node_modules.
    ENV["PUPPETEER_SKIP_DOWNLOAD"] = "1"
    system "npm", "install", "--prefix", libexec,
           "--production", "--no-audit", "--no-fund",
           cached_download.to_s

    pkg_path = libexec/"node_modules/@moravio/md-pdf"

    # Map each bin name to its JS entry-point inside the installed package.
    bins = {
      "md-pdf"                => "convert-to-pdf.js",
      "md-pdf-branding-check" => "scripts/branding-check.js",
      "md-pdf-branding-init"  => "scripts/branding-init.js",
    }

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

        exec "#{Formula["node@22"].opt_bin}/node" "#{pkg_path}/#{script}" "$@"
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
