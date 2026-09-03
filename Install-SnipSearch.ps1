<#
.SYNOPSIS
    Registers the SnipSearch hotkeys, or removes them again.

.DESCRIPTION
    Windows gives a Start Menu shortcut a global hotkey, so the install is
    three shortcuts pointing at src\SnipSearch.vbs. Windows reserves the
    Ctrl+Alt prefix for these, which is why the keys are what they are.

    Re-running the install is safe: it overwrites the shortcuts in place.

.PARAMETER Uninstall
    Delete the shortcuts instead of creating them.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File Install-SnipSearch.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Uninstall)

Set-StrictMode -Version Latest

$shortcuts = @(
    @{ Name = 'SnipSearch.lnk';              Mode = '';      Key = 'CTRL+ALT+L'; Description = 'Snip and look it up' }
    @{ Name = 'SnipSearch (image).lnk';      Mode = 'lens';  Key = 'CTRL+ALT+K'; Description = 'Snip and search with Google Lens' }
    @{ Name = 'SnipSearch (text).lnk';       Mode = 'text';  Key = 'CTRL+ALT+T'; Description = 'Snip, read the text, search it' }
)

$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$launcher = Join-Path $PSScriptRoot 'src\SnipSearch.vbs'

if ($Uninstall) {
    foreach ($shortcut in $shortcuts) {
        $path = Join-Path $startMenu $shortcut.Name
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path
            "removed  $($shortcut.Name)"
        }
    }
    return
}

if (-not (Test-Path -LiteralPath $launcher)) {
    throw "Launcher not found at $launcher"
}

$shell = New-Object -ComObject WScript.Shell
foreach ($shortcut in $shortcuts) {
    $path = Join-Path $startMenu $shortcut.Name
    if (-not $PSCmdlet.ShouldProcess($path, 'Create shortcut')) { continue }

    $link = $shell.CreateShortcut($path)
    $link.TargetPath = Join-Path $env:WINDIR 'System32\wscript.exe'
    $link.Arguments = '"{0}"{1}' -f $launcher, $(if ($shortcut.Mode) { " $($shortcut.Mode)" } else { '' })
    $link.WorkingDirectory = Split-Path $launcher
    $link.IconLocation = (Join-Path $env:WINDIR 'System32\SnippingTool.exe') + ',0'
    $link.Description = $shortcut.Description
    $link.HotKey = $shortcut.Key
    $link.Save()
    "{0}  {1}" -f $shortcut.Key, $shortcut.Name
}

# Barcode reading is the one part that needs something Windows does not ship.
if (-not (& (Join-Path $PSScriptRoot 'src\Get-WslPython.ps1') -Refresh)) {
    Write-Warning 'No WSL interpreter with OpenCV found, so QR and barcode reading will be skipped.'
    Write-Warning 'Install it with: wsl python3 -m pip install opencv-python-headless'
}
