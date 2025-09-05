# 🐳 Test Locale con Docker

Questa guida ti aiuta a testare l'applicazione Data Viz Satellite MVP in locale usando Docker.

## 🚀 Avvio Rapido

### 1. Build e avvio dei container

```powershell
# Build delle immagini Docker
docker-compose build

# Avvio dei servizi in background
docker-compose up -d
```

### 2. Verifica dello stato

```powershell
# Controlla lo stato dei container
docker-compose ps

# Esegui il test automatico
./test-local-docker.ps1
```

### 3. Accesso all'applicazione

- **Frontend**: http://localhost:3000
- **API Backend**: http://localhost:8000
- **Documentazione API**: http://localhost:8000/docs

## 🏗️ Architettura

L'applicazione è composta da due servizi principali:

### Frontend (Next.js)
- **Porta**: 3000 (mappata dalla porta interna 8080)
- **Tecnologie**: Next.js 15, React 19, TypeScript, Tailwind CSS
- **Features**: 
  - Volcano plots interattivi
  - Interfaccia utente moderna
  - Proxy API per comunicazione con backend

### Backend (FastAPI)
- **Porta**: 8000 (mappata dalla porta interna 9000)
- **Tecnologie**: Python 3.11, FastAPI, Polars, scikit-learn
- **Features**:
  - API REST per dati volcano plot
  - Generazione dati sintetici
  - Cache intelligente
  - Health checks

## 🔧 Comandi Utili

### Gestione Container

```powershell
# Avvia i servizi
docker-compose up -d

# Ferma i servizi
docker-compose down

# Riavvia un servizio specifico
docker-compose restart web
docker-compose restart api

# Rebuild e riavvio
docker-compose up -d --build
```

### Monitoring e Debug

```powershell
# Visualizza i log
docker-compose logs -f web    # Frontend logs
docker-compose logs -f api    # Backend logs
docker-compose logs -f        # Tutti i logs

# Accesso shell nei container
docker-compose exec web sh    # Shell nel container frontend
docker-compose exec api bash  # Shell nel container backend

# Statistiche risorse
docker stats
```

### Test e Verifica

```powershell
# Test automatico completo
./test-local-docker.ps1

# Test manuali API
curl http://localhost:8000/health
curl "http://localhost:8000/api/volcano-data?dataset_size=1000"

# Test frontend
curl http://localhost:3000
curl "http://localhost:3000/api/volcano-data?dataset_size=1000"
```

## 📊 Endpoint API Principali

### Health Checks
- `GET /health` - Status dell'API
- `GET /ready` - Readiness check

### Volcano Data
- `GET /api/volcano-data` - Dati per volcano plot
  - Parametri: `dataset_size`, `p_value_threshold`, `log_fc_min`, `log_fc_max`, etc.

### Cache Management
- `GET /api/cache-status` - Status della cache
- `POST /api/warm-cache` - Pre-caricamento cache
- `POST /api/clear-cache` - Pulizia cache

### PCA Data
- `GET /api/pca-data` - Dati per PCA plot
  - Parametri: `dataset_size`, `n_features`, `n_groups`, etc.

## 🐛 Troubleshooting

### Container non si avvia
```powershell
# Controlla i logs per errori
docker-compose logs

# Rimuovi container e volumi
docker-compose down -v
docker-compose up -d --build
```

### Errori di connessione
- Verifica che le porte 3000 e 8000 non siano occupate
- Controlla le variabili d'ambiente nel docker-compose.yml
- Assicurati che `API_INTERNAL_URL=http://api:9000` sia configurato

### Performance lente
```powershell
# Controlla l'uso delle risorse
docker stats

# Limita la memoria se necessario
docker-compose down
# Modifica docker-compose.yml aggiungendo limits
docker-compose up -d
```

### Pulizia completa
```powershell
# Ferma tutto e rimuovi volumi
docker-compose down -v

# Rimuovi immagini locali
docker rmi data-viz-sat-mvp-web data-viz-sat-mvp-api

# Rebuild completo
docker-compose build --no-cache
docker-compose up -d
```

## 🔒 Sicurezza

- I container girano con utenti non-root
- Le porte sono esposte solo localmente
- CORS configurato per sviluppo locale
- Health checks attivi per monitoraggio

## 📈 Performance

### Ottimizzazioni attive:
- Cache multi-livello per dati sintetici
- Sampling intelligente per grandi dataset
- Compressione response HTTP
- Build multi-stage per immagini ottimizzate

### Limiti consigliati:
- Dataset size: max 1M punti
- Features PCA: max 2K
- Concurrent requests: 10-20

## 🚀 Prossimi Passi

Dopo aver testato in locale, puoi:

1. **Deploy su Cloud Run**: Usa `./deploy-and-test.ps1`
2. **Configurazione CI/CD**: Setup GitHub Actions
3. **Monitoring**: Aggiungi logging e metriche
4. **Scaling**: Configura auto-scaling per produzione

---

**Buon testing! 🎉**