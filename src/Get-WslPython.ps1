<#
.SYNOPSIS
    Finds a WSL Python interpreter that can import OpenCV.

.DESCRIPTION
    Writes the interpreter path to the pipeline, or nothing if no interpreter
    on this machine has OpenCV. The answer is cached, because probing costs a
    WSL round trip per candidate and this runs behind a hotkey.

.PARAMETER Refresh
    Ignore the cached answer and probe again.
#>
[CmdletBinding()]
param([switch]$Refresh)

Set-StrictMode -Version Latest

$cacheFile = Join-Path $env:LOCALAPPDATA 'SnipSearch\wsl-python.txt'

if (-not $Refresh -and (Test-Path -LiteralPath $cacheFile)) {
    $cached = (Get-Content -LiteralPath $cacheFile -Raw).Trim()
    if ($cached) { return $cached }
}

$candidates = @('python3')
try {
    $wslHome = & wsl.exe -e printenv HOME 2>$null
    if ($LASTEXITCODE -eq 0 -and $wslHome) {
        $wslHome = ($wslHome | Select-Object -First 1).Trim()
        $candidates += @('.miniforge3', 'miniconda3', 'anaconda3', '.local') |
            ForEach-Object { "$wslHome/$_/bin/python3" }
    }

    foreach ($python in $candidates) {
        & wsl.exe -e $python -c 'import cv2' 2>$null
        if ($LASTEXITCODE -ne 0) { continue }

        New-Item -ItemType Directory -Force -Path (Split-Path $cacheFile) | Out-Null
        Set-Content -LiteralPath $cacheFile -Value $python -Encoding UTF8
        return $python
    }
} catch {
    Write-Verbose "WSL is not available: $_"
}
