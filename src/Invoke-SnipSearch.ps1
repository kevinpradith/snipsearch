<#
.SYNOPSIS
    Snip a region of the screen and look it up, the way Circle to Search does.

.DESCRIPTION
    Captures a region with the Windows snip overlay, then routes it by content:
    a QR code or barcode opens its link, a snip that is mostly text becomes a
    Google search for that text, and anything else goes to Google Lens.

    Text only counts as the subject of a snip when it covers enough of the
    snipped area, so a photo carrying a small caption still goes to Lens.

.PARAMETER Mode
    auto (default) routes by content. lens forces the visual search. text
    forces the text lookup and copies the text to the clipboard.

.PARAMETER Image
    Route this image file instead of snipping the screen. Useful for trying a
    change without reaching for the screen.

.PARAMETER TextCoverage
    How much of the snip text must cover before the snip counts as text rather
    than a picture. 0.05 means five percent.

.EXAMPLE
    Invoke-SnipSearch.ps1
    Snip, and let the content decide where it goes.

.EXAMPLE
    Invoke-SnipSearch.ps1 -Mode text
    Snip, read the text, and search for it even if it is a caption on a photo.

.EXAMPLE
    Invoke-SnipSearch.ps1 -Image .\screenshot.png
    Route an existing file, without snipping.
#>
[CmdletBinding()]
param(
    [ValidateSet('auto', 'lens', 'text')]
    [string]$Mode = 'auto',

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$Image,

    [ValidateRange(0.0, 1.0)]
    [double]$TextCoverage = 0.05
)

Set-StrictMode -Version Latest

# Text recognition loads WinRT types, which only .NET Framework projects.
if ($PSVersionTable.PSEdition -eq 'Core') {
    throw 'Run this with Windows PowerShell 5.1 (powershell.exe), not PowerShell 7.'
}

Add-Type -AssemblyName System.Windows.Forms

# Links we should follow rather than search for, from a QR code or from OCR.
$LinkPattern = '^\s*((https?|ftp)://|www\.)\S+\s*$|^\s*(mailto|tel|bitcoin|upi):\S+\s*$'

function Open-Result {
    param([Parameter(Mandatory)][string]$Text)

    $trimmed = $Text.Trim()
    if ($trimmed -match $LinkPattern) {
        if ($trimmed -like 'www.*') { $trimmed = "https://$trimmed" }
        Start-Process $trimmed
    } else {
        if ($trimmed.Length -gt 300) { $trimmed = $trimmed.Substring(0, 300) }
        Start-Process ('https://www.google.com/search?q=' + [uri]::EscapeDataString($trimmed))
    }
}

function Get-ScreenSnip {
    <# Returns the path of the snip, or $null if the user cancelled. #>
    param([Parameter(Mandatory)][string]$Destination)

    try { [Windows.Forms.Clipboard]::Clear() } catch { Write-Verbose 'Clipboard was busy.' }
    Start-Process 'explorer.exe' 'ms-screenclip:'

    $image = $null
    $deadline = (Get-Date).AddSeconds(60)
    while (-not $image -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
        try { $image = [Windows.Forms.Clipboard]::GetImage() } catch { Write-Verbose 'Clipboard was busy.' }
    }
    if (-not $image) { return $null }

    $image.Save($Destination, [Drawing.Imaging.ImageFormat]::Png)
    $image.Dispose()
    $Destination
}

function Read-Barcode {
    <# Returns the payload of a QR code or barcode in the image, else $null.
       Windows has no barcode API, so this needs the ZXing.NET assembly the
       installer fetches; without it the step is skipped rather than failing. #>
    param([Parameter(Mandatory)][string]$Path)

    $assembly = Join-Path $env:LOCALAPPDATA 'SnipSearch\zxing.dll'
    if (-not (Test-Path -LiteralPath $assembly)) {
        Write-Verbose 'ZXing.NET is not installed, skipping barcode detection.'
        return $null
    }

    try {
        Add-Type -Path $assembly
        Add-Type -AssemblyName System.Drawing

        $reader = New-Object ZXing.BarcodeReader
        $reader.AutoRotate = $true          # A snip of a screen is rarely square on.
        $reader.Options.TryHarder = $true

        $bitmap = New-Object System.Drawing.Bitmap $Path
        try { $result = $reader.Decode($bitmap) } finally { $bitmap.Dispose() }
    } catch {
        Write-Verbose "Barcode detection did not run: $_"
        return $null
    }

    if ($result) { $result.Text } else { $null }
}

function Read-ImageText {
    <# Returns the OCR text and the fraction of the image it covers. #>
    param([Parameter(Mandatory)][string]$Path)

    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

    function Await($operation, $type) {
        $task = $asTask.MakeGenericMethod($type).Invoke($null, @($operation))
        $task.Wait() | Out-Null
        $task.Result
    }

    $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
    $null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
    $null = [Windows.Media.Ocr.OcrEngine, Windows.Media.Ocr, ContentType = WindowsRuntime]

    $result = [pscustomobject]@{ Text = ''; Coverage = 0.0 }
    try {
        $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)) ([Windows.Storage.StorageFile])
        $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitmap = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])

        $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
        if (-not $engine) { return $result }

        $ocr = Await ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
        $inked = 0.0
        foreach ($line in $ocr.Lines) {
            foreach ($word in $line.Words) {
                $inked += $word.BoundingRect.Width * $word.BoundingRect.Height
            }
        }
        $result.Text = ($ocr.Text -replace '\s+', ' ').Trim()
        $result.Coverage = $inked / ($decoder.PixelWidth * $decoder.PixelHeight)
    } catch {
        Write-Verbose "OCR did not run: $_"
    }
    $result
}

function Search-WithLens {
    param([Parameter(Mandatory)][string]$Path)

    # curl.exe ships with Windows; the upload answers with the results page.
    $url = & curl.exe --silent --location --max-time 20 --output NUL --write-out '%{url_effective}' `
        --user-agent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' `
        --form "encoded_image=@$Path" 'https://lens.google.com/v3/upload'

    if ($url -like 'http*') {
        Start-Process $url
        return $true
    }

    # Nothing opened, so say so rather than failing silently behind a hotkey.
    [Windows.Forms.MessageBox]::Show(
        'The snip could not be uploaded to Google Lens.', 'SnipSearch') | Out-Null
    $false
}

$snip = if ($Image) { (Resolve-Path -LiteralPath $Image).Path }
        else { Get-ScreenSnip -Destination (Join-Path $env:TEMP 'snipsearch.png') }
if (-not $snip) { exit 1 }

if ($Mode -eq 'auto') {
    $barcode = Read-Barcode -Path $snip
    if ($barcode) {
        if ($barcode -match $LinkPattern) {
            Open-Result -Text $barcode
        } else {
            Set-Clipboard $barcode
            [Windows.Forms.MessageBox]::Show($barcode, 'Barcode content') | Out-Null
        }
        exit 0
    }
}

if ($Mode -ne 'lens') {
    $ocr = Read-ImageText -Path $snip
    $wordy = ((($ocr.Text -split ' ').Count -ge 2 -and $ocr.Text.Length -ge 4) -or $ocr.Text.Length -ge 8)
    if ($wordy -and ($ocr.Coverage -ge $TextCoverage -or $Mode -eq 'text')) {
        Set-Clipboard $ocr.Text
        Open-Result -Text $ocr.Text
        exit 0
    }
    if ($Mode -eq 'text') {
        Write-Verbose 'No text found in the snip.'
        exit 1
    }
}

if (Search-WithLens -Path $snip) { exit 0 } else { exit 1 }
