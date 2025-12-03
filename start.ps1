# Script para iniciar o Device Location Tracker
Write-Host "🌍 Iniciando Device Location Tracker..." -ForegroundColor Cyan
Write-Host ""

# Verificar se o Rust está instalado
if (!(Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Rust não está instalado!" -ForegroundColor Red
    Write-Host "📥 Instale o Rust em: https://rustup.rs/" -ForegroundColor Yellow
    exit 1
}

# Navegar para o diretório
Set-Location "D:\device-location-tracker"

Write-Host "📦 Compilando o projeto..." -ForegroundColor Yellow
cargo build --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilação concluída com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Iniciando o servidor..." -ForegroundColor Cyan
    Write-Host "📍 Acesse: http://localhost:8080" -ForegroundColor Green
    Write-Host "⚠️  Pressione Ctrl+C para parar o servidor" -ForegroundColor Yellow
    Write-Host ""

    # Aguardar um pouco e abrir o navegador
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:8080"

    # Iniciar o servidor
    cargo run --release
} else {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}
