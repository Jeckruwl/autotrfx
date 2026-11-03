#!/bin/bash
# =============================================================
#  SETUP COMPLETO VPS - Ubuntu 22.04 - TGSCHEA Bot
#  v9 - Setup completo dalla VPS, file copiati in precedenza
#       Wine 9, MT5 headless, Python UTF-16LE, systemd
# =============================================================
set -e

VPS_USER="ubuntu"
VPS_HOME="/home/ubuntu"
WINE_PREFIX="$VPS_HOME/.wine_mt5"
WINE_VERSION="9.0.0.0~jammy-1"
MT5_DIR="$WINE_PREFIX/drive_c/Program Files/MetaTrader 5"
COMMON_FILES="$VPS_HOME/.wine_mt5/drive_c/users/ubuntu/AppData/Roaming/MetaQuotes/Terminal/Common/Files"
SIGNAL_FILE="$COMMON_FILES/signal.txt"
OPT_DIR="/opt/telegram_mt5"

echo "========================================"
echo "  SETUP VPS v9 - TGSCHEA Bot"
echo "========================================"

# --------------------------------------------------------------
# CREDENZIALI TELEGRAM (chiede all'utente)
# --------------------------------------------------------------
echo ""
echo "=== Credenziali Telegram ==="
echo "Ottienile da https://my.telegram.org/apps"
echo ""
read -p "TELEGRAM_API_ID: " TG_API_ID
read -p "TELEGRAM_API_HASH: " TG_API_HASH
read -p "TELEGRAM_PHONE (es. +393401234567): " TG_PHONE
read -p "TELEGRAM_GROUP (ID numerico es. -1003746867737): " TG_GROUP
echo ""
echo "Credenziali salvate."

# --------------------------------------------------------------
# CREDENZIALI MT5 (per login headless)
# --------------------------------------------------------------
echo ""
echo "=== Credenziali MT5 ActivTrades ==="
read -p "MT5 Login (numero account): " MT5_LOGIN
read -s -p "MT5 Password: " MT5_PASSWORD
echo ""
read -p "MT5 Server (es. ActivTrades-Live): " MT5_SERVER
echo ""

# --------------------------------------------------------------
# 0. SWAP
# --------------------------------------------------------------
echo ""
echo "[0/9] Swap..."
if swapon --show | grep -q swapfile; then
    echo "SKIP - Swap già presente."
else
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "OK - Swap 2GB creata."
fi
free -h | grep -E "Mem|Swap"

# --------------------------------------------------------------
# 1. DIPENDENZE BASE
# --------------------------------------------------------------
echo ""
echo "[1/9] Dipendenze base..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget curl git unzip cabextract \
    python3 python3-pip python3-venv \
    xvfb x11vnc xterm x11-utils \
    software-properties-common \
    apt-transport-https \
    screen gnupg
echo "OK"

# --------------------------------------------------------------
# 2. WINE 9
# --------------------------------------------------------------
echo ""
echo "[2/9] Wine 9..."
CURRENT_WINE=$(wine64 --version 2>/dev/null || echo "none")
if echo "$CURRENT_WINE" | grep -q "wine-9"; then
    echo "SKIP - Wine 9 già installato ($CURRENT_WINE)."
    apt-mark hold winehq-stable wine-stable wine-stable-amd64 wine-stable-i386 2>/dev/null || true
else
    dpkg --add-architecture i386
    mkdir -pm755 /etc/apt/keyrings
    wget -O- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key
    [ ! -f /etc/apt/sources.list.d/winehq-jammy.sources ] && \
        wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades --install-recommends \
        winehq-stable=$WINE_VERSION \
        wine-stable=$WINE_VERSION \
        wine-stable-amd64=$WINE_VERSION \
        wine-stable-i386=$WINE_VERSION
    apt-mark hold winehq-stable wine-stable wine-stable-amd64 wine-stable-i386
    echo "OK - Wine 9 installato."
fi
wine64 --version

# --------------------------------------------------------------
# 3. WINETRICKS
# --------------------------------------------------------------
echo ""
echo "[3/9] Winetricks..."
if [ -x /usr/local/bin/winetricks ]; then
    echo "SKIP"
else
    wget -q -O /usr/local/bin/winetricks \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    chmod +x /usr/local/bin/winetricks
    echo "OK"
fi

# --------------------------------------------------------------
# 4. DISPLAY VIRTUALE
# --------------------------------------------------------------
echo ""
echo "[4/9] Display virtuale (Xvfb)..."
pkill Xvfb 2>/dev/null || true
sleep 1
Xvfb :99 -screen 0 1024x768x16 -nolisten tcp &
for i in $(seq 1 20); do
    DISPLAY=:99 xdpyinfo >/dev/null 2>&1 && echo "OK - Xvfb pronto." && break
    sleep 2
done

# --------------------------------------------------------------
# 5. WINE PREFIX
# --------------------------------------------------------------
echo ""
echo "[5/9] Wine prefix..."
if [ -f "$WINE_PREFIX/drive_c/windows/system32/kernel32.dll" ] && \
   file "$WINE_PREFIX/drive_c/windows/system32/kernel32.dll" | grep -q "x86-64"; then
    echo "SKIP - Prefix già ok."
