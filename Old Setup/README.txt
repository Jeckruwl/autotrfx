FREE VPS TELEGRAM SIGNAL CHANNEL MT5 EXPERT ADVISOR (TGSCHEA)- GUIDA INSTALLAZIONE
========================================
Versione 4 - Giugno 2026

Questo pacchetto installa un sistema che legge i segnali dal canale Telegram
e li esegue automaticamente su MetaTrader 5 tramite una VPS Oracle Cloud Free Tier.

Componenti:
  - setup_vps.sh               Script di installazione completo
  - telegram_signal_reader.py  Lettore segnali Telegram (Python)
  - TelegramSignalEA.mq5       Expert Advisor per MetaTrader 5
  - mt5setup.exe               Installer MetaTrader 5
  - VC_redist_x64.exe          Microsoft Visual C++ Runtime (richiesto da MT5)
  - README.txt                 Questo file


========================================
PARTE 1 - PREREQUISITI
========================================


1.1 ORACLE CLOUD FREE TIER - CREAZIONE ACCOUNT
-----------------------------------------------
Andare su https://cloud.oracle.com e creare un account gratuito.

Dati richiesti durante la registrazione:
  - Nome e cognome
  - Email valida (usata per il login)
  - Numero di carta di credito (non viene addebitato nulla, serve solo per verifica)
  - Numero di telefono per OTP

Al termine della registrazione Oracle assegna:
  - 200 USD di credito gratuito per 30 giorni
  - Risorse Always Free che non scadono mai (quelle che useremo)


1.2 ORACLE CLOUD - CREAZIONE VPS
---------------------------------
Dopo il login andare su Menu principale > Compute > Instances > Create Instance.

NOME: scegliere un nome a piacere (es. mt5bot)

