<#
ComfyTreeAndDump.ps1
- Prints an ASCII tree (files first, then folders) and saves it as <folder>.txt,
  enclosed in triple backticks.
- Excludes __pycache__ contents from the tree and from file selection.
- Lets you pick files by name/pattern; writes a consolidated txt with each file
  wrapped in triple backticks and the relative path as a header.
#>

[CmdletBinding()]
param(
  [string]$RootDir,
  [string]$OutputDump
)

function Show-Banner {
  param(
    [string]$Text = 'Comfy Node Slop Dev Helper',
    [switch]$NoClear,
    [switch]$Ascii
  )
  try { $host.UI.RawUI.WindowTitle = $Text } catch {}
  try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

  if (-not $NoClear) { Clear-Host }

  $minInner = 30
  $maxCols  = [Math]::Max(40, [Console]::WindowWidth - 4)
  $inner    = [Math]::Max($minInner, [Math]::Min($maxCols, $Text.Length + 6))
  $padLeft  = [Math]::Max(0, [Math]::Floor(($inner - $Text.Length)/2))
  $padRight = [Math]::Max(0, $inner - $Text.Length - $padLeft)

  if ($Ascii) {
    $top = '+' + ('-' * ($inner + 2)) + '+'
    $mid = '| ' + (' ' * $padLeft) + $Text + (' ' * $padRight) + ' |'
    $bot = '+' + ('-' * ($inner + 2)) + '+'
    Write-Host $top -ForegroundColor Cyan
    Write-Host $mid -ForegroundColor Yellow
    Write-Host $bot -ForegroundColor Cyan
  } else {
    # Build Unicode box chars via char codes (file stays ASCII-safe)
    $tl = [char]0x250F  # ┏
    $tr = [char]0x2513  # ┓
    $bl = [char]0x2517  # ┗
    $br = [char]0x251B  # ┛
    $v  = [char]0x2503  # ┃
    $h  = ([char]0x2501).ToString() * ($inner + 2) # '━' repeated

    $top = "$tl$h$tr"
    $mid = "$v " + (' ' * $padLeft) + $Text + (' ' * $padRight) + " $v"
    $bot = "$bl$h$br"

    Write-Host $top -ForegroundColor Cyan
    Write-Host $mid -ForegroundColor Yellow
    Write-Host $bot -ForegroundColor Cyan
  }
  Write-Host ''
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# Folders to list but not descend into
$ExcludedDirs = @('__pycache__', '.git')

Show-Banner -NoClear   # reprint banner (no screen clear) so it stays visible above the prompt
function Resolve-Root {
  param([string]$InputPath)
  if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $val = Read-Host "Enter root directory (Press Enter to use current: $(Get-Location))"
    if ([string]::IsNullOrWhiteSpace($val)) { $val = (Get-Location).Path }
  } else { $val = $InputPath }
  (Resolve-Path -LiteralPath $val).Path
}