else
    rm -rf "$WINE_PREFIX"
    sudo -u $VPS_USER \
        DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEARCH=win64 WINEDEBUG=-all \
        wine64 wineboot --init
    sudo -u $VPS_USER WINEPREFIX="$WINE_PREFIX" wineserver -w 2>/dev/null || true
    sleep 5
    echo "OK - Prefix creato."
fi

# --------------------------------------------------------------
# 6. VCRUNTIME + COREFONTS
# --------------------------------------------------------------
echo ""
echo "[6/9] Dipendenze MT5 (vcruntime + corefonts)..."
if [ -f "$WINE_PREFIX/drive_c/windows/system32/vcruntime140.dll" ]; then
    echo "SKIP - vcruntime già presente."
else
    if [ -f "$VPS_HOME/VC_redist_x64.exe" ]; then
        sudo -u $VPS_USER \
            DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all \
            wine64 "$VPS_HOME/VC_redist_x64.exe" /quiet /norestart
        sudo -u $VPS_USER WINEPREFIX="$WINE_PREFIX" wineserver -w 2>/dev/null || true
        echo "OK - vcruntime installato da file locale."
    else
        echo "WARN: VC_redist_x64.exe non trovato in $VPS_HOME, provo winetricks..."
        sudo -u $VPS_USER DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all \
            winetricks -q vcrun2019 || echo "WARN: vcruntime fallito (non bloccante)"
    fi
fi

sudo -u $VPS_USER DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all \
    winetricks -q corefonts || echo "WARN: corefonts fallito (non bloccante)"
sudo -u $VPS_USER WINEPREFIX="$WINE_PREFIX" wineserver -w 2>/dev/null || true

# --------------------------------------------------------------
# 7. MT5
# --------------------------------------------------------------
echo ""
echo "[7/9] MetaTrader 5..."
MT5_EXE="$MT5_DIR/terminal64.exe"

if [ -f "$MT5_EXE" ]; then
    echo "SKIP - MT5 già installato."
else
    if [ ! -f "$VPS_HOME/mt5setup.exe" ]; then
        echo "ERRORE: mt5setup.exe non trovato in $VPS_HOME"
        echo "Copialo con: scp mt5setup.exe ubuntu@VPS_IP:~/"
        exit 1
    fi
    echo "  Installazione MT5 (circa 2 minuti)..."
    sudo -u $VPS_USER \
        DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all \
        wine64 "$VPS_HOME/mt5setup.exe" /auto
    sudo -u $VPS_USER WINEPREFIX="$WINE_PREFIX" wineserver -w 2>/dev/null || true
    sleep 15
    chown -R $VPS_USER:$VPS_USER "$WINE_PREFIX"
    [ -f "$MT5_EXE" ] && echo "OK - MT5 installato." || echo "WARN: terminal64.exe non trovato nel path atteso."
fi

# --------------------------------------------------------------
# 7b. AVVIA MT5 PER LOGIN + CARTELLA Common Files
# --------------------------------------------------------------
echo ""
echo "[7b] Primo avvio MT5 (login ActivTrades)..."
# Avvia MT5 con credenziali — crea le cartelle Common Files
sudo -u $VPS_USER \
    DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all \
    wine64 "$MT5_EXE" /login:$MT5_LOGIN /password:$MT5_PASSWORD /server:$MT5_SERVER &
MT5_PID=$!
echo "  MT5 avviato (PID $MT5_PID), attendo 30 secondi per login..."
sleep 30

# Crea la cartella Common/Files se non esiste ancora
mkdir -p "$COMMON_FILES"
chown -R $VPS_USER:$VPS_USER "$(dirname $(dirname $(dirname $COMMON_FILES)))"
echo "OK - Common Files path: $COMMON_FILES"

# --------------------------------------------------------------
# 7c. COPIA E COMPILA EA
# --------------------------------------------------------------
echo ""
echo "[7c] EA TelegramSignalEA..."
EA_SRC="$VPS_HOME/TelegramSignalEA.mq5"
EA_DST="$MT5_DIR/MQL5/Experts/TelegramSignalEA.mq5"

if [ ! -f "$EA_SRC" ]; then
    echo "ERRORE: TelegramSignalEA.mq5 non trovato in $VPS_HOME"
    echo "Copialo con: scp TelegramSignalEA.mq5 ubuntu@VPS_IP:~/"
    exit 1
fi

cp "$EA_SRC" "$EA_DST"
chown $VPS_USER:$VPS_USER "$EA_DST"
echo "  EA copiato."

echo "  Compilazione EA con MetaEditor..."
sudo -u $VPS_USER \
    DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all \
    wine64 "$MT5_DIR/metaeditor64.exe" \
    /compile:"C:\\Program Files\\MetaTrader 5\\MQL5\\Experts\\TelegramSignalEA.mq5" \
    /log 2>/dev/null &
sleep 20

