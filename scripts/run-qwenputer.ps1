$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo "experimental\riscv"
$python = Join-Path $project ".venv\Scripts\python.exe"
$model = "D:\SS\Models\qwenputer-rv"
$firmware = Join-Path $project "tests\data\rv\calc-bridge.elf"

function Stop-Launcher([string]$message) {
    Write-Host "`n$message" -ForegroundColor Yellow
    Read-Host "Pressione Enter para fechar"
    exit 1
}

if (-not (Test-Path $python)) {
    Stop-Launcher "Ambiente nao instalado. Execute uv sync --extra hf na pasta experimental\riscv."
}
if (-not (Test-Path (Join-Path $model "config.json"))) {
    Stop-Launcher "Checkpoint incompleto ou ausente: $model"
}
if (-not (Test-Path $firmware)) {
    Stop-Launcher "Firmware nao encontrado: $firmware"
}

$ramGb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$cudaAvailable = (& $python -c "import torch; print(torch.cuda.is_available())" 2>$null | Select-Object -Last 1).Trim()
if ($cudaAvailable -eq "True") {
    $vramGb = [math]::Round([double](& $python -c "import torch; print(torch.cuda.get_device_properties(0).total_memory / 1024**3)" 2>$null | Select-Object -Last 1))
    if ($vramGb -lt 24) {
        Stop-Launcher "A GPU tem ${vramGb} GB de VRAM. Este checkpoint BF16 precisa de uma GPU de cerca de 24 GB; ou use um PC com pelo menos 32 GB de RAM para execução pela CPU."
    }
} elseif ($ramGb -lt 32) {
    Stop-Launcher "Sem CUDA compativel e com ${ramGb} GB de RAM. O checkpoint ocupa 18.8 GB em BF16; para CPU, use um PC com pelo menos 32 GB de RAM ou uma GPU compativel com cerca de 24 GB de VRAM."
}

Set-Location $project
$question = Read-Host "O que voce quer perguntar ao Qwenputer?"
if ([string]::IsNullOrWhiteSpace($question)) {
    $question = "Use calc: what is 123456789 * 987654321?"
}

& $python -m chipformer.rv.chat $model --firmware $firmware --ask $question
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nO Qwenputer terminou com erro (codigo $LASTEXITCODE)." -ForegroundColor Red
}
Read-Host "`nPressione Enter para fechar"
