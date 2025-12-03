# Desinstalar Device Location Tracker Service
# Requer privilégios de administrador

#Requires -RunAsAdministrator

param(
    [string]$ServiceName = "DeviceLocationTracker"
)

Write-Host "🗑️  Desinstalando Device Location Tracker Service" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow
Write-Host ""

# Verificar se serviço existe
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "⚠️  Serviço '$ServiceName' não encontrado!" -ForegroundColor Yellow
    exit 0
}

# Parar serviço
Write-Host "⏹️  Parando serviço..." -ForegroundColor Yellow
Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue

# Aguardar parar
Start-Sleep -Seconds 2

# Remover com NSSM se disponível
if (Get-Command nssm -ErrorAction SilentlyContinue) {
    Write-Host "📦 Removendo com NSSM..." -ForegroundColor Yellow
    nssm remove $ServiceName confirm
} else {
    Write-Host "📦 Removendo com sc.exe..." -ForegroundColor Yellow
    sc.exe delete $ServiceName
}

# Remover regra de firewall
Write-Host "🔥 Removendo regra de firewall..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "Device Location Tracker" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ Serviço desinstalado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Arquivos mantidos:" -ForegroundColor Gray
Write-Host "   - Executável: .\target\release\" -ForegroundColor Gray
Write-Host "   - Histórico: .\location_history.json" -ForegroundColor Gray
Write-Host "   - Logs: .\logs\" -ForegroundColor Gray
