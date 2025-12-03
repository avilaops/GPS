# Script para rodar offline - Device Location Tracker
# Inicia o servidor localmente sem precisar de internet

param(
    [switch]$Background,
    [string]$Port = "8080"
)

Write-Host "🌍 Device Location Tracker - Modo Offline" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se já compilado
$exePath = ".\target\release\device-location-tracker.exe"

if (-not (Test-Path $exePath)) {
    Write-Host "⚠️  Executável não encontrado. Compilando..." -ForegroundColor Yellow
    cargo build --release

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro na compilação!" -ForegroundColor Red
        exit 1
    }
}

# Configurar variável de ambiente para porta
$env:PORT = $Port

Write-Host "✅ Configuração:" -ForegroundColor Green
Write-Host "   - Porta: $Port" -ForegroundColor Gray
Write-Host "   - Modo: Offline (sem internet necessária)" -ForegroundColor Gray
Write-Host "   - GPS: Funciona com GPS do dispositivo" -ForegroundColor Gray
Write-Host ""

# Abrir navegador após 2 segundos
Start-Job -ScriptBlock {
    param($port)
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:$port"
} -ArgumentList $Port | Out-Null

Write-Host "🚀 Iniciando servidor..." -ForegroundColor Cyan
Write-Host "📍 Acesse: http://localhost:$Port" -ForegroundColor Green
Write-Host "📱 Permita o acesso à localização no navegador" -ForegroundColor Yellow
Write-Host ""
Write-Host "⏸️  Pressione Ctrl+C para parar" -ForegroundColor Gray
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($Background) {
    # Rodar em background
    Start-Process -FilePath $exePath -WindowStyle Hidden
    Write-Host "✅ Servidor iniciado em background!" -ForegroundColor Green
    Write-Host "   Use 'Stop-Process -Name device-location-tracker' para parar" -ForegroundColor Gray
} else {
    # Rodar em foreground
    & $exePath
}