# Compatible relative path (Windows PowerShell 5.1)
function Get-RelativePath {
  param([string]$Root, [string]$FullPath)
  $rootUri = [Uri]((Resolve-Path -LiteralPath $Root).Path + [IO.Path]::DirectorySeparatorChar)
  $fileUri = [Uri]((Resolve-Path -LiteralPath $FullPath).Path)
  $rootUri.MakeRelativeUri($fileUri).ToString().Replace('/', '\')
}

function Get-ItemsSorted {
  param([string]$Path)
  # Force arrays so .Count works even with 0/1 items
  $files = @(Get-ChildItem -LiteralPath $Path -File -Force | Sort-Object Name)
  $dirs  = @(Get-ChildItem -LiteralPath $Path -Directory -Force | Sort-Object Name)
  [PSCustomObject]@{ Files = $files; Dirs = $dirs }
}

function Get-AsciiTreeInner {
  param([string]$Path, [string]$Prefix)

  $lines = New-Object System.Collections.Generic.List[string]
  $items = Get-ItemsSorted -Path $Path

  foreach ($f in $items.Files) {
    $null = $lines.Add($Prefix + "    " + $f.Name)
  }

  for ($i = 0; $i -lt $items.Dirs.Count; $i++) {
    $dir    = $items.Dirs[$i]
    $isLast = ($i -eq $items.Dirs.Count - 1)

    $connector   = ""
    $childPrefix = ""
    if ($isLast) {
      $connector   = "\---"
      $childPrefix = $Prefix + "    "
    } else {
      $connector   = "+---"
      $childPrefix = $Prefix + "|   "
    }

    $null = $lines.Add($Prefix + $connector + $dir.Name)

	if ($ExcludedDirs -notcontains $dir.Name) {
	  $childLines = Get-AsciiTreeInner -Path $dir.FullName -Prefix $childPrefix
	  foreach ($cl in $childLines) { $null = $lines.Add([string]$cl) }
	}
  }
  return $lines
}

function New-AsciiTree {
  param([string]$Path)
  $rootItem = Get-Item -LiteralPath $Path
  $driveLabel = $rootItem.PSDrive.Name + ":."
  $lines = New-Object System.Collections.Generic.List[string]
  $null = $lines.Add($driveLabel)

  $items = Get-ItemsSorted -Path $Path

  foreach ($f in $items.Files) {
    $null = $lines.Add("|   " + $f.Name)
  }

  for ($i = 0; $i -lt $items.Dirs.Count; $i++) {
    $dir    = $items.Dirs[$i]
    $isLast = ($i -eq $items.Dirs.Count - 1)

    $connector   = ""
    $childPrefix = ""
    if ($isLast) {
      $connector   = "\---"
      $childPrefix = "    "
    } else {
      $connector   = "+---"
      $childPrefix = "|   "
    }

    $null = $lines.Add($connector + $dir.Name)

	if ($ExcludedDirs -notcontains $dir.Name) {
	  $childLines = Get-AsciiTreeInner -Path $dir.FullName -Prefix $childPrefix
	  foreach ($cl in $childLines) { $null = $lines.Add([string]$cl) }
	}
  }
  return $lines
}

function Build-FileIndex {
  param([string]$Root)
  @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
    Where-Object {
      $_.FullName -notmatch '(?i)(\\|/)(__pycache__|\.git)(\\|/|$)'
    })
}

