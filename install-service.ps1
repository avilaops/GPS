# Instalar Device Location Tracker como Serviço Windows
# Requer privilégios de administrador

#Requires -RunAsAdministrator

param(
    [string]$ServiceName = "DeviceLocationTracker",
    [string]$Port = "8080"
)

Write-Host "🔧 Instalando Device Location Tracker como Serviço Windows" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se executável existe
$exePath = (Get-Item ".\target\release\device-location-tracker.exe").FullName

if (-not (Test-Path $exePath)) {
    Write-Host "❌ Executável não encontrado!" -ForegroundColor Red
    Write-Host "   Execute primeiro: cargo build --release" -ForegroundColor Yellow
    exit 1
}

# Verificar se serviço já existe
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($existingService) {
    Write-Host "⚠️  Serviço já existe. Removendo..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force
    sc.exe delete $ServiceName
    Start-Sleep -Seconds 2
}

# Criar wrapper script para o serviço
$wrapperPath = ".\target\release\service-wrapper.ps1"
$wrapperContent = @"
# Wrapper para executar como serviço
`$env:PORT = "$Port"
Set-Location "$PSScriptRoot"
& "$exePath"
"@

Set-Content -Path $wrapperPath -Value $wrapperContent

# Tentar usar NSSM se disponível
if (Get-Command nssm -ErrorAction SilentlyContinue) {
    Write-Host "📦 Usando NSSM para criar serviço..." -ForegroundColor Yellow

    nssm install $ServiceName $exePath
    nssm set $ServiceName AppDirectory (Split-Path $exePath)
    nssm set $ServiceName AppEnvironmentExtra PORT=$Port
    nssm set $ServiceName DisplayName "Device Location Tracker"
    nssm set $ServiceName Description "Sistema de rastreamento GPS em tempo real"
    nssm set $ServiceName Start SERVICE_AUTO_START
    nssm set $ServiceName AppStdout ".\logs\service-output.log"
    nssm set $ServiceName AppStderr ".\logs\service-error.log"

    Write-Host "✅ Serviço instalado com NSSM!" -ForegroundColor Green
} else {
    Write-Host "⚠️  NSSM não encontrado. Usando sc.exe..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Para instalar NSSM:" -ForegroundColor Gray
    Write-Host "   - Com Chocolatey: choco install nssm" -ForegroundColor Gray
    Write-Host "   - Manual: https://nssm.cc/download" -ForegroundColor Gray
    Write-Host ""

    # Criar usando sc.exe (limitado)
    $binPath = "$exePath"
    sc.exe create $ServiceName binPath= $binPath start= auto DisplayName= "Device Location Tracker"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Serviço criado com sc.exe!" -ForegroundColor Green
        Write-Host "⚠️  Nota: Configuração avançada requer NSSM" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Erro ao criar serviço!" -ForegroundColor Red
        exit 1
    }
}

# Configurar firewall
Write-Host ""
Write-Host "🔥 Configurando Firewall..." -ForegroundColor Yellow

$firewallRule = Get-NetFirewallRule -DisplayName "Device Location Tracker" -ErrorAction SilentlyContinue

if ($firewallRule) {
    Remove-NetFirewallRule -DisplayName "Device Location Tracker"
}

New-NetFirewallRule `
    -DisplayName "Device Location Tracker" `
    -Direction Inbound `
    -LocalPort $Port `
    -Protocol TCP `
    -Action Allow `
    -Description "Permite acesso ao Device Location Tracker na porta $Port" | Out-Null

Write-Host "✅ Regra de firewall criada!" -ForegroundColor Green

# Criar diretório de logs
New-Item -ItemType Directory -Path ".\logs" -Force | Out-Null

# Resumo
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "✅ Instalação concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Informações do Serviço:" -ForegroundColor Cyan
Write-Host "   - Nome: $ServiceName" -ForegroundColor Gray
Write-Host "   - Porta: $Port" -ForegroundColor Gray
Write-Host "   - Executável: $exePath" -ForegroundColor Gray
Write-Host "   - Logs: .\logs\" -ForegroundColor Gray
Write-Host ""
Write-Host "🎮 Comandos:" -ForegroundColor Yellow
Write-Host "   Iniciar:  Start-Service $ServiceName" -ForegroundColor White
Write-Host "   Parar:    Stop-Service $ServiceName" -ForegroundColor White
Write-Host "   Status:   Get-Service $ServiceName" -ForegroundColor White
Write-Host "   Logs:     Get-Content .\logs\service-output.log -Wait" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Acesso:" -ForegroundColor Cyan
Write-Host "   Local:    http://localhost:$Port" -ForegroundColor White
Write-Host "   Rede:     http://$(hostname):$Port" -ForegroundColor White
Write-Host ""
Write-Host "Para remover o serviço:" -ForegroundColor Gray
Write-Host "   .\uninstall-service.ps1" -ForegroundColor White

# Perguntar se quer iniciar agora
Write-Host ""
$start = Read-Host "Deseja iniciar o serviço agora? (S/N)"
if ($start -eq "S" -or $start -eq "s") {
    Start-Service $ServiceName
    Start-Sleep -Seconds 2
    $status = Get-Service $ServiceName
    if ($status.Status -eq "Running") {
        Write-Host "✅ Serviço iniciado com sucesso!" -ForegroundColor Green
        Start-Process "http://localhost:$Port"
    } else {
        Write-Host "❌ Erro ao iniciar serviço!" -ForegroundColor Red
        Write-Host "   Verifique os logs em: .\logs\" -ForegroundColor Yellow
    }
}
