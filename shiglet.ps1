#Requires -Version 5.1

<#
.SYNOPSIS
    Turn text into ASCII art right from your terminal.

.DESCRIPTION
    shiglet.ps1 renders text using the local character files in the chars folder.
    Letter and digit files are named after the character (a.txt, 7.txt).
    punctuation uses word names (comma.txt, dash.txt, etc.).
    Each character is 4 rows tall and made of half-block shapes
    (U+2580, U+2584, U+2588), with the top row used for tall letters with ascenders.
    Any missing characters get skipped with a warning message.

    The ASCII arts are inspired by OpenCode font (https://opencode.ai/font/).

.PARAMETER Text
    The text to render. If you pass multiple arguments,
    they'll be joined with a single space. Unquoted commas work too:
    Hello, World! is read as text instead of a PowerShell array.

.PARAMETER Gap
    Spacing between characters (default: 1). Use 0 for tight letter spacing.

.PARAMETER Width
    Maximum banner width (in columns). Wraps text at word breaks.
    Default is 0 (disabled). Words wider than Width won't be split.

.PARAMETER List
    Lists the characters that have glyph files and exits.

.EXAMPLE
    .\shiglet.ps1 hello

    Renders "hello".

.EXAMPLE
    .\shiglet.ps1 Hello, World! 2026

    Renders two words and a number, including the comma and exclamation
    mark. The unquoted comma is read as text rather than a PowerShell array.

.EXAMPLE
    .\shiglet.ps1 Wait... what? Oh, no!

    Renders the comma, period, question mark, and exclamation mark glyphs.

.EXAMPLE
    .\shiglet.ps1 -Gap 0 -Width 60 the quick brown fox

    Renders the pangram with no space between glyphs, wrapping at 60 columns.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [object[]] $Text,

    [ValidateRange(0, 64)]
    [int] $Gap = 1,

    [ValidateRange(0, 10000)]
    [int] $Width = 0,

    [switch] $List
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-GlyphHeight {
    param([object[]] $Glyphs)

    $height = 0
    foreach ($glyph in $Glyphs) {
        if ($glyph.Height -gt $height) { $height = $glyph.Height }
    }
    return $height
}

function Resolve-Glyph {
    param([char] $Character)

    $key = ([string] $Character).ToLowerInvariant()
    if ($script:Glyphs.ContainsKey($key)) {
        return $script:Glyphs[$key]
    }

    if ([char]::IsWhiteSpace($Character)) {
        return $script:SpaceGlyph
    }

    if (-not $script:WarnedCharacters.ContainsKey($key)) {
        Write-Warning ("No glyph for character '{0}' (U+{1:X4}); skipping it." -f $Character, [int] $Character)
        $script:WarnedCharacters[$key] = $true
    }
    return $null
}

function Get-WordItems {
    param([string] $Word)

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($character in $Word.ToCharArray()) {
        $glyph = Resolve-Glyph -Character $character
        if ($null -ne $glyph) {
            [void] $items.Add($glyph)
        }
    }
    return ,$items.ToArray()
}

function Join-TextArguments {
    param([object[]] $Arguments)

    if ($null -eq $Arguments -or $Arguments.Count -eq 0) { return '' }

    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($argument in $Arguments) {
        if ($argument -is [System.Array]) {
            $segments = @($argument | ForEach-Object { [string] $_ })
            [void] $parts.Add(($segments -join ', '))
        }
        else {
            [void] $parts.Add([string] $argument)
        }
    }

    return ($parts -join ' ')
}

function Get-LiteralText {
    param($Ast)

    switch ($Ast.GetType().Name) {
        'StringConstantExpressionAst' { return $Ast.Value }
        'ConstantExpressionAst' { return [string] $Ast.Value }
        'ExpandableStringExpressionAst' { return $Ast.Value }
        default { return $null }
    }
}

function Get-TrailingCommaText {
    param(
        [string] $Line,
        [string] $CommandName
    )

    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Line, [ref] $tokens, [ref] $parseErrors)
    if ($null -eq $ast -or $parseErrors.Count -gt 0) { return $null }

    # Find the invocation of this script (the line may contain other commands).
    $allCommands = @($ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst]
    }, $true))

    $namedCommands = @($allCommands | Where-Object {
        $_.CommandElements.Count -gt 0 -and
        $_.CommandElements[0].Extent.Text.Trim('"', "'").EndsWith($CommandName, [System.StringComparison]::OrdinalIgnoreCase)
    })

    if ($namedCommands.Count -gt 0) {
        $command = $namedCommands[$namedCommands.Count - 1]
    }
    else {
        # The script may have been invoked through a variable (for example
        # "& $script Hello, World!"). Fall back to the only command on the line
        # that ends in a comma group.
        $arrayCommands = @($allCommands | Where-Object {
            $_.CommandElements.Count -gt 0 -and
            $_.CommandElements[$_.CommandElements.Count - 1] -is [System.Management.Automation.Language.ArrayLiteralAst]
        })

        if ($arrayCommands.Count -ne 1) { return $null }
        $command = $arrayCommands[0]
    }

    # When a comma group is the final argument, PowerShell flattens it and the
    # comma disappears before this script runs. Read it back from the source.
    $last = $command.CommandElements[$command.CommandElements.Count - 1]
    if ($last -isnot [System.Management.Automation.Language.ArrayLiteralAst]) { return $null }

    $elements = @($last.Elements)
    if ($elements.Count -lt 2) { return $null }

    $builder = New-Object System.Text.StringBuilder
    for ($elementIndex = 0; $elementIndex -lt $elements.Count; $elementIndex++) {
        $value = Get-LiteralText -Ast $elements[$elementIndex]
        if ($null -eq $value) { return $null }

        if ($elementIndex -gt 0) {
            $previous = $elements[$elementIndex - 1]
            $length = $elements[$elementIndex].Extent.StartOffset - $previous.Extent.EndOffset
            if ($length -gt 0) {
                [void] $builder.Append($Line.Substring($previous.Extent.EndOffset, $length))
            }
            else {
                [void] $builder.Append(',')
            }
        }

        [void] $builder.Append([string] $value)
    }

    return [pscustomobject] @{
        Text  = $builder.ToString()
        Count = $elements.Count
    }
}

