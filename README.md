# Smart Table OS — App P0

Pilota: Ardea Caffè · Stack: HTML/CSS/JS + Supabase Realtime · Offline coda locale

## Cosa c’è ora

| Pagina | Uso |
|---|---|
| `index.html?tavolo=05` | Cliente al tavolo (NFC/QR) |
| `staff.html` | Cameriere telefono (PRENDI / CHIUDI / PAUSA) |
| `dashboard.html` | Responsabile / muro |
| `supabase/001_p0_staff_first.sql` | Schema da eseguire su Supabase |

## Avvio in 3 passi

1. Apri Supabase → SQL Editor → incolla ed esegui `supabase/001_p0_staff_first.sql`
2. In Replication, assicurati che `calls`, `staff_status`, `tables` siano in realtime
3. Pubblica su Vercel (o apri i file in locale con un static server)

Self-check a video:
- Verde: *Tutto collegato e funzionante*
- Giallo: coda offline
- Rosso: manca cloud

## Test rapido

1. Apri `index.html?tavolo=07` → tocca Acqua  
2. Apri `staff.html` → inserisci nome → **Prendi** → **Chiudi**  
3. Sul cliente deve comparire feedback “sta arrivando / Fatto”  
4. **Pausa protetta** su staff → la coda si nasconde  

## Prossimi pezzi

Menu digitale · 86 · pre-conto · KDS · Watch companion nativo
