# Requirements Document

## Introduction

L'analisi dei benchmark ha rivelato una significativa differenza di performance tra l'implementazione R e Python per la generazione e serializzazione dei dati volcano plot. Python risulta molto più veloce di R, probabilmente a causa di inefficienze nella conversione dei dati da data.table a formato JSON per Plotly nel frontend.

## Glossary

- **R_API**: Il server API R basato su Plumber per la generazione di dati volcano plot
- **Python_API**: Il server API Python basato su FastAPI per la generazione di dati volcano plot  
- **JSON_Serialization**: Il processo di conversione dei dati da formato R (data.table) a JSON
- **Data_Conversion**: La trasformazione dei dati da formato tabulare a lista di oggetti per il frontend
- **Performance_Bottleneck**: Il collo di bottiglia che causa la lentezza dell'API R rispetto a Python

## Requirements

### Requirement 1

**User Story:** Come sviluppatore, voglio che l'API R abbia performance comparabili a Python, così che gli utenti possano scegliere il backend senza penalizzazioni significative di velocità

#### Acceptance Criteria

1. WHEN l'API R processa dataset di 100K punti, THE R_API SHALL completare la richiesta in meno di 2 secondi
2. WHEN si confrontano le performance R vs Python, THE R_API SHALL avere un overhead massimo del 50% rispetto al Python_API
3. WHEN si serializzano i dati in JSON, THE JSON_Serialization SHALL utilizzare metodi ottimizzati per ridurre il tempo di conversione
4. WHEN si convertono i dati da data.table a lista, THE Data_Conversion SHALL evitare loop espliciti in favore di operazioni vettorizzate
5. THE R_API SHALL mantenere la compatibilità con l'interfaccia esistente

### Requirement 2

**User Story:** Come utente dell'applicazione, voglio che la visualizzazione dei volcano plot sia fluida indipendentemente dal backend scelto, così che l'esperienza utente sia consistente

#### Acceptance Criteria

1. WHEN l'utente richiede un volcano plot tramite R backend, THE R_API SHALL rispondere entro 3 secondi per dataset fino a 500K punti
2. WHEN si applica il downsampling intelligente, THE R_API SHALL mantenere la qualità dei dati significativi
3. WHEN si utilizza il level-of-detail loading, THE R_API SHALL adattare dinamicamente il numero di punti in base al zoom level
4. THE R_API SHALL fornire feedback di progresso per operazioni che richiedono più di 1 secondo
5. THE R_API SHALL gestire gracefully i timeout e gli errori di memoria

### Requirement 3

**User Story:** Come amministratore di sistema, voglio monitorare e ottimizzare le performance dell'API R, così che possa identificare e risolvere i bottleneck

#### Acceptance Criteria

1. THE R_API SHALL loggare i tempi di esecuzione per ogni fase del processing (generazione dati, categorizzazione, sampling, serializzazione)
2. WHEN si identifica un Performance_Bottleneck, THE R_API SHALL fornire metriche dettagliate per il debugging
3. THE R_API SHALL implementare caching intelligente per ridurre la rigenerazione di dati identici
4. WHEN la memoria raggiunge soglie critiche, THE R_API SHALL attivare garbage collection automatico
5. THE R_API SHALL fornire endpoint di diagnostica per il monitoraggio delle performance