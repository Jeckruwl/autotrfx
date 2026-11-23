# Catalogatore Telegram

Pagina statica per catalogare manualmente un export Telegram. Non si collega a Telegram o MT5 e non invia ordini.

## Utilizzo

1. Apri la pagina pubblicata tramite GitHub Pages oppure usa un server web locale.
2. Premi **Importa HTML** e seleziona uno o più file HTML dell’export Telegram. I file vengono letti in ordine naturale per nome (`messages.html`, `messages2.html`, `messages10.html` ecc.) ed elaborati nel browser, senza inviarli al sito. Si apre la schermata di catalogazione.
3. Premi **newop**, **updateop**, **closeop**, **trash**, **recap**, **opening** o **warning**: la categoria viene salvata subito e appare il messaggio successivo, senza conferme. Se torni indietro e scegli un'altra categoria, questa sostituisce la precedente. Le frecce o i pulsanti **Precedente** e **Successivo** consentono di spostarsi senza cambiare le categorie. Con **Vai a** inserisci la posizione del messaggio (il numero mostrato sulla barra di avanzamento) e premi Invio o Vai. I contatori sopra i pulsanti mostrano quanti messaggi sono stati catalogati in ciascuna categoria.
4. Le scorciatoie iniziali sono **1, 2, 3, 4, 5, 6, 7**. Puoi cambiarle nelle impostazioni cliccando sulla casella della categoria e premendo un tasto. Le frecce navigano tra i messaggi e **Esc** riapre le impostazioni; c'è anche il pulsante a forma di ingranaggio.
5. Nelle impostazioni puoi esportare un **backup JSON** o ripristinarlo su un altro dispositivo. Ripristinare un backup sostituisce immediatamente il database locale. Se reimporti gli stessi HTML, le classificazioni vengono mantenute. Per file diversi, la pagina chiede conferma prima di sostituire il database: la sostituzione cancella le classificazioni precedenti, quindi esporta prima un backup completo. I file con ID messaggio duplicati non sono importati.

### Esportazione da una data

Nelle impostazioni, sotto **Backup e allegati**, scegli il giorno e premi **Scarica JSON filtrato**. La data è inclusa: il file contiene solo messaggi con data riconoscibile uguale o successiva al giorno scelto, confrontando le date originali dell’export senza conversioni di fuso orario. I messaggi senza data o con data non riconosciuta (anche eventi di servizio) sono esclusi, perché non è possibile stabilire se siano precedenti; la pagina ne mostra il numero. Sono riconosciute le date italiane dell’export, come `11 novembre 2022, 10:03:21`.

L’esportazione non modifica né elimina nulla nel browser. Nel JSON filtrato le posizioni vengono rinumerate da 1, mentre ID, testo e categorie restano invariati. Ripristinare anche questo file sostituisce tutto il database locale con i soli messaggi esportati: prima conserva un **backup completo**. Se nessun messaggio corrisponde, non viene scaricato alcun file.

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
