# Catalogatore Telegram

Pagina statica per catalogare manualmente un export Telegram. Non si collega a Telegram o MT5 e non invia ordini.

## Utilizzo

1. Apri la pagina pubblicata tramite GitHub Pages oppure usa un server web locale.
2. Premi **Importa HTML** e seleziona uno o più file HTML dell’export Telegram. I file vengono letti in ordine naturale per nome (`messages.html`, `messages2.html`, `messages10.html` ecc.) ed elaborati nel browser, senza inviarli al sito. Si apre la schermata di catalogazione.
3. Premi **neword**, **updord**, **clsord**, **openord**, **newpos**, **updpos**, **clspos**, **trash**, **recap** o **warning**: la categoria viene salvata subito e appare il messaggio successivo, senza conferme. Se torni indietro e scegli un'altra categoria, questa sostituisce la precedente. Le frecce o i pulsanti **Precedente** e **Successivo** consentono di spostarsi senza cambiare le categorie. Con **Vai a** inserisci la posizione del messaggio e premi Invio o Vai. I contatori sopra i pulsanti mostrano quanti messaggi sono catalogati in ciascuna categoria.
4. Le scorciatoie iniziali per i nuovi utenti sono **1, 2, 3, 4, 5, 6, 7, 8, 9, 0**, nell'ordine dei pulsanti. Puoi cambiarle nelle impostazioni cliccando sulla casella e premendo un tasto. Le scorciatoie già configurate sono mantenute ove possibile. Le frecce navigano tra i messaggi e **Esc** riapre le impostazioni; c'è anche il pulsante a forma di ingranaggio.
5. Nelle impostazioni puoi esportare un **backup JSON** o ripristinarlo su un altro dispositivo. Ripristinare un backup sostituisce immediatamente il database locale. Se reimporti gli stessi HTML, le classificazioni vengono mantenute. Per file diversi, la pagina chiede conferma prima di sostituire il database: la sostituzione cancella le classificazioni precedenti, quindi esporta prima un backup completo. I file con ID messaggio duplicati non sono importati.

### Categorie e cataloghi precedenti

- **neword**: nuovo ordine pendente; **updord**: modifica di un pendente; **clsord**: annullamento di un pendente; **openord**: notifica che un pendente si è aperto a mercato.
- **newpos**: apertura diretta a mercato; **updpos**: modifica di una posizione aperta; **clspos**: richiesta di chiusura di una o più posizioni.
- **trash** e **recap** conservano il loro significato. **warning** comprende le notifiche di stop loss già raggiunto. Il catalogatore non verifica il conto e non esegue chiusure.

All'apertura di un catalogo esistente o al ripristino di un vecchio backup, i casi riconoscibili vengono convertiti automaticamente secondo il testo e, quando necessario, la catena di risposte. Per esempio, un `closeop` con richiesta di chiusura manuale diventa `clspos`, e un `updateop` che annulla un pending diventa `clsord`. Una notifica `STOP LOSS` con collegamento a un ordine riconosciuto diventa `warning`. Un'apertura legacy diventa `openord` solo se è possibile risalire a un pendente; una modifica generica viene convertita in `updpos` solo se la catena indica una posizione aperta.

**I casi non riconoscibili e le classificazioni multiple restano invariati e sono segnalati come “da verificare”**, non vengono contati come catalogati né attribuiti automaticamente a una nuova categoria. Il pulsante **Prossima categoria da verificare** li raggiunge; scegliendo una categoria li si conferma manualmente. La categoria precedente viene conservata nel campo `legacyCategories` del JSON, insieme a messaggi e collegamenti. Esporta un backup prima di modificare le classificazioni e un altro dopo la verifica. Il nuovo backup ha versione 2; restano importabili i vecchi backup versione 1. Le conversioni sono suggerimenti basati su schemi, non una verifica del conto o un'autorizzazione a fare trading.

### Catene di ordini e posizioni

Ogni messaggio `neword` o `newpos` apre una catena identificata dal suo **ID Telegram numerico**. Un `openord` collegato resta nella stessa catena del pendente: non ne crea una nuova. Per le successive modifiche e notifiche, il catalogatore segue la catena delle risposte `replyToId` fino al messaggio iniziale, senza dedurre collegamenti soltanto dal prezzo. Le informazioni sono calcolate di nuovo quando si esporta il JSON: `chainId` contiene l'ID iniziale quando è unico, `chainIds` elenca tutti gli ID collegati e `chainStatus` descrive la provenienza o l'incertezza. Gli ID sono univoci solo all'interno della chat/catalogo; non sono identificativi del broker.

