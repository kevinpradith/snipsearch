# SnipSearch

Circle-to-Search for Windows 11 machines that cannot run Click to Do, which
needs a Copilot+ PC with a 40+ TOPS NPU.

Press a hotkey, drag a box around anything on screen, and the snip is routed by
what is actually in it:

| In the snip | What happens |
| --- | --- |
| QR code or barcode | its link opens, or its text is copied and shown |
| mostly text | Google search for that text, or the URL opens if it is one |
| anything else | Google Lens visual search |

Text only counts as the subject of a snip when it covers at least 5% of the
snipped area, so a photo carrying a small caption still goes to Lens rather
than searching for the caption.

## Install

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Install-SnipSearch.ps1
```

This creates three Start Menu shortcuts, which is how Windows grants a global
hotkey. Re-running it is safe, and `-Uninstall` removes them again.

| Key | Mode |
| --- | --- |
| `Ctrl+Alt+L` | route by content |
| `Ctrl+Alt+K` | force Google Lens |
| `Ctrl+Alt+T` | force the text lookup, and copy the text |

Windows reserves the `Ctrl+Alt` prefix for shortcut hotkeys, so only the last
key can be changed, in each shortcut's properties.

To reach it from the touchpad: Settings > Bluetooth & devices > Touchpad >
Advanced gestures > Three-finger gestures > Taps > Custom shortcut, and record
`Ctrl+Alt+L`. Windows exposes taps only; there is no hold gesture to bind.

## Requirements

Windows 11 and nothing else installed. Capture is the Windows snip overlay
(`ms-screenclip:`), so multi-monitor, DPI scaling and HDR stay Windows'
problem; OCR is `Windows.Media.Ocr`; the upload is the `curl.exe` that ships
with Windows.

The one gap is barcodes, for which Windows has no API. The installer fetches
[ZXing.NET](https://github.com/micjahn/ZXing.Net) from NuGet, checks it against
a known SHA-256, and keeps it under `%LOCALAPPDATA%\SnipSearch`. If that
download fails, barcode reading is skipped and everything else still works.

## Layout

```
Install-SnipSearch.ps1         registers or removes the hotkeys
src/Invoke-SnipSearch.ps1      capture and routing
src/Install-BarcodeReader.ps1  fetches and verifies ZXing.NET
src/SnipSearch.vbs             runs the script without a console window
```

## Development

Route a file instead of the screen, which is the way to try a change without
reaching for a screenshot:

```powershell
.\src\Invoke-SnipSearch.ps1 -Image .\sample.png -Mode auto -Verbose
```

`-TextCoverage` overrides the 5% threshold if text keeps being mistaken for a
picture, or the other way around.

Lint before committing:

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse
```

## Privacy

Barcode decoding and OCR happen on the machine. The image leaves it only on the
Lens path, which uploads the snip to Google.

## License

MIT, see [LICENSE](LICENSE).
