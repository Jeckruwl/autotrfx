# Catalogatore Telegram

Pagina statica per catalogare manualmente i messaggi di un export Telegram. Non si collega a Telegram o MT5 e non invia ordini.

## Come usarla

1. Pubblica `index.html` con GitHub Pages oppure aprila tramite un server web locale. Usa un browser aggiornato con supporto a IndexedDB.
2. Premi **Importa i due HTML** e seleziona contemporaneamente `messages.html` e `messages2.html` dal tuo dispositivo. I file sono elaborati nel browser e non vengono inviati al sito.
3. Per vedere le immagini disponibili, premi facoltativamente **Seleziona cartella allegati** e scegli la cartella completa dell'export. La selezione degli allegati non viene conservata dopo la chiusura della pagina. Alcuni browser potrebbero non supportare la selezione di cartelle.
4. Per ogni messaggio scegli `newop`, `updateop`, `closeop` o `trash`, e premi **Salva e avanti**. È possibile selezionare più categorie, tranne `trash` che è esclusiva. Puoi saltare, tornare indietro, modificare o rimuovere una catalogazione.
5. Premi regolarmente **Esporta backup JSON**: il file contiene messaggi, categorie, data di catalogazione e posizione. Su un altro dispositivo, o dopo aver cancellato i dati del sito, premi **Ripristina backup JSON**. Ripristinare un backup o reimportare gli HTML sostituisce il database locale, previa conferma.

Le classificazioni sono memorizzate automaticamente in **IndexedDB nel browser**, non nella repository. Il JSON esportato è un backup leggibile anche da altri programmi, ma **non è un database SQLite**. Per salvarlo nella repository bisogna caricarlo manualmente tramite GitHub; non si aggiorna automaticamente.

**Privacy:** la repository è pubblica. Se carichi il backup JSON nella repository o lo pubblichi, i testi e le classificazioni diventano pubblici. Il backup non contiene i file degli allegati, solo i loro percorsi; conserva separatamente l'export originale. La memoria del browser può essere cancellata dal browser o dall'utente: il backup è importante. Non condividere credenziali.

Gli eventi di servizio che hanno un ID sono inclusi; le intestazioni senza ID no. I messaggi senza testo non sono automaticamente `trash`. La data rimane nel formato originale dell'export.

## GitHub Pages

La sola presenza di `index.html` non pubblica il sito automaticamente. Su GitHub occorre rendere il file disponibile sul ramo/cartella di pubblicazione configurato in **Settings → Pages**, attivare Pages se necessario e attendere la pubblicazione. Finché le modifiche restano solo in questo ramo di lavoro non sono disponibili automaticamente sul ramo predefinito. Il sito è pubblico se la sua pubblicazione è pubblica.

Per prova sul proprio computer, dalla cartella del progetto:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

Poi apri `http://127.0.0.1:8000/`. Non è necessario Python su GitHub Pages. Il vecchio catalogatore Python/SQLite nella cartella `catalogatore/` è separato: la pagina web non legge né modifica automaticamente quel database.
