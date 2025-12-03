# 🚀 Guia Completo de Deploy - Device Location Tracker

Sistema de rastreamento GPS 100% nativo com Arxis/Avila.

---

## 📋 Índice

1. [Deploy Local (Desenvolvimento)](#-1-deploy-local-desenvolvimento)
2. [Deploy Offline](#-2-deploy-offline)
3. [Deploy como Serviço Windows](#-3-deploy-como-serviço-windows)
4. [Deploy em Servidor](#-4-deploy-em-servidor)
5. [Deploy Docker](#-5-deploy-docker)
6. [Acesso Remoto](#-6-acesso-remoto)
7. [Troubleshooting](#-troubleshooting)

---

## 🖥️ 1. Deploy Local (Desenvolvimento)

### Compilar e Rodar

```powershell
# Compilar
cargo build --release

# Rodar direto
cargo run --release

# Ou usar o executável
.\target\release\device-location-tracker.exe
```

### Script Automatizado

```powershell
.\start.ps1
```

Acesse: **http://localhost:8080**

---

## 📴 2. Deploy Offline

Para usar **sem internet** (apenas com GPS do dispositivo):

```powershell
# Modo offline simples
.\run-offline.ps1

# Offline em background
.\run-offline.ps1 -Background

# Porta customizada
.\run-offline.ps1 -Port 3000
```

### Funcionalidades Offline

✅ **Funciona:**
- GPS do dispositivo
- Armazenamento local
- Interface web
- Histórico de localizações

❌ **Não funciona:**
- Tiles do mapa (use cache offline)
- Sincronização com servidor externo

---

## 🔧 3. Deploy como Serviço Windows

### Instalar como Serviço

```powershell
# Como administrador
.\install-service.ps1

# Porta customizada
.\install-service.ps1 -Port 8080
```

### Gerenciar Serviço

```powershell
# Iniciar
Start-Service DeviceLocationTracker

# Parar
Stop-Service DeviceLocationTracker

# Status
Get-Service DeviceLocationTracker

# Ver logs
Get-Content .\logs\service-output.log -Wait

# Reiniciar
Restart-Service DeviceLocationTracker
```

### Desinstalar Serviço

```powershell
.\uninstall-service.ps1
```

### Configurar Início Automático

```powershell
Set-Service -Name DeviceLocationTracker -StartupType Automatic
```

---

## 🖥️ 4. Deploy em Servidor

### Preparar Deploy

```powershell
# Deploy completo
.\deploy.ps1 -Mode server

# Deploy local
.\deploy.ps1 -Mode local

# Porta customizada
.\deploy.ps1 -Port 3000
```

### Estrutura do Deploy

```
deploy/
├── device-location-tracker.exe
├── static/
│   └── index.html
├── config.env
├── start.bat
├── install-service.ps1
└── README.md
```

### Windows Server

1. Copie a pasta `deploy/` para o servidor
2. Execute como administrador:
   ```powershell
   cd deploy
   .\install-service.ps1
   ```

### Firewall

```powershell
# Liberar porta
New-NetFirewallRule `
    -DisplayName "Device Tracker" `
    -Direction Inbound `
    -LocalPort 8080 `
    -Protocol TCP `
    -Action Allow
```

---

## 🐳 5. Deploy Docker

### Criar Container

```powershell
# Gerar arquivos Docker
.\deploy.ps1 -Mode docker

# Build
docker build -t location-tracker .

# Run
docker run -d -p 8080:8080 --name tracker location-tracker

# Com volume persistente
docker run -d \
    -p 8080:8080 \
    -v $(pwd)/data:/app/data \
    --name tracker \
    location-tracker
```

### Docker Compose

```yaml
version: '3.8'

services:
  location-tracker:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./location_history.json:/app/location_history.json
    restart: unless-stopped
    environment:
      - PORT=8080
```

```powershell
docker-compose up -d
```

---

## 🌐 6. Acesso Remoto

### Descobrir IP Local

```powershell
# Windows
ipconfig

# Procure por "IPv4 Address"
# Ex: 192.168.1.100
```

### Acessar de Outro Dispositivo

```
http://192.168.1.100:8080
```

### Acesso pela Internet (Avançado)

#### Opção 1: Redirecionamento de Porta no Roteador

1. Acesse configurações do roteador
2. Configure Port Forwarding:
   - Porta Externa: 8080
   - Porta Interna: 8080
   - IP Local: (seu IP local)

#### Opção 2: Túnel Ngrok

```powershell
# Instalar ngrok
choco install ngrok

# Criar túnel
ngrok http 8080
```

#### Opção 3: Cloudflare Tunnel

```powershell
# Instalar cloudflared
choco install cloudflared

# Criar túnel
cloudflared tunnel --url http://localhost:8080
```

### HTTPS para GPS

⚠️ **Importante**: Navegadores modernos requerem HTTPS para acessar GPS.

**Soluções:**
- Use `localhost` (sempre funciona)
- Configure certificado SSL
- Use túnel com HTTPS (ngrok/cloudflare)

---

## 🔍 Troubleshooting

### Porta em Uso

```powershell
# Ver processo usando a porta
netstat -ano | findstr :8080

# Matar processo
taskkill /PID <PID> /F
```

### GPS Não Funciona

**Problema:** "Geolocation não disponível"

**Soluções:**
1. ✅ Use **localhost** (não IP)
2. ✅ Configure **HTTPS**
3. ✅ Permita localização no navegador
4. ✅ Verifique se GPS está ativo

### Erro de Compilação

```powershell
# Limpar cache
cargo clean

# Atualizar Rust
rustup update

# Recompilar
cargo build --release
```

### Serviço Não Inicia

```powershell
# Ver logs
Get-Content .\logs\service-error.log

# Verificar permissões
icacls .\target\release\device-location-tracker.exe

# Testar manualmente
.\target\release\device-location-tracker.exe
```

### Firewall Bloqueando

```powershell
# Verificar regras
Get-NetFirewallRule -DisplayName "*Device*"

# Desabilitar temporariamente
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Reabilitar
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

---

## 📊 Monitoramento

### Verificar Status

```powershell
# Serviço rodando?
Get-Service DeviceLocationTracker

# Porta aberta?
Test-NetConnection -ComputerName localhost -Port 8080

# Processo ativo?
Get-Process -Name device-location-tracker -ErrorAction SilentlyContinue
```

### Logs

```powershell
# Logs do serviço
Get-Content .\logs\service-output.log -Wait -Tail 50

# Logs de erro
Get-Content .\logs\service-error.log
```

---

## 🔒 Segurança

### Recomendações

1. ✅ Configure firewall adequadamente
2. ✅ Use HTTPS em produção
3. ✅ Limite acesso por IP (se possível)
4. ✅ Mantenha histórico limitado
5. ✅ Monitore logs regularmente

### Configurar HTTPS (Avançado)

1. Gere certificado SSL
2. Configure reverse proxy (nginx/caddy)
3. Redirecione tráfego HTTPS para porta local

---

## 📈 Performance

### Otimizações

- ✅ Compilado com `--release` (máxima otimização)
- ✅ Zero dependências externas
- ✅ Thread pool nativo
- ✅ Parser JSON nativo
- ✅ Histórico limitado (1000 items)

### Recursos

- **CPU**: Mínimo (~1% idle)
- **RAM**: ~10MB
- **Disco**: <5MB (executável)
- **Rede**: Mínima (apenas GPS local)

---

## 🎯 Casos de Uso

### 1. Rastreamento Pessoal
```powershell
.\run-offline.ps1
```

### 2. Servidor Doméstico
```powershell
.\install-service.ps1
# Configure roteador para acesso remoto
```

### 3. Servidor de Produção
```powershell
.\deploy.ps1 -Mode server -Port 80
.\deploy\install-service.ps1
```

### 4. Container Docker
```powershell
.\deploy.ps1 -Mode docker
docker-compose up -d
```

---

## 📚 Recursos Adicionais

- [Documentação Arxis](https://github.com/avilaops/arxis)
- [Rust Book](https://doc.rust-lang.org/book/)
- [NSSM - Serviços Windows](https://nssm.cc/)

---

## 💡 Dicas

1. **Backup do Histórico**:
   ```powershell
   Copy-Item location_history.json location_history.backup.json
   ```

2. **Executar ao Inicializar Windows**:
   - Instale como serviço
   - Ou adicione ao Task Scheduler

3. **Múltiplas Instâncias**:
   ```powershell
   .\device-location-tracker.exe
   # Em outro terminal com porta diferente:
   $env:PORT=8081; .\device-location-tracker.exe
   ```

---

**Desenvolvido com 🦀 Rust + Ecossistema Arxis/Avila**
