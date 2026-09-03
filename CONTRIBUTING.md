# Contributing

Thanks for taking the time. SnipSearch is small on purpose, so the bar for new
code is that it earns its place: prefer something Windows already ships over a
new dependency, and a few lines over a new file.

## Getting set up

You need Windows 11 and the PowerShell that ships with it. Nothing to build.

```powershell
git clone https://github.com/kevinpradith/snipsearch.git
cd snipsearch
powershell -NoProfile -ExecutionPolicy Bypass -File Install-SnipSearch.ps1
```

Install [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) once,
since CI will run it against your pull request anyway:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser
```

## Working on the routing

Route a file instead of the screen. This is far quicker than reaching for a
screenshot every time, and `-Verbose` prints why a step was skipped.

```powershell
.\src\Invoke-SnipSearch.ps1 -Image .\sample.png -Mode auto -Verbose
```

Three images cover the interesting cases: a QR code, a screenshot of a
paragraph, and a photo with a small caption on it. The last one is the one that
regresses: if the caption starts winning, the text coverage threshold is wrong.

## Before you open a pull request

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse
```

It must report nothing. Then route those three images and confirm each one
still ends up where it should.

## Style

- PowerShell follows the [PowerShell Practice and Style](https://poshcode.gitbook.io/powershell-practice-and-style)
  guide: approved Verb-Noun names, `PascalCase` for functions and parameters,
  four spaces, comment-based help on anything a user runs directly.
- Comments explain why a line exists, not what it does. If a threshold or a
  workaround is not obvious in six months, say what it is guarding against.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `docs:`, `refactor:`, `build:`, `chore:`. Write the body in
  full sentences, explaining what was wrong before.

## Reporting things

Bugs and ideas both go to [Issues](https://github.com/kevinpradith/snipsearch/issues).
For anything security related, read [SECURITY.md](SECURITY.md) first.