EA_EX5="$MT5_DIR/MQL5/Experts/TelegramSignalEA.ex5"
if [ -f "$EA_EX5" ]; then
    echo "OK - EA compilato: $EA_EX5"
else
    echo "WARN: .ex5 non trovato, potrebbe servire compilazione manuale da MetaEditor."
fi

# --------------------------------------------------------------
# 8. PYTHON + TELETHON
# --------------------------------------------------------------
echo ""
echo "[8/9] Python e Telethon..."
if [ ! -f "$OPT_DIR/venv/bin/python" ]; then
    mkdir -p "$OPT_DIR"
    python3 -m venv "$OPT_DIR/venv"
    "$OPT_DIR/venv/bin/pip" install --upgrade pip -q
    "$OPT_DIR/venv/bin/pip" install telethon python-dotenv -q
    echo "OK - Venv creato."
else
    echo "SKIP - Venv già presente."
fi

# Copia il signal reader
if [ -f "$VPS_HOME/telegram_signal_reader.py" ]; then
    cp "$VPS_HOME/telegram_signal_reader.py" "$OPT_DIR/telegram_signal_reader.py"
    echo "OK - telegram_signal_reader.py copiato."
else
    echo "ERRORE: telegram_signal_reader.py non trovato in $VPS_HOME"
    exit 1
fi

# Crea .env con le credenziali inserite
cat > "$OPT_DIR/.env" << EOF
TELEGRAM_API_ID=$TG_API_ID
TELEGRAM_API_HASH=$TG_API_HASH
TELEGRAM_PHONE=$TG_PHONE
TELEGRAM_GROUP=$TG_GROUP
SIGNAL_FILE=$SIGNAL_FILE
EOF
chown -R $VPS_USER:$VPS_USER "$OPT_DIR"
echo "OK - .env creato con SIGNAL_FILE=$SIGNAL_FILE"

# --------------------------------------------------------------
# 9. SYSTEMD
# --------------------------------------------------------------
echo ""
echo "[9/9] Servizi systemd..."

# Servizio Python
cat > /etc/systemd/system/tgschea-signal.service << EOF
[Unit]
Description=TGSCHEA Telegram Signal Reader
After=network.target

[Service]
User=$VPS_USER
WorkingDirectory=$OPT_DIR
ExecStart=$OPT_DIR/venv/bin/python telegram_signal_reader.py
Restart=always
RestartSec=10
EnvironmentFile=$OPT_DIR/.env

[Install]
WantedBy=multi-user.target
EOF

# Servizio MT5
cat > /etc/systemd/system/tgschea-mt5.service << EOF
[Unit]
Description=MetaTrader 5 via Wine
After=network.target

[Service]
User=$VPS_USER
Environment=DISPLAY=:99
Environment=WINEPREFIX=$WINE_PREFIX
Environment=WINEDEBUG=-all
ExecStartPre=/bin/bash -c 'Xvfb :99 -screen 0 1024x768x16 -nolisten tcp & sleep 3'
ExecStart=/usr/bin/wine64 "$MT5_EXE" /login:$MT5_LOGIN /password:$MT5_PASSWORD /server:$MT5_SERVER
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Script start_mt5.sh (per avvio manuale + VNC)
cat > /usr/local/bin/start_mt5.sh << EOF
#!/bin/bash
pkill Xvfb 2>/dev/null; pkill x11vnc 2>/dev/null; sleep 1
Xvfb :99 -screen 0 1024x768x16 -nolisten tcp &
sleep 3
x11vnc -display :99 -passwd mt5vnc -forever -bg -quiet -o /var/log/x11vnc.log
sleep 1
sudo -u $VPS_USER env DISPLAY=:99 WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all \
    wine64 "$MT5_EXE" /login:$MT5_LOGIN /password:$MT5_PASSWORD /server:$MT5_SERVER &
echo "MT5 avviato. VNC porta 5900 password: mt5vnc"
EOF
chmod +x /usr/local/bin/start_mt5.sh

systemctl daemon-reload
systemctl enable tgschea-signal
systemctl enable tgschea-mt5

echo ""
echo "========================================"
echo "  SETUP COMPLETATO!"
echo "========================================"
echo ""
echo "File segnale: $SIGNAL_FILE"
echo ""
echo "Comandi utili:"
echo "  sudo systemctl start tgschea-mt5       # Avvia MT5"
echo "  sudo systemctl start tgschea-signal    # Avvia Python"
echo "  sudo systemctl status tgschea-signal   # Stato Python"
echo "  sudo journalctl -u tgschea-signal -f   # Log Python live"
echo "  sudo start_mt5.sh                   # MT5 + VNC (debug)"
echo ""
echo "VNC (se usi start_mt5.sh):"
echo "  Host: $(curl -s ifconfig.me):5900"
echo "  Password: mt5vnc"
echo ""
echo "PASSO FINALE:"
echo "  1. Apri VNC e carica TelegramSignalEA sul chart EURUSD"
echo "  2. Abilita Algo Trading (bottone verde in alto)"
echo "  3. sudo systemctl start tgschea-signal"
echo "  4. Prima sessione Telegram richiede codice OTP sul telefono"
echo "========================================"
