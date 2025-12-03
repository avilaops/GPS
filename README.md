# 🌍 GPS Location Tracker

Sistema completo de rastreamento GPS em tempo real. **100% Rust nativo** usando ecossistema Arxis/Avila - zero dependências externas!

🌐 **Online em:** [gps.avila.inc](https://gps.avila.inc)

## ✨ Funcionalidades

- 📍 **Rastreamento GPS em Tempo Real** - Localização atualizada a cada 10 segundos
- 🗺️ **Visualização em Mapa Interativo** - OpenStreetMap/Leaflet
- 📊 **Histórico de Localizações** - Até 1000 registros
- 🎯 **Modo GOD** - Funciona sem permissões (localização simulada)
- 📍 **Teleporte** - Mude instantaneamente entre cidades mundiais
- 💾 **Armazenamento Persistente** - JSON local
- 🌐 **API RESTful** - Backend Rust nativo
- 📱 **Responsivo** - Desktop e mobile
- ⚡ **Alto Desempenho** - Zero overhead

## 🦀 Tecnologia

**100% Rust Nativo:**
- ✅ `avila-json` - Parser JSON nativo (zero deps)
- ✅ `avila-geo` - Sistema de coordenadas
- ✅ `std::net` - HTTP server puro
- ❌ Sem tokio
- ❌ Sem actix-web
- ❌ Sem serde

## 🚀 Uso Rápido

### Modo Offline (Mais Simples)

```powershell
.\run-offline.ps1
```

Acesse: **http://localhost:8080**

### Compilar e Rodar

```bash
cargo build --release
cargo run --release
```

## 🌐 Deploy Online

### Deploy Automático (GitHub Actions)

1. Configure secrets no GitHub:
   - `SERVER_HOST`
   - `SERVER_USER`
   - `SSH_PRIVATE_KEY`

2. Push para o repositório:
```bash
git push origin main
```

Deploy automático para **gps.avila.inc**!

### Deploy Manual

```powershell
# Windows
.\deploy-to-server.ps1 -SetupSSL

# Linux/Mac
./deploy-to-server.sh
```

📖 **Guia completo:** [README-DEPLOY-ONLINE.md](README-DEPLOY-ONLINE.md)

## 🎮 Como Usar

1. **Abra** o navegador em `http://localhost:8080` ou `https://gps.avila.inc`
2. **MODO GOD ativo** - Inicia automaticamente
3. **Clique "Mudar Localização"** para teleportar entre cidades

### Cidades Disponíveis

🌍 São Paulo • Rio de Janeiro • Brasília • Dubai • Nova York • Tóquio • Paris • Londres

## 📁 Estrutura

```
device-location-tracker/
├── src/
│   └── main.rs              # Backend Rust 100% nativo
├── static/
│   └── index.html           # Frontend com mapa
├── .github/workflows/
│   └── deploy.yml           # CI/CD automático
├── deploy-to-server.ps1     # Deploy Windows
├── deploy-to-server.sh      # Deploy Linux
├── nginx.conf               # Configuração Nginx
├── systemd-service.conf     # Serviço Linux
└── location_history.json    # Histórico (auto-criado)
```

## 🔌 API Endpoints

### `POST /api/location`
Atualiza localização
```json
{
  "latitude": -23.550520,
  "longitude": -46.633308,
  "accuracy": 10.5,
  "device_name": "Seu PC"
}
```

### `GET /api/location`
Retorna localização atual

### `GET /api/history`
Retorna histórico completo

### `DELETE /api/history/clear`
Limpa histórico

## 🎯 Modo GOD

- ✅ **Sem permissões** - Não pede acesso GPS
- ✅ **Auto-start** - Inicia automaticamente
- ✅ **Localização simulada** - Funciona sempre
- ✅ **Teleporte** - 8 cidades disponíveis
- ✅ **Movimento realista** - Simula deslocamento

## 🖥️ Como Serviço Windows

```powershell
# Instalar
.\install-service.ps1

# Gerenciar
Start-Service DeviceLocationTracker
Stop-Service DeviceLocationTracker
Get-Service DeviceLocationTracker
```

## 📊 Performance

- **CPU**: ~1% idle
- **RAM**: ~10MB
- **Binário**: <5MB
- **Dependências externas**: 0
- **Latência**: <5ms

## 🔒 Segurança (Produção)

✅ HTTPS obrigatório  
✅ CORS configurado  
✅ Headers de segurança  
✅ Firewall configurado  
✅ SSL/TLS com Let's Encrypt  

## 📝 Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `run-offline.ps1` | Rodar localmente offline |
| `deploy.ps1` | Deploy local/server/docker |
| `deploy-to-server.ps1` | Deploy para gps.avila.inc |
| `install-service.ps1` | Instalar como serviço Windows |
| `uninstall-service.ps1` | Remover serviço |
| `start.ps1` | Iniciar servidor simples |

## 🌐 Acesso Online

- **Produção**: https://gps.avila.inc
- **Local**: http://localhost:8080

## 📖 Documentação

- [Deploy Local & Offline](README-DEPLOY.md)
- [Deploy Online (gps.avila.inc)](README-DEPLOY-ONLINE.md)

## 🤝 Contribuir

```bash
git clone https://github.com/avilaops/GPS.git
cd GPS
cargo build --release
```

## 📄 Licença

MIT OR Apache-2.0

---

**Desenvolvido com 🦀 Rust + Ecossistema Arxis/Avila**  
**Zero dependências externas | 100% código nativo brasileiro**