IMMAGINE E SHAPE:
  Cliccare "Edit" nella sezione Image and Shape.
  Image: Canonical Ubuntu 22.04 (Always Free-eligible)
  Shape: VM.Standard.A1.Flex (Always Free)

  In alternativa usare VM.Standard.E2.1.Micro se A1 non e' disponibile
  nella propria region (solo 1 OCPU, 1 GB RAM - funziona ma piu' lento).

NETWORKING:
  Lasciare i valori di default (crea una nuova VCN automaticamente).

SSH KEY:
  Selezionare "Generate a key pair for me" e scaricare la chiave privata.
  Salvare il file .key in un posto sicuro, serve per connettersi alla VPS.
  Rinominarlo in prkey.key e salvarlo nella stessa cartella di questo README.

Cliccare "Create" e attendere che lo stato diventi "Running" (1-2 minuti).
Annotare l'IP pubblico mostrato nella pagina dell'istanza.


1.3 ORACLE CLOUD - APERTURA PORTE DI RETE
------------------------------------------
Di default Oracle blocca tutte le porte tranne la 22 (SSH).
Aprire la porta 5900 per VNC (necessaria per accedere a MT5 via schermo remoto).

Andare su:
  Menu > Networking > Virtual Cloud Networks
  Cliccare la VCN creata automaticamente
  Cliccare "Public Subnet"
  Cliccare la Security List
  Cliccare "Add Ingress Rules"

Aggiungere la regola:
  Source CIDR: 0.0.0.0/0
  IP Protocol: TCP
  Destination Port Range: 5900

Cliccare "Add Ingress Rules" per salvare.

Nota: la porta 5900 e' accessibile da qualsiasi IP. Per maggiore sicurezza
sostituire 0.0.0.0/0 con il proprio IP pubblico (trovarlo su https://ifconfig.me).


1.4 CONNESSIONE SSH ALLA VPS
-----------------------------
Da terminale (Mac/Linux) nella cartella dove si trova prkey.key:

Bash: 
  chmod 600 prkey.key
  ssh -i prkey.key ubuntu@IP_DELLA_VPS

Sostituire IP_DELLA_VPS con l'IP annotato in precedenza.
Al primo accesso digitare "yes" per confermare l'impronta del server.


1.5 TELEGRAM - CREAZIONE APP API
----------------------------------
Telethon richiede credenziali API di Telegram per leggere i messaggi.
Queste credenziali sono personali e legate all'account Telegram dell'utente.

Andare su https://my.telegram.org/apps con il browser.
Fare login con il numero di telefono dell'account Telegram.
Inserire il codice OTP ricevuto sull'app Telegram.

Cliccare "API development tools" e compilare il form:
  App title: mt5bot (o qualsiasi nome)
  Short name: mt5bot
  Platform: Other
  Description: lasciare vuoto

Cliccare "Create application".

Annotare i valori mostrati:
  api_id:   numero intero 
  api_hash: stringa esadecimale

Questi valori vengono richiesti dallo script di setup.


1.6 TELEGRAM - ID DEL GRUPPO
------------------------------
Lo script ha bisogno dell'ID numerico del canale TheRealFX Signals,
non del nome testuale, perche' il nome puo' cambiare.

Il modo piu' semplice per trovarlo:
  Aprire Telegram Web (https://web.telegram.org)
  Aprire il canale di cui vogliamo eseguire i segnali
  Guardare l'URL nella barra del browser: contiene un numero tipo -1003746867737
  Quell'e' l'ID del gruppo, incluso il segno meno.

In alternativa, dopo aver completato il setup e avviato Python per la prima volta,
il log mostra automaticamente l'ID del canale trovato.


1.7 CREDENZIALI MT5 BROKER
---------------------------------
Tenere a portata di mano:
  - Numero account del broker
  - Password account MT5
  - Nome server

Queste credenziali vengono richieste dallo script di setup per configurare
il login automatico di MT5 senza dover usare il mouse via VNC.


========================================
PARTE 2 - SETUP
========================================


2.1 COPIA DEI FILE SULLA VPS
------------------------------
Dalla cartella locale che contiene tutti i file del pacchetto,
aprire un terminale ed eseguire:

  scp -i prkey.key \
    mt5setup.exe \
    VC_redist_x64.exe \
    TelegramSignalEA.mq5 \
    telegram_signal_reader.py \
    setup_vps.sh \
    ubuntu@IP_DELLA_VPS:~/

Sostituire IP_DELLA_VPS con l'IP della propria istanza Oracle.
Attendere il completamento del trasferimento.


2.2 AVVIO DELLO SCRIPT DI SETUP
---------------------------------
Connettersi alla VPS via SSH:

  ssh -i prkey.key ubuntu@IP_DELLA_VPS

Rendere lo script eseguibile e avviarlo:

  chmod +x setup_vps.sh
  sudo bash setup_vps.sh

Lo script richiede di essere eseguito come root (sudo).


2.3 COSA SUCCEDE DURANTE IL SETUP - PASSO PER PASSO
-----------------------------------------------------
Lo script si ferma subito a chiedere le credenziali. Inserire:

  TELEGRAM_API_ID--------------	il numero api_id ottenuto in 1.5
  TELEGRAM_API_HASH--------	la stringa api_hash ottenuta in 1.5
  TELEGRAM_PHONE-------------	il numero di telefono con prefisso internazionale 
  TELEGRAM_GROUP-------------	l'ID numerico del canale ottenuto in 1.6 
  MT5 Login-------------------------	il numero account ActivTrades
  MT5 Password-------------------	la password MT5 
  MT5 Server------------------------	il nome del server

Dopo aver inserito le credenziali lo script procede automaticamente con:

  [0/9] Swap
  Crea un file swap da 2 GB. Necessario perche' Wine e MT5 insieme
  consumano piu' della RAM disponibile senza swap.
  Durata: pochi secondi.

  [1/9] Dipendenze base
  Installa wget, curl, Python, Xvfb, x11vnc e altri strumenti di sistema.
  Durata: 1-2 minuti.

  [2/9] Wine 9
  Aggiunge il repository ufficiale WineHQ e installa Wine 9.
  La versione viene bloccata per evitare aggiornamenti accidentali.
  Durata: 3-5 minuti.

  [3/9] Winetricks
  Scarica lo script winetricks, usato per installare le librerie Windows.
  Durata: pochi secondi.

  [4/9] Display virtuale
  Avvia Xvfb, il display virtuale su cui girera' MT5.
  Nessuna finestra reale viene mostrata, tutto e' in memoria.
  Durata: pochi secondi.

  [5/9] Wine prefix
  Inizializza l'ambiente Windows virtuale in ~/.wine_mt5.
  E' l'equivalente di una installazione Windows pulita dentro Linux.
  Durata: 5-10 minuti. Possono apparire messaggi di dialogo Wine
  (Mono, Gecko) - vengono gestiti automaticamente.

  [6/9] Dipendenze MT5
  Installa Microsoft Visual C++ Runtime (VC_redist_x64.exe) e i font
  Windows di base (corefonts) necessari per MT5.
  Durata: 2-3 minuti.

  [7/9] MetaTrader 5
  Installa MT5 dentro il prefix Wine usando mt5setup.exe.
  Durata: 2-5 minuti.

  [7b] Primo avvio MT5
  Avvia MT5 con le credenziali inserite per effettuare il primo login
  e creare le cartelle necessarie (inclusa Common/Files dove viene
  scritto il file segnale).
  Durata: 30 secondi di attesa.
  Nota: se il login fallisce (password errata, server sbagliato) questo
  passo completa comunque, ma MT5 non sara' connesso. Verificare le
  credenziali e rilanciare manualmente MT5 in seguito.

  [7c] EA TelegramSignalEA
  Copia TelegramSignalEA.mq5 nella cartella Experts di MT5 e lo
  compila con MetaEditor in modalita' headless.
  Il file .ex5 compilato viene creato automaticamente.
  Durata: 20 secondi.

  [8/9] Python e Telethon
  Crea un ambiente virtuale Python in /opt/telegram_mt5/venv,
  installa Telethon e python-dotenv, copia telegram_signal_reader.py
  e crea il file .env con le credenziali inserite in precedenza.
  Durata: 1-2 minuti.

  [9/9] Servizi systemd
  Crea e abilita due servizi che si avviano automaticamente al boot:
    trfx-mt5      avvia MT5 con Wine
    trfx-signal   avvia il lettore segnali Python
  Crea anche /usr/local/bin/start_mt5.sh per l'avvio manuale con VNC.
  Durata: pochi secondi.

Al termine lo script stampa un riepilogo con i comandi utili.


2.4 PRIMO AVVIO DOPO IL SETUP
-------------------------------
Al termine dello script, seguire questi passi nell'ordine:

PASSO A - Aprire MT5 con VNC e caricare l'EA

  Avviare MT5 con VNC:
    sudo start_mt5.sh

  Connettersi con un client VNC (es. RealVNC Viewer, TigerVNC):
    Host:     IP_DELLA_VPS:5900
    Password: mt5vnc

  In MT5:
    1. Verificare che sia connesso al server (barra verde in basso a destra)
    2. Aprire un chart EURUSD (o qualsiasi coppia)
    3. Nel pannello Navigator a sinistra, trovare Expert Advisors >
       TelegramSignalEA e trascinarlo sul chart
    4. Nel pannello parametri lasciare i valori di default e cliccare OK
    5. Abilitare il trading algoritmico: cliccare il bottone "Algo Trading"
       nella barra degli strumenti in alto (diventa verde quando e' attivo)
    6. Nel tab "Experts" in basso verificare che compaia:
       [TGSCHEAEA v4] Avviato
       [TGSCHEAEA v4] Common Files path: C:\users\ubuntu\AppData\...

PASSO B - Prima sessione Telegram

  Il primo avvio di Python richiede autenticazione con codice OTP.
  Eseguire manualmente:

    cd /opt/telegram_mt5
    source venv/bin/activate
    python telegram_signal_reader.py

  Telegram invia un codice sul telefono (o sull'app Telegram).
  Inserire il codice quando richiesto.
  Se richiesta la password 2FA, inserirla.

  Quando compare "In ascolto..." la sessione e' autenticata.
  Fermare con CTRL+C.

PASSO C - Avviare i servizi

  Avviare i servizi systemd:

    sudo systemctl start tgschea-mt5
    sudo systemctl start tgschea-signal

  Verificare lo stato:

    sudo systemctl status tgschea-signal
    sudo journalctl -u tgschea-signal -f


2.5 VERIFICA CHE TUTTO FUNZIONI
---------------------------------
Con i servizi attivi e MT5 connesso, inviare un messaggio di test
sul canale Telegram (o direttamente nel gruppo se si ha i permessi).

In alternativa scrivere manualmente un segnale di test nel file:

  python3 -c "
  content = '{\"action\":\"SELL\",\"symbol\":\"EURUSD\",\"order_type\":\"LIMIT\",\"price\":1.17,\"sl\":1.20,\"tp\":1.10,\"lot\":0.01,\"timestamp\":\"2026-06-16 12:00:00\",\"processed\":false}'
  with open('/home/ubuntu/.wine_mt5/drive_c/users/ubuntu/AppData/Roaming/MetaQuotes/Terminal/Common/Files/signal.txt', 'w', encoding='utf-16-le') as f:
      f.write(content)
  "

Nel tab Experts di MT5 deve comparire entro 1 secondo:
  [TGSCHEA v4] Segnale: SELL EURUSD (LIMIT) P=1.17 SL=1.2 TP=1.1 Lot=0.01


========================================
PARTE 3 - COMANDI UTILI
========================================

Connessione SSH:
  ssh -i prkey.key ubuntu@IP_DELLA_VPS

Avvio MT5 con VNC (per accesso visivo):
  sudo start_mt5.sh
  VNC: IP_DELLA_VPS:5900  password: mt5vnc

Stato servizi:
  sudo systemctl status tgschea-mt5
  sudo systemctl status tgschea-signal

Log Python in tempo reale:
  sudo journalctl -u tgschea-signal -f

Riavvio servizi:
  sudo systemctl restart tgschea-mt5
  sudo systemctl restart tgschea-signal

Modifica credenziali Telegram:
  sudo nano /opt/telegram_mt5/.env

Riavvio VNC se la schermata diventa nera:
  sudo pkill x11vnc
  sleep 1
  sudo x11vnc -display :99 -passwd mt5vnc -forever -rfbport 5900 -nolookup -bg


========================================
PARTE 4 - NOTE E LIMITAZIONI
========================================

RIAVVIO VPS
I servizi systemd si avviano automaticamente al riavvio della VPS.
MT5 si riconnette automaticamente ad ActivTrades.
Il display virtuale Xvfb viene avviato come dipendenza del servizio MT5.
Non e' necessario nessun intervento manuale dopo un riavvio.

MERCATO CHIUSO
I segnali Telegram arrivano solo nei giorni feriali.
MT5 resta connesso anche nel weekend, gli ordini pendenti rimangono attivi.

ACCOUNT DEMO VS LIVE
Il setup funziona identicamente su account demo e live.
Cambiare il server in .env e nel servizio systemd per passare da uno all'altro.

AGGIORNAMENTI MT5
MT5 potrebbe proporre aggiornamenti automatici.
Se MT5 si aggiorna e smette di funzionare, riavviare il servizio tgschea-mt5.
In casi estremi ripetere il setup dall'istruzione [7/9].

FILE SEGNALE
Il file di comunicazione tra Python e MT5 si trova in:
  /home/ubuntu/.wine_mt5/drive_c/users/ubuntu/AppData/Roaming/MetaQuotes/Terminal/Common/Files/signal.txt

Deve essere scritto in UTF-16LE senza spazi nel JSON.
Questo viene gestito automaticamente da telegram_signal_reader.py.

LOG PYTHON
I log del lettore segnali si trovano in:
  /opt/telegram_mt5/bot_log.txt

Utile per verificare quali messaggi Telegram vengono ricevuti e parsati.
