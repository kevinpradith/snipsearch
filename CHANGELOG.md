# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-09-04

### Added

- Snip a region of the screen and route it by what is in it: a QR code or
  barcode opens its link, a snip that is mostly text becomes a Google search for
  that text, and anything else goes to Google Lens.
- Three hotkeys: `Ctrl+Alt+L` routes by content, `Ctrl+Alt+K` forces Google
  Lens, `Ctrl+Alt+T` forces the text lookup and copies the text.
- `Install-SnipSearch.ps1`, which registers the hotkeys and removes them again
  with `-Uninstall`.
- A text coverage threshold, so a photo carrying a small caption still reaches
  Lens instead of searching for the caption. `-TextCoverage` overrides it.
- Barcode decoding through ZXing.NET, fetched once by the installer and verified
  against a pinned SHA-256.

[Unreleased]: https://github.com/kevinpradith/snipsearch/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/kevinpradith/snipsearch/releases/tag/v0.1.0
