# Deploy para gps.avila.inc (Windows PowerShell)

param(
    [string]$ServerHost = "gps.avila.inc",
    [string]$ServerUser = "root",
    [switch]$SetupSSL
)

Write-Host "🚀 Deploy GPS Tracker para gps.avila.inc" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Build
Write-Host "📦 Compilando projeto..." -ForegroundColor Yellow
cargo build --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro na compilação!" -ForegroundColor Red
    exit 1
}

# 2. Criar pacote
Write-Host "📁 Criando pacote de deploy..." -ForegroundColor Yellow
$deployDir = "deploy-package"
if (Test-Path $deployDir) {
    Remove-Item $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

Copy-Item "target\release\device-location-tracker.exe" -Destination "$deployDir\device-location-tracker"
Copy-Item "static" -Destination "$deployDir\static" -Recurse
Copy-Item "systemd-service.conf" -Destination "$deployDir\"
Copy-Item "nginx.conf" -Destination "$deployDir\"

# 3. Upload via SCP (requer WSL ou Git Bash)
Write-Host "📤 Enviando para servidor..." -ForegroundColor Yellow
Write-Host "   Host: $ServerHost" -ForegroundColor Gray
Write-Host "   User: $ServerUser" -ForegroundColor Gray
Write-Host ""

$deployPath = "/var/www/gps.avila.inc"

# Criar estrutura no servidor
ssh "${ServerUser}@${ServerHost}" "mkdir -p ${deployPath}/{current,backups}"

# Backup
Write-Host "💾 Fazendo backup..." -ForegroundColor Yellow
ssh "${ServerUser}@${ServerHost}" @"
    if [ -d ${deployPath}/current ]; then
        BACKUP_NAME=backup-`$(date +%Y%m%d-%H%M%S)
        mv ${deployPath}/current ${deployPath}/backups/`$BACKUP_NAME
        echo 'Backup criado: '`$BACKUP_NAME
    fi
"@

# Upload
Write-Host "⬆️  Enviando arquivos..." -ForegroundColor Yellow
scp -r "$deployDir\*" "${ServerUser}@${ServerHost}:${deployPath}/current/"

# 4. Configurar servidor
Write-Host "⚙️  Configurando servidor..." -ForegroundColor Yellow
ssh "${ServerUser}@${ServerHost}" @"
    cd ${deployPath}/current
    
    # Permissões
    chmod +x device-location-tracker
    chown -R www-data:www-data ${deployPath}/current
    
    # Logs
    mkdir -p /var/log/gps-tracker
    chown www-data:www-data /var/log/gps-tracker
    
    # Systemd
    cp systemd-service.conf /etc/systemd/system/gps-tracker.service
    systemctl daemon-reload
    
    # Nginx
    cp nginx.conf /etc/nginx/sites-available/gps.avila.inc
    ln -sf /etc/nginx/sites-available/gps.avila.inc /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    
    # Iniciar
    systemctl enable gps-tracker
    systemctl restart gps-tracker
    
    echo ''
    echo '✅ Deploy concluído!'
    systemctl status gps-tracker
"@

# 5. SSL (opcional)
if ($SetupSSL) {
    Write-Host ""
    Write-Host "🔒 Configurando SSL..." -ForegroundColor Yellow
    ssh "${ServerUser}@${ServerHost}" @"
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
        certbot --nginx -d gps.avila.inc --non-interactive --agree-tos -m admin@avila.inc
        systemctl reload nginx
"@
    Write-Host "✅ SSL configurado!" -ForegroundColor Green
}

# Resumo
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Deploy Completo!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Acesse: https://gps.avila.inc" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Comandos úteis:" -ForegroundColor Yellow
Write-Host "   Logs:    ssh ${ServerUser}@${ServerHost} 'journalctl -u gps-tracker -f'" -ForegroundColor Gray
Write-Host "   Status:  ssh ${ServerUser}@${ServerHost} 'systemctl status gps-tracker'" -ForegroundColor Gray
Write-Host "   Restart: ssh ${ServerUser}@${ServerHost} 'systemctl restart gps-tracker'" -ForegroundColor Gray
Write-Host "   Stop:    ssh ${ServerUser}@${ServerHost} 'systemctl stop gps-tracker'" -ForegroundColor Gray
Write-Host ""