function Find-Matches {
  param([string]$Token, [array]$AllFiles, [string]$Root)

  $tok = $Token.Trim(" `"`'")
  if ([string]::IsNullOrWhiteSpace($tok)) { return @() }

  $matches = @()

  if ($tok -match '[*?\\/]') {
    $matches = @(
      $AllFiles | Where-Object {
        $_.Name -like $tok -or (Get-RelativePath -Root $Root -FullPath $_.FullName) -like $tok
      }
    )
  } else {
    $matches = @($AllFiles | Where-Object { $_.Name -ieq $tok })
    if ($matches.Count -eq 0) {
      $matches = @($AllFiles | Where-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) -ieq $tok })
    }
    if ($matches.Count -eq 0) {
      $matches = @($AllFiles | Where-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) -ilike "*$tok*" })
    }
  }

  return @($matches)  # force array (even when only one match)
}

function Expand-Selection {
  param([string]$input, [int]$max)
  $input = $input.Trim()
  if ($input -match '^(?i:a|all)$') { return 1..$max }
  if ($input -match '^(?i:s|skip)$') { return @() }

  $nums = New-Object System.Collections.Generic.List[int]
  foreach ($chunk in ($input -split '\s*,\s*')) {
    if ($chunk -match '^\d+$') {
      $n = [int]$chunk
      if ($n -ge 1 -and $n -le $max) { $nums.Add($n) }
    } elseif ($chunk -match '^\s*(\d+)\s*-\s*(\d+)\s*$') {
      $start = [int]$Matches[1]; $end = [int]$Matches[2]
      if ($start -le $end) {
        foreach ($n in $start..$end) {
          if ($n -ge 1 -and $n -le $max) { $nums.Add($n) }
        }
      }
    }
  }
  @($nums | Select-Object -Unique | Sort-Object)
}

function Is-BinaryFile {
  param([string]$Path)
  try {
    $fs = [IO.File]::OpenRead($Path)
    try {
      $buf = New-Object byte[] 8192
      $read = $fs.Read($buf, 0, $buf.Length)
      for ($i=0; $i -lt $read; $i++) {
        if ($buf[$i] -eq 0) { return $true }
      }
      return $false
    } finally { $fs.Dispose() }
  } catch { return $true }
}

# ===================== Main =====================
$root = Resolve-Root -InputPath $RootDir
$rootLeaf = Split-Path -Leaf $root

Show-Banner  # prints the badge and sets window title
Write-Host ""
Write-Host "Generating ASCII tree for: $root" -ForegroundColor Cyan
$treeLines = New-AsciiTree -Path $root

# Show in terminal
$treeLines | ForEach-Object { Write-Host $_ }

# Save to <folder>.txt, enclosed in triple backticks
$treeTxtPath = Join-Path $root "$rootLeaf.txt"
$treeContent = '```' + "`r`n" + ($treeLines -join "`r`n") + "`r`n" + '```' + "`r`n"
Set-Content -LiteralPath $treeTxtPath -Value $treeContent -Encoding UTF8
Write-Host ""
Write-Host "Tree saved to: $treeTxtPath" -ForegroundColor Green

# Ask for files to collect
Show-Banner -NoClear   # reprint banner (no screen clear) so it stays visible above the prompt
$spec = Read-Host "Enter file names or patterns (comma/semicolon/pipe/space-separated), or press Enter to skip"
if ([string]::IsNullOrWhiteSpace($spec)) {
  Write-Host "No files specified. Done." -ForegroundColor Yellow
  return
}

# Split on comma, semicolon, pipe, or whitespace; keep non-empty tokens
$tokens = @($spec -split '[,;|\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$allFiles = Build-FileIndex -Root $root

$selected = @()

foreach ($tok in $tokens) {
  $matches = @(Find-Matches -Token $tok -AllFiles $allFiles -Root $root)

  if ($matches.Count -eq 0) {
    Write-Host "No matches for '$tok'." -ForegroundColor Yellow
    continue
  }

  if ($matches.Count -eq 1) {
    $selected += ,$matches[0].FullName
    continue
  }

  # Ambiguity — prompt the user
  Write-Host ""
  Write-Host "Multiple matches for '$tok':" -ForegroundColor Cyan
  for ($i=0; $i -lt $matches.Count; $i++) {
    $rel = Get-RelativePath -Root $root -FullPath $matches[$i].FullName
    Write-Host ("[{0}] {1}" -f ($i+1), $rel)
  }
  $sel = Read-Host "Select numbers (e.g., 1,3-5), 'A' for all, or 'S' to skip"
  $idxs = @(Expand-Selection -input $sel -max $matches.Count)
  if ($idxs.Count -eq 0) { Write-Host "Skipped '$tok'." -ForegroundColor Yellow; continue }
  foreach ($i in $idxs) { $selected += ,$matches[$i-1].FullName }
}

# Deduplicate while preserving order
$seen  = New-Object 'System.Collections.Generic.HashSet[string]'
$final = @()
foreach ($p in $selected) {
  if ($seen.Add($p)) { $final += ,$p }
}

if ($final.Count -eq 0) {
  Write-Host "No files selected. Done." -ForegroundColor Yellow
  return
}

# Output dump filename
if ([string]::IsNullOrWhiteSpace($OutputDump)) {
  $defaultName = "selected_files_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date)
  $outName = Read-Host "Output file name (press Enter for $defaultName)"
  if ([string]::IsNullOrWhiteSpace($outName)) { $outName = $defaultName }
  $OutputDump = Join-Path $root $outName
} else {
  if (-not [IO.Path]::IsPathRooted($OutputDump)) {
    $OutputDump = Join-Path $root $OutputDump
  }
}

# Build the output text
$fence = '```'
$sb = New-Object System.Text.StringBuilder

foreach ($p in $final) {
  $rel = Get-RelativePath -Root $root -FullPath $p
  $null = $sb.AppendLine($rel)
  $null = $sb.AppendLine($fence)

  if (Is-BinaryFile -Path $p) {
    $null = $sb.AppendLine('[[binary or non-text file skipped]]')
  } else {
    try {
      $text = Get-Content -LiteralPath $p -Raw -Encoding UTF8
    } catch {
      try { $text = Get-Content -LiteralPath $p -Raw } catch { $text = '[[unable to read file]]' }
    }
    $null = $sb.Append($text)
    if (-not $text.EndsWith("`n") -and -not $text.EndsWith("`r")) {
      $null = $sb.AppendLine()
    }
  }

  $null = $sb.AppendLine($fence)
  $null = $sb.AppendLine()
}

Set-Content -LiteralPath $OutputDump -Value $sb.ToString() -Encoding UTF8
Write-Host ""
Write-Host "Wrote selected contents to: $OutputDump" -ForegroundColor Green