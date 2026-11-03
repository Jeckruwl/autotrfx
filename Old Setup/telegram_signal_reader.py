"""
Telegram Signal Reader — TheRealFX Signals  (v4)
"""

import os, re, sys, json, logging
from datetime import datetime
from dotenv import load_dotenv
from telethon import TelegramClient, events

load_dotenv("/opt/telegram_mt5/.env")

API_ID       = os.getenv("TELEGRAM_API_ID")
API_HASH     = os.getenv("TELEGRAM_API_HASH")
PHONE        = os.getenv("TELEGRAM_PHONE")
TARGET_GROUP = os.getenv("TELEGRAM_GROUP")
SIGNAL_FILE  = os.getenv("SIGNAL_FILE", "/opt/trfx/signal.txt")
LOG_FILE     = "/opt/telegram_mt5/bot_log.txt"
SESSION      = "/opt/telegram_mt5/trfx_session"

if not API_ID or not API_HASH or not PHONE:
    print("ERRORE: compila /opt/telegram_mt5/.env")
    sys.exit(1)
if not TARGET_GROUP:
    print("ERRORE: compila TELEGRAM_GROUP in .env")
    sys.exit(1)

API_ID = int(API_ID)

def parse_group(g):
    g = g.strip()
    try:
        return int(g)
    except ValueError:
        return g

os.makedirs(os.path.dirname(SIGNAL_FILE), exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

client = TelegramClient(SESSION, API_ID, API_HASH)

# ── Messaggi da ignorare ─────────────────────────────────────────────────────
# ATTENZIONE: questi pattern vengono controllati SOLO se il messaggio NON
# contiene segnali operativi (BUY/SELL/CHIUDERE/ANNULLARE/MODIFICARE).
# Non usare pattern troppo generici che matchano anche messaggi con segnali.
IGNORE_PATTERNS = [
    # Conferme apertura ordini pendenti (messaggio automatico MT5/canale)
    r"ORDINE\s+(BUY|SELL)\b.{0,30}APERTO",
    r"LIVELLO DI INGRESSO\s+[0-9]",
    r"APERTURA DEL PENDING",
    # Messaggi puramente informativi senza segnali
    r"BUON FINE SETTIMANA",
    r"STAY TUNED",
    r"TOTALE IN PROFITTO",
    r"MYFXBOOK",
    r"UN ABBRACCIO A TUTTI",
    r"RICORDIAMO CHE LE OPERAZIONI",
]

def is_ignored(text):
    """Controlla solo messaggi che NON contengono segnali operativi."""
    # Se contiene parole chiave operative non ignorare MAI
    if re.search(r"\b(BUY|SELL|CHIUDERE|ANNULLARE|MODIFICARE)\b", text):
        return False
    # Altrimenti controlla i pattern
    for p in IGNORE_PATTERNS:
        if re.search(p, text):
            return True
    return False

def clean_text(text):
    text = text.replace('\xa0', ' ')
    text = re.sub(r"[^\x00-\x7F\u00C0-\u024F]+", " ", text)
    text = re.sub(r"(\d)\s*\.\s*(\d)", r"\1.\2", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text.upper()

def extract_symbol(text):
    m = re.search(r"\b([A-Z]{3})[/ ]([A-Z]{3})\b", text)
    if m:
        return m.group(1) + m.group(2)
    m = re.search(
        r"\b(EURUSD|GBPUSD|USDJPY|XAUUSD|USDCHF|AUDUSD|USDCAD"
        r"|NZDUSD|GBPJPY|EURJPY|EURGBP|AUDJPY|CHFJPY|CADJPY)\b", text)
    return m.group(1) if m else None

def extract_price(text, label):
    m = re.search(re.escape(label) + r"[^\d]{0,20}?([0-9]+\.[0-9]+)", text)
    return float(m.group(1)) if m else 0.0

def parse_signal(raw_text):
    text = clean_text(raw_text)

    if is_ignored(text):
        return None

    symbol = extract_symbol(text)

    if "CHIUDERE" in text and ("MANUALMENTE" in text or "POSIZIONE" in text):
        if not symbol: return None
        entry_prices = [float(p) for p in re.findall(r"\(([0-9]+\.[0-9]+)\+?\)", text)]
        return {"action": "CLOSE", "symbol": symbol, "order_type": "MARKET",
                "entry_prices": entry_prices,
                "price": entry_prices[0] if entry_prices else 0.0,
                "sl": 0.0, "tp": 0.0, "lot": 0.0}

    if "ANNULLARE" in text:
        if not symbol: return None
        return {"action": "CANCEL", "symbol": symbol, "order_type": "LIMIT",
                "price": 0.0, "sl": 0.0, "tp": 0.0, "lot": 0.0}

    if "MODIFICARE" in text and "INGRESSO" in text:
        if not symbol: return None
        m = re.search(r"DA\s+([0-9]+\.[0-9]+)\s+A\s+([0-9]+\.[0-9]+)", text)
        new_price = float(m.group(2)) if m else 0.0
        return {"action": "MODIFY", "symbol": symbol, "order_type": "LIMIT",
                "price": new_price, "sl": 0.0, "tp": 0.0, "lot": 0.0}

    m_limit = re.search(r"\b(BUY|SELL)\s+LIMIT\b", text)
    if m_limit:
        if not symbol: return None
        return {"action": m_limit.group(1), "symbol": symbol,
                "order_type": "LIMIT",
                "price": extract_price(text, "PREZZO"),
                "sl":    extract_price(text, "STOP LOSS"),
                "tp":    extract_price(text, "TAKE PROFIT"),
                "lot": 0.01}

    m_market = re.search(r"\b(BUY|SELL)\b", text)
    if m_market:
        if not symbol: return None
        return {"action": m_market.group(1), "symbol": symbol,
                "order_type": "MARKET",
                "price": 0.0,
                "sl":    extract_price(text, "STOP LOSS"),
                "tp":    extract_price(text, "TAKE PROFIT"),
                "lot": 0.01}

    return None

def write_signal(signal):
    signal["timestamp"] = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    signal["processed"] = False
    try:
        with open(SIGNAL_FILE, "w", encoding="utf-16-le") as f:
            json.dump(signal, f, separators=(',', ':'))
        logger.info(f"Segnale scritto -> {signal}")
    except Exception as e:
        logger.error(f"Errore scrittura: {e}")

async def main():
    logger.info("=== TheRealFX Signal Reader v4 ===")
    await client.start(phone=PHONE)
    logger.info("Login Telegram effettuato.")

    group = parse_group(TARGET_GROUP)
    logger.info(f"Connessione al gruppo: {group}")

    try:
        entity = await client.get_entity(group)
        logger.info(f"Canale trovato: {entity.title} (ID: {entity.id})")
    except Exception as e:
        logger.error(f"Canale non trovato: {e}")
        return

    @client.on(events.NewMessage(chats=entity.id))
    async def handler(event):
        text = event.message.message or ""
        if not text.strip():
            return
        logger.info(f"Messaggio ricevuto ({len(text)} chars)")
        signal = parse_signal(text)
        if signal:
            logger.info(f"SEGNALE -> {signal['action']} {signal['symbol']} "
                        f"({signal['order_type']}) P={signal['price']} "
                        f"SL={signal['sl']} TP={signal['tp']}")
            write_signal(signal)
        else:
            logger.debug("Ignorato")

    logger.info("In ascolto... Premi CTRL+C per fermare.")
    await client.run_until_disconnected()

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
