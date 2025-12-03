# ⚡ Setup Rápido - gps.avila.inc

Guia ultrarrápido para colocar online em **5 minutos**!

---

## 🎯 Checklist Rápido

### 1. GitHub (1 min)

✅ Código já está no GitHub: `github.com/avilaops/GPS`

Configure Secrets:
```
Settings → Secrets → Actions → New secret

SERVER_HOST = gps.avila.inc (ou IP do servidor)
SERVER_USER = root
SSH_PRIVATE_KEY = (sua chave privada SSH)
```

### 2. DNS (2 min)

**No seu provedor DNS:**

```
Tipo: A
Nome: gps
Valor: SEU_IP_SERVIDOR
TTL: 300
```

Ou se preferir CNAME:
```
Tipo: CNAME
Nome: gps
Valor: avila.inc
TTL: 300
```

**Verificar:**
```powershell
nslookup gps.avila.inc
```

### 3. Servidor (2 min)

**Conectar no servidor:**
```bash
ssh root@gps.avila.inc
```

**Instalar requisitos:**
```bash
# Ubuntu/Debian
apt-get update
apt-get install -y nginx curl

# Criar estrutura
mkdir -p /var/www/gps.avila.inc/{current,backups}
mkdir -p /var/log/gps-tracker
```

### 4. Deploy

**Opção A: GitHub Actions (Automático)**

```bash
git push origin main
```

Aguarde 2-3 minutos. Pronto! ✅

**Opção B: Script Manual**

```powershell
.\deploy-to-server.ps1 -SetupSSL
```

---

## 🔒 SSL (Opcional - 1 min)

```bash
# No servidor
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d gps.avila.inc -m admin@avila.inc --agree-tos --non-interactive
```

---

## ✅ Testar

```bash
# Status do serviço
systemctl status gps-tracker

# Testar localmente no servidor
curl http://localhost:8080

# Testar do seu PC
curl https://gps.avila.inc
```

**Abrir no navegador:**
```
https://gps.avila.inc
```

---

## 🔧 Comandos Úteis

```bash
# Ver logs em tempo real
journalctl -u gps-tracker -f

# Restart
systemctl restart gps-tracker

# Status completo
systemctl status gps-tracker nginx

# Ver quem está conectado
ss -tulpn | grep -E '(8080|80|443)'
```

---

## 🚨 Problemas?

### Serviço não inicia
```bash
journalctl -u gps-tracker -n 50
```

### Nginx 502
```bash
curl http://localhost:8080  # Backend rodando?
systemctl status gps-tracker
```

### DNS não resolve
```bash
dig gps.avila.inc
# Aguarde propagação (até 24h, geralmente 5 min)
```

### SSL erro
```bash
certbot certificates
certbot renew
```

---

## 📊 Monitoramento Simples

```bash
# Ver recursos
htop

# Ver memória do processo
ps aux | grep device-location

# Ver logs últimas 100 linhas
journalctl -u gps-tracker -n 100
```

---

## 🎉 Pronto!

Acesse: **https://gps.avila.inc**

GPS funcionando online! 🌍

---

**Tempo total: ~5 minutos** ⚡
