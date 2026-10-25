param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$engine = Join-Path $env:WINDIR 'System32\cscript.exe'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('frecuencia-syntax-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    foreach ($page in Get-ChildItem -LiteralPath $ProjectRoot -Filter '*.asp') {
        $source = [System.IO.File]::ReadAllText($page.FullName)
        $source = [regex]::Replace($source, '<!--#include file="([^"]+)"-->', {
            param($match)
            [System.IO.File]::ReadAllText((Join-Path $ProjectRoot $match.Groups[1].Value))
        })
        $chunks = foreach ($match in [regex]::Matches($source, '<%([\s\S]*?)%>')) {
            $code = $match.Groups[1].Value
            if ($code.StartsWith('@')) { continue }
            if ($code.StartsWith('=')) { $code = 'Response.Write ' + $code.Substring(1) }
            [regex]::Replace($code, '(?im)^\s*Option Explicit\s*$', '')
        }
        # El motor analiza todo el script; Quit impide ejecutar lógica o tocar la BD.
        $script = "Option Explicit`r`nDim Response, Request, Server, Session`r`nWScript.Quit 0`r`n" + ($chunks -join "`r`n")
        $target = Join-Path $scratch ($page.BaseName + '.vbs')
        # WSH necesita UTF-16 para interpretar los literales en español.
        [System.IO.File]::WriteAllText($target, $script, [System.Text.Encoding]::Unicode)
        $output = & $engine //Nologo $target 2>&1
        if ($LASTEXITCODE -ne 0) { throw "$($page.Name): $output" }
        Write-Output "PASS VBScript: $($page.Name)"
    }
    & node --check (Join-Path $ProjectRoot 'player.js')
    if ($LASTEXITCODE -ne 0) { throw 'player.js no supera el análisis sintáctico.' }
    Write-Output 'PASS JavaScript: player.js'
    $pages = (Get-ChildItem -LiteralPath $ProjectRoot -Filter '*.asp' | Get-Content -Raw) -join "`n"
    if ($pages -match '<table\b|<asp:|CodeBehind|System\.Data\.') { throw 'Tecnología o marcado prohibido.' }
    Write-Output 'PASS: sin tablas HTML ni componentes ASP.NET en las páginas.'
} finally {
    # Solo archivos temporales creados y enumerados por esta ejecución.
    Get-ChildItem -LiteralPath $scratch -File | Remove-Item
    Remove-Item -LiteralPath $scratch
}