function Measure-Items {
    param([object[]] $Items)

    if ($null -eq $Items -or $Items.Count -eq 0) { return 0 }

    $total = 0
    foreach ($item in $Items) {
        $total += $item.Width
    }
    return $total + ($script:Gap * ($Items.Count - 1))
}

function Format-Items {
    param([object[]] $Items)

    $lines = New-Object System.Collections.Generic.List[string]
    for ($rowIndex = 0; $rowIndex -lt $script:Height; $rowIndex++) {
        $builder = New-Object System.Text.StringBuilder

        for ($itemIndex = 0; $itemIndex -lt $Items.Count; $itemIndex++) {
            if ($itemIndex -gt 0) {
                [void] $builder.Append($script:GapText)
            }

            $glyph = $Items[$itemIndex]
            $line = ''
            if ($rowIndex -lt $glyph.Rows.Count) {
                $line = $glyph.Rows[$rowIndex]
            }

            [void] $builder.Append($line)
            if ($line.Length -lt $glyph.Width) {
                [void] $builder.Append(' ' * ($glyph.Width - $line.Length))
            }
        }

        [void] $lines.Add($builder.ToString().TrimEnd())
    }

    return ,$lines.ToArray()
}

function Show-Usage {
    Write-Output 'Usage: .\shiglet.ps1 [-Gap <n>] [-Width <n>] <text ...>'
    Write-Output ''
    Write-Output '  -Gap <n>      Spaces between character (default 1).'
    Write-Output '  -Width <n>    Wrap banners at this column; 0 disables wrapping (default 0).'
    Write-Output '  -List         List the characters that have glyph files.'
    Write-Output ''
    Write-Output 'Examples:'
    Write-Output '  .\shiglet.ps1 hello'
    Write-Output '  .\shiglet.ps1 Hello, World! 2026'
    Write-Output '  .\shiglet.ps1 "Wait... what?"'
    Write-Output '  .\shiglet.ps1 -Width 60 the quick brown fox'
}

$script:Glyphs = @{}
$script:WarnedCharacters = @{}
$script:Gap = $Gap
$script:GapText = ' ' * $Gap
$script:Height = 0

# Punctuation can't live in a single-character file name on every platform, so
# those glyphs use word names. Each name (without .txt) maps to the characters
# it stands for.
$script:GlyphNames = @{
    'comma'             = @(',')
    'dash'              = @("-")
    'exclamation-mark'  = @('!')
    'period'            = @('.')
    'question-mark'     = @('?')
    'underscore'        = @("_")
}

$fontDirectory = "$PSScriptRoot\chars"
if ([string]::IsNullOrEmpty($fontDirectory)) {
    $fontDirectory = (Get-Location).ProviderPath
}

# Cache the console encoding so the block glyphs are written as UTF-8, then
# put it back so the caller's session is left untouched.
$previousOutputEncoding = $null
try {
    $previousOutputEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
}
catch {
    $previousOutputEncoding = $null
}

