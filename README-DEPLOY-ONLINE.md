# 🌐 Deploy Online - gps.avila.inc

Guia completo para colocar o GPS Tracker online em **gps.avila.inc**

---

## 📋 Pré-requisitos

### No Servidor

- Ubuntu/Debian Linux
- Acesso SSH (root ou sudo)
- Nginx instalado
- Domínio apontando para o servidor

### No PC Local

- Git
- SSH configurado
- Cargo/Rust (para build)

---

## 🚀 Deploy Automático (GitHub Actions)

### 1. Configurar Secrets no GitHub

Vá em: `github.com/avilaops/GPS` → Settings → Secrets and variables → Actions

Adicione:
- `SERVER_HOST`: `gps.avila.inc` ou IP do servidor
- `SERVER_USER`: `root` ou seu usuário SSH
- `SSH_PRIVATE_KEY`: Sua chave SSH privada

```bash
# Gerar chave SSH (se não tiver)
ssh-keygen -t ed25519 -C "deploy@gps.avila.inc"

# Copiar para servidor
ssh-copy-id root@gps.avila.inc

# Copiar conteúdo da chave privada
cat ~/.ssh/id_ed25519
```

### 2. Push para GitHub

```bash
git add .
git commit -m "Deploy inicial GPS Tracker"
git push origin main
```

O GitHub Actions irá:
- ✅ Compilar o projeto
- ✅ Fazer deploy no servidor
- ✅ Reiniciar o serviço
- ✅ Deixar online automaticamente

---

## 🖥️ Deploy Manual

### Opção 1: Script PowerShell (Windows)

```powershell
# Deploy simples
.\deploy-to-server.ps1

# Com SSL
.\deploy-to-server.ps1 -SetupSSL

# Servidor customizado
.\deploy-to-server.ps1 -ServerHost "seu.servidor.com" -ServerUser "usuario"
```

### Opção 2: Script Bash (Linux/Mac/WSL)

```bash
# Tornar executável
chmod +x deploy-to-server.sh

# Deploy
./deploy-to-server.sh

# Com variáveis customizadas
SERVER_HOST="seu.servidor.com" SERVER_USER="usuario" ./deploy-to-server.sh
```

### Opção 3: Manual Completo

```bash
# 1. Build local
cargo build --release

# 2. Conectar no servidor
ssh root@gps.avila.inc

# 3. No servidor:
# Criar estrutura
mkdir -p /var/www/gps.avila.inc/current
cd /var/www/gps.avila.inc/current

# 4. Do seu PC, enviar arquivos:
scp target/release/device-location-tracker root@gps.avila.inc:/var/www/gps.avila.inc/current/
scp -r static root@gps.avila.inc:/var/www/gps.avila.inc/current/

# 5. Voltar ao servidor e configurar:
chmod +x /var/www/gps.avila.inc/current/device-location-tracker

# Criar serviço
nano /etc/systemd/system/gps-tracker.service
# (Cole o conteúdo de systemd-service.conf)

# Configurar Nginx
nano /etc/nginx/sites-available/gps.avila.inc
# (Cole o conteúdo de nginx.conf)

ln -s /etc/nginx/sites-available/gps.avila.inc /etc/nginx/sites-enabled/

# Testar e reiniciar
nginx -t
systemctl reload nginx

# Iniciar serviço
systemctl daemon-reload
systemctl enable gps-tracker
systemctl start gps-tracker
```

---

## 🔒 Configurar SSL (HTTPS)

### Automático com Certbot

```bash
# No servidor
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Obter certificado
certbot --nginx -d gps.avila.inc

# Renovação automática já configurada!
```

### Verificar Renovação

```bash
# Testar renovação
certbot renew --dry-run

# Ver certificados
certbot certificates
```

---

## 🌐 Configurar DNS

### No seu provedor DNS (Cloudflare, Route53, etc):

**Tipo A:**
```
gps.avila.inc → SEU_IP_SERVIDOR
```

ou

**Tipo CNAME:**
```
gps → avila.inc
```

### Verificar DNS:

```bash
# Windows
nslookup gps.avila.inc

# Linux/Mac
dig gps.avila.inc
```

---

## 📊 Monitoramento

### Ver Logs em Tempo Real

```bash
# Logs do serviço
journalctl -u gps-tracker -f

# Logs do Nginx
tail -f /var/log/nginx/gps.avila.inc.access.log
tail -f /var/log/nginx/gps.avila.inc.error.log
```

