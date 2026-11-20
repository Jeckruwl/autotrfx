# Catalogatore Telegram

Pagina statica per catalogare manualmente un export Telegram. Non si collega a Telegram o MT5 e non invia ordini.

## Utilizzo

1. Apri la pagina pubblicata tramite GitHub Pages oppure usa un server web locale.
2. Premi **Importa i due HTML** e seleziona insieme `messages.html` e `messages2.html`. I file vengono elaborati nel browser, senza inviarli al sito. Si apre la schermata di catalogazione.
3. Premi **newop**, **updateop**, **closeop** o **trash**: la categoria viene salvata subito e appare il messaggio successivo, senza conferme. Se torni indietro e scegli un'altra categoria, questa sostituisce la precedente. Le frecce o i pulsanti **Precedente** e **Successivo** consentono di spostarsi senza cambiare le categorie.
4. Le scorciatoie iniziali sono **1, 2, 3, 4**. Puoi cambiarle nelle impostazioni cliccando sulla casella della categoria e premendo un tasto. Le frecce navigano tra i messaggi e **Esc** riapre le impostazioni; c'è anche il pulsante a forma di ingranaggio.
5. Nelle impostazioni puoi esportare un **backup JSON** o ripristinarlo su un altro dispositivo. Ripristinare un backup sostituisce immediatamente il database locale. Se reimporti gli stessi HTML, le classificazioni vengono mantenute; file diversi non sovrascrivono automaticamente il database esistente.

Facoltativamente, in impostazioni scegli **Seleziona cartella allegati** e indica la cartella completa dell'export per visualizzare gli allegati disponibili. Devi selezionarla nuovamente dopo aver chiuso la pagina. Alcuni browser potrebbero non supportare la selezione di cartelle.

## Salvataggio e privacy

Il database è memorizzato in **IndexedDB nel browser**, non nella repository. Il backup JSON contiene messaggi, categorie, data di catalogazione e posizione, ma non è un database SQLite. Per salvarlo nella repository bisogna caricarlo manualmente tramite GitHub; non si aggiorna automaticamente.

**La repository è pubblica:** se carichi o pubblichi il backup, messaggi e classificazioni saranno visibili a tutti. Il backup conserva i percorsi, non i file degli allegati. Conserva separatamente l'export originale ed esporta backup regolarmente: i dati del browser possono essere cancellati.

Gli eventi di servizio con ID sono inclusi; le intestazioni senza ID no. I messaggi senza testo non sono automaticamente `trash`. La data rimane nel formato originale dell'export. La versione precedente consentiva più categorie per messaggio: sono conservate, ma la scelta di un nuovo pulsante le sostituisce con quella categoria.

## GitHub Pages

Il file `index.html` deve essere disponibile nel ramo e nella cartella configurati in **Settings → Pages**. L'attivazione e la pubblicazione del sito non sono automatiche. Il sito è pubblico se la sua pubblicazione è pubblica.

Per prova sul proprio computer, dalla cartella del progetto:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

Poi apri `http://127.0.0.1:8000/`. Non è necessario Python su GitHub Pages. Il precedente catalogatore Python/SQLite nella cartella `catalogatore/` è separato: la pagina web non legge né modifica automaticamente quel database.
