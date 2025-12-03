# Script de Deploy - Device Location Tracker
# Prepara o sistema para produção

param(
    [string]$Mode = "local",  # local, server, docker
    [string]$Port = "8080"
)

Write-Host "🚀 Device Location Tracker - Deploy Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Compilar em modo release
Write-Host "📦 Compilando em modo release..." -ForegroundColor Yellow
Set-Location $PSScriptRoot
cargo build --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Compilação concluída!" -ForegroundColor Green
Write-Host ""

# 2. Criar diretório de deploy
$deployDir = ".\deploy"
if (Test-Path $deployDir) {
    Remove-Item $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

# 3. Copiar executável
Write-Host "📂 Preparando arquivos de deploy..." -ForegroundColor Yellow
Copy-Item ".\target\release\device-location-tracker.exe" -Destination "$deployDir\"

# 4. Copiar arquivos estáticos
Copy-Item ".\static" -Destination "$deployDir\static" -Recurse

# 5. Criar arquivo de configuração
$config = @"
# Device Location Tracker - Configuration
PORT=$Port
LOG_LEVEL=info
HISTORY_MAX_ITEMS=1000
AUTO_SAVE=true
CORS_ENABLED=true
"@

Set-Content -Path "$deployDir\config.env" -Value $config

# 6. Criar script de inicialização
$startScript = @"
@echo off
echo 🌍 Iniciando Device Location Tracker...
echo.

REM Carregar configurações
set PORT=$Port

REM Iniciar servidor
device-location-tracker.exe

pause
"@

Set-Content -Path "$deployDir\start.bat" -Value $startScript

# 7. Criar README do deploy
$deployReadme = @"
# Device Location Tracker - Deploy Package

## 🚀 Como Usar

### Windows
1. Execute: \`start.bat\`
2. Acesse: http://localhost:$Port

### Manual
\`\`\`
device-location-tracker.exe
\`\`\`

## 📁 Estrutura

- \`device-location-tracker.exe\` - Executável principal
- \`static/\` - Interface web
- \`config.env\` - Configurações
- \`start.bat\` - Script de inicialização
- \`location_history.json\` - Histórico (criado automaticamente)

## ⚙️ Configuração

Edite \`config.env\` para alterar:
- PORT: Porta do servidor (padrão: $Port)
- HISTORY_MAX_ITEMS: Máximo de localizações no histórico

## 🔒 Firewall

Para acesso externo, libere a porta $Port no firewall:

\`\`\`powershell
New-NetFirewallRule -DisplayName "Device Tracker" -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow
\`\`\`

## 📱 Acesso Remoto

1. Descubra seu IP:
   \`\`\`
   ipconfig
   \`\`\`

2. Acesse de outro dispositivo:
   \`\`\`
   http://SEU_IP:$Port
   \`\`\`

## 🌐 Deploy em Servidor

### Windows Server
1. Copie a pasta \`deploy\` para o servidor
2. Execute \`start.bat\`
3. Configure como serviço (opcional)

### Linux (via Wine)
\`\`\`bash
wine device-location-tracker.exe
\`\`\`

### Docker (se disponível)
\`\`\`bash
docker build -t location-tracker .
docker run -p $Port:$Port location-tracker
\`\`\`

## 🔧 Solução de Problemas

**Porta em uso:**
\`\`\`
netstat -ano | findstr :$Port
taskkill /PID <PID> /F
\`\`\`

**Permissões negadas:**
Execute como administrador

**GPS não funciona:**
- Permita localização no navegador
- Use HTTPS em produção (GPS requer)
"@

Set-Content -Path "$deployDir\README.md" -Value $deployReadme

# 8. Modo específico de deploy
switch ($Mode) {
    "local" {
        Write-Host "📍 Modo: Local Development" -ForegroundColor Cyan
        Write-Host "   - Servidor na porta $Port" -ForegroundColor Gray
        Write-Host "   - Acesso: http://localhost:$Port" -ForegroundColor Gray
    }

    "server" {
        Write-Host "🖥️  Modo: Server Production" -ForegroundColor Cyan
        Write-Host "   - Configurando para servidor..." -ForegroundColor Gray

        # Criar serviço Windows
        $servicePath = "$deployDir\install-service.ps1"
        $serviceScript = @"
# Instalar como serviço Windows
`$serviceName = "DeviceLocationTracker"
`$exePath = "`$PSScriptRoot\device-location-tracker.exe"

Write-Host "📦 Instalando serviço Windows..." -ForegroundColor Yellow

# Criar serviço usando NSSM (se disponível) ou sc.exe
if (Get-Command nssm -ErrorAction SilentlyContinue) {
    nssm install `$serviceName `$exePath
    nssm set `$serviceName AppDirectory `$PSScriptRoot
    nssm set `$serviceName Start SERVICE_AUTO_START
    Write-Host "✅ Serviço instalado com NSSM" -ForegroundColor Green
} else {
    Write-Host "⚠️  NSSM não encontrado. Instale: choco install nssm" -ForegroundColor Yellow
    Write-Host "   Ou use: sc.exe create `$serviceName binPath= `$exePath start= auto" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Para iniciar o serviço:" -ForegroundColor Cyan
Write-Host "  Start-Service `$serviceName" -ForegroundColor White
"@
        Set-Content -Path $servicePath -Value $serviceScript

        Write-Host "   - Script de serviço criado: install-service.ps1" -ForegroundColor Gray
    }

    "docker" {
        Write-Host "🐳 Modo: Docker Container" -ForegroundColor Cyan

        # Criar Dockerfile
        $dockerfile = @"
FROM rust:1.75 as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/target/release/device-location-tracker .
COPY --from=builder /app/static ./static
EXPOSE $Port
CMD ["./device-location-tracker"]
"@
        Set-Content -Path "$deployDir\Dockerfile" -Value $dockerfile

        # Criar docker-compose.yml
        $dockerCompose = @"
version: '3.8'

services:
  location-tracker:
    build: .
    ports:
      - "$Port:$Port"
    volumes:
      - ./location_history.json:/app/location_history.json
    restart: unless-stopped
    environment:
      - PORT=$Port
      - RUST_LOG=info
"@
        Set-Content -Path "$deployDir\docker-compose.yml" -Value $dockerCompose

        Write-Host "   - Dockerfile criado" -ForegroundColor Gray
        Write-Host "   - docker-compose.yml criado" -ForegroundColor Gray
        Write-Host "   - Execute: docker-compose up -d" -ForegroundColor Gray
    }
}

# 9. Resumo
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Deploy preparado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📂 Localização: $deployDir" -ForegroundColor Cyan
Write-Host "📊 Tamanho: " -NoNewline -ForegroundColor Cyan
$size = (Get-ChildItem $deployDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "$([math]::Round($size, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Para iniciar:" -ForegroundColor Yellow
Write-Host "   cd $deployDir" -ForegroundColor White
Write-Host "   .\start.bat" -ForegroundColor White
Write-Host ""
Write-Host "📖 Leia o README.md para mais informações" -ForegroundColor Gray