try {
    $utf8 = New-Object System.Text.UTF8Encoding($false)

    foreach ($file in @(Get-ChildItem -LiteralPath $fontDirectory -Filter '*.txt' -File -ErrorAction SilentlyContinue)) {
        $baseName = $file.BaseName
        $characters = @()

        if ($baseName.Length -eq 1) {
            $characters = @($baseName)
        }
        elseif ($script:GlyphNames.ContainsKey($baseName.ToLowerInvariant())) {
            $characters = $script:GlyphNames[$baseName.ToLowerInvariant()]
        }

        if ($characters.Count -eq 0) { continue }

        $allLines = [System.IO.File]::ReadAllLines($file.FullName, $utf8)
        if ($allLines.Length -eq 0) { continue }

        # Keep the leading (possibly blank) row: it's the cap row of the font.
        # Only trailing blank lines left over from the file's final newline are dropped.
        $end = $allLines.Length - 1
        while ($end -ge 0 -and $allLines[$end].Length -eq 0) { $end-- }

        if ($end -lt 0) { continue }

        # Ignore trailing blank columns so glyph widths reflect their visible ink.
        $rows = @($allLines[0..$end] | ForEach-Object { $_.TrimEnd() })
        $glyphWidth = 0
        foreach ($row in $rows) {
            if ($row.Length -gt $glyphWidth) { $glyphWidth = $row.Length }
        }
        if ($glyphWidth -eq 0) { continue }

        $glyph = [pscustomobject] @{
            Rows   = $rows
            Width  = $glyphWidth
            Height = $rows.Count
        }

        # A named file may stand for more than one character. Don't overwrite an
        # existing glyph if two files collide.
        foreach ($character in $characters) {
            $key = ([string] $character).ToLowerInvariant()
            if ($script:Glyphs.ContainsKey($key)) { continue }
            $script:Glyphs[$key] = $glyph
        }
    }

    if ($script:Glyphs.Count -eq 0) {
        throw "No glyph files were found in '$fontDirectory'. Expected .txt files such as a.txt, 7.txt, or comma.txt."
    }

    $script:Height = Get-GlyphHeight -Glyphs @($script:Glyphs.Values)
    $script:SpaceGlyph = [pscustomobject] @{
        Rows   = @(' ' * 2)
        Width  = 2
        Height = 1
    }

    if ($List) {
        $supported = @($script:Glyphs.Keys | Sort-Object)
        Write-Output ("Supported characters ({0}): {1}" -f $supported.Count, ($supported -join ' '))
        return
    }

    if ($null -eq $Text -or $Text.Count -eq 0) {
        Show-Usage
        return
    }

    # A comma group in the final argument gets flattened into separate arguments,
    # so the comma is gone by the time the parameter is bound. Recover it from the
    # raw invocation line when the host provides it.
    $trailingComma = Get-TrailingCommaText -Line $MyInvocation.Line -CommandName $MyInvocation.MyCommand.Name
    if ($null -ne $trailingComma -and $Text.Count -ge $trailingComma.Count) {
        $headCount = $Text.Count - $trailingComma.Count

        # If the tail is still a nested array, the host kept the comma group
        # intact and Join-TextArguments already handles it.
        if ($Text[$headCount] -isnot [System.Array]) {
            if ($headCount -gt 0) {
                $Text = @($Text[0..($headCount - 1)]) + @($trailingComma.Text)
            }
            else {
                $Text = @($trailingComma.Text)
            }
        }
    }

    $inputText = Join-TextArguments -Arguments $Text
    $words = @($inputText -split '\s+' | Where-Object { $_.Length -gt 0 })
    if ($words.Count -eq 0) {
        Show-Usage
        return
    }

    $blocks = New-Object System.Collections.Generic.List[object]
    $current = New-Object System.Collections.Generic.List[object]
    $currentWidth = 0

    foreach ($word in $words) {
        $wordItems = Get-WordItems -Word $word
        if ($wordItems.Count -eq 0) { continue }

        $wordWidth = Measure-Items -Items $wordItems

        if ($current.Count -gt 0) {
            $candidateWidth = $currentWidth + $script:Gap + $script:SpaceGlyph.Width + $script:Gap + $wordWidth

            if ($script:Width -gt 0 -and $candidateWidth -gt $script:Width) {
                [void] $blocks.Add($current.ToArray())
                $current = New-Object System.Collections.Generic.List[object]
                $currentWidth = 0
            }
            else {
                [void] $current.Add($script:SpaceGlyph)
                [void] $current.AddRange($wordItems)
                $currentWidth = $candidateWidth
                continue
            }
        }

        [void] $current.AddRange($wordItems)
        $currentWidth = $wordWidth
    }

    if ($current.Count -gt 0) {
        [void] $blocks.Add($current.ToArray())
    }

    for ($blockIndex = 0; $blockIndex -lt $blocks.Count; $blockIndex++) {
        if ($blockIndex -gt 0) {
            Write-Output ''
        }

        $renderedLines = Format-Items -Items $blocks[$blockIndex]
        foreach ($line in $renderedLines) {
            Write-Output $line
        }
    }
}
finally {
    if ($null -ne $previousOutputEncoding) {
        try {
            [Console]::OutputEncoding = $previousOutputEncoding
        }
        catch {
            # Nothing useful to do if the host refuses to restore it.
        }
    }
}
