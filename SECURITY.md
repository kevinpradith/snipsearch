# Security Policy

## Supported versions

The latest commit on `main` is the only supported version.

## Reporting a vulnerability

Report privately through
[GitHub Security Advisories](https://github.com/kevinpradith/snipsearch/security/advisories/new).
Please do not open a public issue for anything exploitable.

Expect an acknowledgement within seven days, and a fix or an explanation of why
it is not one within thirty.

## What SnipSearch touches

Worth knowing before you audit it:

- **It reads the screen when you ask it to.** A snip is written to
  `%TEMP%\snipsearch.png` and is overwritten by the next one.
- **The Lens path uploads that image to Google.** This is the only case where
  the image leaves the machine. Barcode decoding and OCR happen locally.
- **The text path sends OCR text to Google as a search query**, and copies it to
  the clipboard.
- **The installer downloads one assembly** from NuGet, [ZXing.NET](https://github.com/micjahn/ZXing.Net),
  and refuses to keep it unless it matches a SHA-256 pinned in
  `src/Install-BarcodeReader.ps1`. Nothing else is fetched at runtime.
- **A decoded QR code is opened with `Start-Process`.** Only strings matching a
  URL scheme in the allowlist are opened; anything else is shown in a dialog and
  copied to the clipboard rather than executed. A malicious QR code can still
  send you to a malicious site, exactly as a phone camera would.
