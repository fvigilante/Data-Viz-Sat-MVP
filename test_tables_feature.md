# Nuova Funzionalità: Tabelle Dinamiche per Gruppi PCA

## Funzionalità Implementate

### 🎛️ **Controlli di Visibilità Gruppi**
- **Toggle Buttons**: Un pulsante per ogni gruppo con colore corrispondente al grafico
- **Contatore Campioni**: Ogni pulsante mostra il numero di campioni nel gruppo
- **Show All / Hide All**: Pulsanti per mostrare/nascondere tutti i gruppi contemporaneamente

### 📊 **Tabelle Dinamiche**
- **Una tabella per gruppo**: Appare automaticamente quando selezioni un gruppo
- **Colori coordinati**: Ogni tabella ha il bordo colorato come il gruppo nel grafico
- **Dati completi**: Sample ID, PC1, PC2, PC3, Batch (se presente)
- **Limite visualizzazione**: Prime 50 righe per performance, con indicatore del totale

### 📥 **Download Individuale**
- **CSV per gruppo**: Ogni tabella ha il suo pulsante download
- **Nome file intelligente**: `pca_data_group_1.csv`, `pca_data_group_2.csv`, etc.
- **Download completo**: Tutti i campioni del gruppo, non solo i primi 50

### 🎨 **Sincronizzazione Grafico**
- **Visibilità coordinata**: Nascondere un gruppo lo rimuove anche dal grafico 3D
- **Aggiornamento real-time**: Le modifiche si riflettono immediatamente
- **Colori consistenti**: Stessi colori tra grafico e interfaccia

## Come Funziona

### 1. **Selezione Gruppi**
```typescript
// Stato per tracciare gruppi visibili
const [visibleGroups, setVisibleGroups] = useState<Set<string>>(new Set())

// Toggle visibilità gruppo
const toggleGroupVisibility = useCallback((group: string) => {
  setVisibleGroups(prev => {
    const newSet = new Set(prev)
    if (newSet.has(group)) {
      newSet.delete(group)  // Rimuovi se presente
    } else {
      newSet.add(group)     // Aggiungi se assente
    }
    return newSet
  })
}, [])
```

### 2. **Filtraggio Dati Grafico**
```typescript
// Il grafico mostra solo i gruppi selezionati
const filteredData = data.filter(point => visibleGroups.has(point.group))
```

### 3. **Generazione Tabelle**
```typescript
// Una tabella per ogni gruppo visibile
{Array.from(visibleGroups).sort().map((group, index) => {
  const groupData = groupedTableData[group] || []
  return <GroupTable key={group} group={group} data={groupData} />
})}
```

## Interfaccia Utente

### Controlli Gruppi
- **Pulsanti colorati**: Rosso, Blu, Verde, Ambra, Viola, Rosa, Ciano, Lime
- **Stato attivo/inattivo**: Pulsante pieno = visibile, outline = nascosto
- **Contatori**: `Group_1 (334)`, `Group_2 (333)`, `Group_3 (333)`

### Tabelle
- **Header colorato**: Bordo sinistro colorato + sfondo tenue
- **Dati formattati**: Coordinate PC con 4 decimali, font monospace
- **Righe alternate**: Bianco/grigio per leggibilità
- **Azioni**: Download CSV + Hide Table

### Performance
- **Limite 50 righe**: Per evitare lag con dataset grandi
- **Indicatore totale**: "Showing first 50 of 1000 samples"
- **Download completo**: CSV contiene tutti i dati, non solo i primi 50

## Benefici

✅ **Esplorazione Dati**: Vedi i dati numerici dietro la visualizzazione
✅ **Analisi Selettiva**: Concentrati sui gruppi di interesse
✅ **Export Flessibile**: Scarica dati per gruppo specifico
✅ **Performance**: Tabelle limitate, grafico filtrato
✅ **UX Intuitiva**: Controlli chiari e feedback visivo
✅ **Sincronizzazione**: Grafico e tabelle sempre allineati

## Test Suggeriti

1. **Test Toggle Gruppi**:
   - Clicca sui pulsanti gruppo → tabelle appaiono/scompaiono
   - Verifica che il grafico si aggiorni di conseguenza

2. **Test Show All / Hide All**:
   - Hide All → tutte le tabelle scompaiono, grafico vuoto
   - Show All → tutte le tabelle riappaiono, grafico completo

3. **Test Download**:
   - Scarica CSV di un singolo gruppo
   - Verifica che contenga solo i dati di quel gruppo

4. **Test Performance**:
   - Con dataset grandi, verifica che le tabelle mostrino max 50 righe
   - Verifica che il download CSV contenga tutti i dati