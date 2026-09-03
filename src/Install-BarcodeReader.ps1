<#
.SYNOPSIS
    Downloads the ZXing.NET assembly used to read QR codes and barcodes.

.DESCRIPTION
    Writes the assembly path to the pipeline. Windows ships no barcode API, so
    this one library is the only thing SnipSearch cannot get from the machine
    it runs on. It is fetched once, verified against a known hash, and kept
    outside the repository under %LOCALAPPDATA%.

.PARAMETER Force
    Download again even if the assembly is already in place.
#>
[CmdletBinding()]
param([switch]$Force)

Set-StrictMode -Version Latest

$version = '0.16.11'
$expectedHash = '52F00A43F9574A411009899A6236F3EFB5B597FBAE0F3163DFEC9CBB0C1F4D38'
$entry = 'lib/net48/zxing.dll'   # PowerShell 5.1 runs on .NET Framework 4.8.

$assembly = Join-Path $env:LOCALAPPDATA 'SnipSearch\zxing.dll'

if (-not $Force -and (Test-Path -LiteralPath $assembly)) {
    if ((Get-FileHash -LiteralPath $assembly -Algorithm SHA256).Hash -eq $expectedHash) {
        return $assembly
    }
    Write-Verbose 'Cached assembly does not match its hash, downloading again.'
}

$package = Join-Path ([IO.Path]::GetTempPath()) "zxing-$version.zip"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -OutFile $package `
        -Uri "https://www.nuget.org/api/v2/package/ZXing.Net/$version"

    New-Item -ItemType Directory -Force -Path (Split-Path $assembly) | Out-Null

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($package)
    try {
        $file = $archive.GetEntry($entry)
        if (-not $file) { throw "$entry is missing from the ZXing.Net package" }
        [IO.Compression.ZipFileExtensions]::ExtractToFile($file, $assembly, $true)
    } finally {
        $archive.Dispose()
    }

    $actualHash = (Get-FileHash -LiteralPath $assembly -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        Remove-Item -LiteralPath $assembly
        throw "Downloaded assembly hash $actualHash does not match the expected $expectedHash"
    }
    $assembly
} finally {
    Remove-Item -LiteralPath $package -ErrorAction SilentlyContinue
}