### Status do Serviço

```bash
# Status
systemctl status gps-tracker

# Restart
systemctl restart gps-tracker

# Stop
systemctl stop gps-tracker

# Start
systemctl start gps-tracker
```

### Verificar Porta

```bash
# Ver se está rodando
ss -tulpn | grep 8080

# Testar localmente
curl http://localhost:8080
```

---

## 🔧 Troubleshooting

### Serviço Não Inicia

```bash
# Ver erro detalhado
journalctl -u gps-tracker -n 50 --no-pager

# Verificar permissões
ls -la /var/www/gps.avila.inc/current/

# Executar manualmente
/var/www/gps.avila.inc/current/device-location-tracker
```

### Nginx Erro 502

```bash
# Verificar se backend está rodando
curl http://localhost:8080

# Ver logs do Nginx
tail -f /var/log/nginx/error.log

# Reiniciar ambos
systemctl restart gps-tracker
systemctl restart nginx
```

### SSL Não Funciona

```bash
# Verificar certificado
certbot certificates

# Renovar manualmente
certbot renew

# Ver configuração
nginx -T | grep ssl
```

### Porta 8080 em Uso

```bash
# Ver quem está usando
lsof -i :8080

# Matar processo
kill -9 PID
```

---

## 🔄 Atualizar Deploy

### Método 1: Git Push

```bash
git add .
git commit -m "Atualização"
git push
# GitHub Actions faz deploy automaticamente
```

### Método 2: Script

```powershell
.\deploy-to-server.ps1
```

### Método 3: Manual

```bash
# Build local
cargo build --release

# Upload
scp target/release/device-location-tracker root@gps.avila.inc:/var/www/gps.avila.inc/current/

# No servidor
ssh root@gps.avila.inc
systemctl restart gps-tracker
```

---

## 📈 Performance

### Otimizações Nginx

```nginx
# Em nginx.conf, adicionar:
gzip on;
gzip_types text/plain text/css application/json application/javascript;
gzip_min_length 1000;

# Cache de assets estáticos
location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Limitar Recursos

```bash
# Editar /etc/systemd/system/gps-tracker.service
[Service]
MemoryMax=512M
CPUQuota=50%
```

---

## 🔐 Segurança

### Firewall (UFW)

```bash
# Instalar
apt-get install -y ufw

# Configurar
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable
```

### Fail2ban (Proteção SSH)

```bash
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### Headers de Segurança

Já configurados no `nginx.conf`:
- ✅ HSTS
- ✅ X-Frame-Options
- ✅ X-Content-Type-Options
- ✅ X-XSS-Protection

---

## 📱 Acesso

Depois do deploy:

- 🌐 **URL**: https://gps.avila.inc
- 📍 **GPS**: Funciona automaticamente (HTTPS obrigatório)
- 🔒 **Seguro**: SSL/TLS configurado
- ⚡ **Rápido**: Nginx + Rust nativo

---

## 📞 Suporte

### Comandos Rápidos

```bash
# Status completo
systemctl status gps-tracker nginx

# Logs importantes
journalctl -u gps-tracker -n 100

# Reiniciar tudo
systemctl restart gps-tracker nginx

# Ver conexões ativas
ss -tulpn | grep -E '(8080|80|443)'
```

### Rollback (Voltar versão)

```bash
# Listar backups
ls -la /var/www/gps.avila.inc/backups/

# Restaurar backup
systemctl stop gps-tracker
rm -rf /var/www/gps.avila.inc/current
cp -r /var/www/gps.avila.inc/backups/backup-XXXXXXXX /var/www/gps.avila.inc/current
systemctl start gps-tracker
```

---

## ✅ Checklist Final

- [ ] Servidor com Ubuntu/Debian
- [ ] DNS apontando para servidor
- [ ] SSH configurado
- [ ] Nginx instalado
- [ ] Build compilado
- [ ] Arquivos enviados
- [ ] Serviço systemd criado
- [ ] Nginx configurado
- [ ] SSL configurado (certbot)
- [ ] Firewall configurado
- [ ] Serviço rodando
- [ ] Site acessível em https://gps.avila.inc
- [ ] GPS funcionando

---

**Deploy criado com 🦀 Rust + Ecossistema Arxis/Avila**
