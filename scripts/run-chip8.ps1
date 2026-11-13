$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$python = Join-Path $repo ".venv\Scripts\python.exe"
$rom = Join-Path $repo "games\roms\pong.ch8"

if (-not (Test-Path $python)) {
    Write-Host "Python do ambiente .venv nao encontrado: $python" -ForegroundColor Red
    Read-Host "Pressione Enter para fechar"
    exit 1
}
if (-not (Test-Path $rom)) {
    Write-Host "ROM CHIP-8 nao encontrada: $rom" -ForegroundColor Red
    Read-Host "Pressione Enter para fechar"
    exit 1
}

Set-Location $repo
Write-Host "Abrindo Pong CHIP-8. Teclas: 1/2/3/4, Q/W/E/R, A/S/D/F, Z/X/C/V. Esc fecha."
& $python -m chipformer.ref.play $rom --ipf 10 --scale 12 --check
if ($LASTEXITCODE -ne 0) {
    Write-Host "O emulador terminou com erro (codigo $LASTEXITCODE)." -ForegroundColor Red
}
Read-Host "`nPressione Enter para fechar"