Se una risposta non è presente, il collegamento non è ricostruibile automaticamente e risulta **non identificato**. Le chiusure multiple con una sola risposta sono indicate come **parziali**, perché una risposta non identifica necessariamente tutte le posizioni. Il pulsante **Catene da verificare** consente di raggiungere questi casi. La scheda offre **Collega catene**: inserisci gli ID Telegram dei messaggi iniziali `neword` o `newpos`, separati da virgole, e salva. Il collegamento manuale è registrato come `manualChainIds`; la responsabilità di verificare che comprenda tutte le posizioni resta all'utente. Svuotando il campo si torna al collegamento automatico. Nessun collegamento è un ordine di trading.

Una esportazione filtrata conserva i riferimenti ricavati prima del filtro anche quando il messaggio iniziale è escluso; dopo il ripristino sono marcati come **esterni**, da verificare. Cambiare la categoria di un messaggio iniziale può cambiare o rendere irrisolvibili i collegamenti: riesporta il backup e verifica le catene interessate.

### Collegamenti alle risposte

I nuovi HTML importati salvano nel JSON anche `replyToId`, l’ID Telegram del messaggio a cui si risponde direttamente. `null` significa che non è indicata una risposta; il campo assente indica che il riferimento non era disponibile o non è stato riconosciuto. Il messaggio a cui si risponde può non essere presente nel catalogo (per esempio se si esporta da una data), e gli ID sono riferiti alla stessa chat: il collegamento non garantisce che un’azione sia eseguibile.

Per aggiornare un catalogo già classificato, prima esporta un backup completo. Nelle impostazioni premi **Aggiorna collegamenti da HTML** e seleziona gli HTML originali che contengono tutti i messaggi del catalogo, con i nomi usati all’importazione. La pagina verifica ID, file di origine e contenuti: se trova differenze o collegamenti in conflitto non modifica nulla. I file possono contenere anche messaggi aggiuntivi (ad esempio nel caso di un catalogo filtrato). Le date di classificazione e la posizione restano invariate; le categorie legacy che diventano riconoscibili possono essere convertite. Infine esporta un nuovo backup JSON. Reimportando gli stessi HTML tramite **Importa HTML** vengono ugualmente aggiunti i collegamenti mancanti. I vecchi backup senza questo campo restano utilizzabili.

### Esportazione da una data

Nelle impostazioni, sotto **Backup e allegati**, scegli il giorno e premi **Scarica JSON filtrato**. La data è inclusa: il file contiene solo messaggi con data riconoscibile uguale o successiva al giorno scelto, confrontando le date originali dell’export senza conversioni di fuso orario. I messaggi senza data o con data non riconosciuta (anche eventi di servizio) sono esclusi, perché non è possibile stabilire se siano precedenti; la pagina ne mostra il numero. Sono riconosciute le date italiane dell’export, come `11 novembre 2022, 10:03:21`.

L’esportazione non modifica né elimina nulla nel browser. Nel JSON filtrato le posizioni vengono rinumerate da 1, mentre ID, testo e categorie restano invariati. Ripristinare anche questo file sostituisce tutto il database locale con i soli messaggi esportati: prima conserva un **backup completo**. Se nessun messaggio corrisponde, non viene scaricato alcun file.

Facoltativamente, in impostazioni scegli **Seleziona cartella allegati** e indica la cartella completa dell'export per visualizzare gli allegati disponibili. Devi selezionarla nuovamente dopo aver chiuso la pagina. Alcuni browser potrebbero non supportare la selezione di cartelle.

## Salvataggio e privacy

Il database è memorizzato in **IndexedDB nel browser**, non nella repository. Il backup JSON contiene messaggi, categorie, data di catalogazione e posizione, ma non è un database SQLite. Per salvarlo nella repository bisogna caricarlo manualmente tramite GitHub; non si aggiorna automaticamente.

**La repository è pubblica:** se carichi o pubblichi il backup, messaggi e classificazioni saranno visibili a tutti. Il backup conserva i percorsi, non i file degli allegati. Conserva separatamente l'export originale ed esporta backup regolarmente: i dati del browser possono essere cancellati.

Gli eventi di servizio con ID sono inclusi; le intestazioni senza ID no. I messaggi senza testo non sono automaticamente `trash`. La data rimane nel formato originale dell'export. La versione precedente consentiva più categorie per messaggio: sono segnalate da verificare e conservate in `legacyCategories` quando si sceglie una nuova categoria.

## GitHub Pages

Il file `index.html` deve essere disponibile nel ramo e nella cartella configurati in **Settings → Pages**. L'attivazione e la pubblicazione del sito non sono automatiche. Il sito è pubblico se la sua pubblicazione è pubblica.

Per prova sul proprio computer, dalla cartella del progetto:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

Poi apri `http://127.0.0.1:8000/`. Non è necessario Python su GitHub Pages. Il precedente catalogatore Python/SQLite nella cartella `catalogatore/` è separato: la pagina web non legge né modifica automaticamente quel database.
