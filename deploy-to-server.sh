#!/bin/bash
# Script de Deploy Manual para gps.avila.inc

set -e

echo "🚀 Deploy GPS Tracker para gps.avila.inc"
echo "========================================"
echo ""

# Configurações
SERVER_HOST="${SERVER_HOST:-gps.avila.inc}"
SERVER_USER="${SERVER_USER:-root}"
DEPLOY_PATH="/var/www/gps.avila.inc"

# 1. Build local
echo "📦 Compilando projeto..."
cargo build --release

# 2. Criar pacote
echo "📁 Criando pacote de deploy..."
mkdir -p deploy-package
cp target/release/device-location-tracker deploy-package/
cp -r static deploy-package/
cp systemd-service.conf deploy-package/
cp nginx.conf deploy-package/

# 3. Enviar para servidor
echo "📤 Enviando para servidor..."
ssh ${SERVER_USER}@${SERVER_HOST} "mkdir -p ${DEPLOY_PATH}/{current,backups}"

# Backup atual
echo "💾 Fazendo backup da versão atual..."
ssh ${SERVER_USER}@${SERVER_HOST} "
    if [ -d ${DEPLOY_PATH}/current ]; then
        BACKUP_NAME=backup-\$(date +%Y%m%d-%H%M%S)
        mv ${DEPLOY_PATH}/current ${DEPLOY_PATH}/backups/\${BACKUP_NAME}
        echo '✅ Backup criado: \${BACKUP_NAME}'
    fi
"

# Upload
echo "⬆️  Fazendo upload..."
scp -r deploy-package/* ${SERVER_USER}@${SERVER_HOST}:${DEPLOY_PATH}/current/

# 4. Configurar servidor
echo "⚙️  Configurando servidor..."
ssh ${SERVER_USER}@${SERVER_HOST} "
    # Permissões
    chmod +x ${DEPLOY_PATH}/current/device-location-tracker
    chown -R www-data:www-data ${DEPLOY_PATH}/current

    # Criar diretórios de log
    mkdir -p /var/log/gps-tracker
    chown www-data:www-data /var/log/gps-tracker

    # Configurar systemd service
    cp ${DEPLOY_PATH}/current/systemd-service.conf /etc/systemd/system/gps-tracker.service
    systemctl daemon-reload

    # Configurar nginx
    cp ${DEPLOY_PATH}/current/nginx.conf /etc/nginx/sites-available/gps.avila.inc
    ln -sf /etc/nginx/sites-available/gps.avila.inc /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx

    # Iniciar serviço
    systemctl enable gps-tracker
    systemctl restart gps-tracker

    echo ''
    echo '✅ Deploy concluído!'
    echo ''
    systemctl status gps-tracker
"

# 5. Configurar SSL (se necessário)
echo ""
read -p "🔒 Configurar SSL com Let's Encrypt? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "📜 Configurando SSL..."
    ssh ${SERVER_USER}@${SERVER_HOST} "
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
        certbot --nginx -d gps.avila.inc --non-interactive --agree-tos -m admin@avila.inc
        systemctl reload nginx
    "
    echo "✅ SSL configurado!"
fi

echo ""
echo "========================================"
echo "✅ Deploy Completo!"
echo ""
echo "🌐 Acesse: https://gps.avila.inc"
echo "📊 Logs: ssh ${SERVER_USER}@${SERVER_HOST} 'journalctl -u gps-tracker -f'"
echo "🔄 Restart: ssh ${SERVER_USER}@${SERVER_HOST} 'systemctl restart gps-tracker'"
echo ""
