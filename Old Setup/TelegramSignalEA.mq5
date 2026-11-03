//+------------------------------------------------------------------+
//|  TelegramSignalEA.mq5  —  TheRealFX Signals  (v4 — finale)     |
//|                                                                  |
//|  PERCORSO FILE SEGNALE:                                          |
//|  Usa FILE_COMMON di MT5.                                         |
//|  Python deve scrivere in UTF-16LE senza spazi nel JSON.         |
//|  Il percorso reale viene stampato all'avvio nel tab Experts.    |
//|                                                                  |
//|  Gestisce: BUY/SELL market, BUY/SELL LIMIT,                    |
//|            CLOSE (per prezzo ingresso), CANCEL, MODIFY           |
//+------------------------------------------------------------------+
#property copyright "TelegramSignalEA v4"
#property version   "4.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Parametri input
input string   SignalFilePath  = "signal.txt";  // Nome file segnale (Common Files MT5)
input double   DefaultLotSize  = 0.01;          // Lotto default
input int      MagicNumber     = 20250601;       // Magic number
input int      Slippage        = 10;             // Slippage punti
input int      CheckIntervalMs = 1000;           // Controllo ogni N ms
input bool     EnableAlerts    = true;           // Alert visivi MT5

//--- Oggetti Trade
CTrade        trade;
CPositionInfo posInfo;
COrderInfo    ordInfo;

//--- Stato
string lastTimestamp = "";

//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(Slippage);
    trade.SetTypeFilling(ORDER_FILLING_IOC);
    EventSetMillisecondTimer(CheckIntervalMs);
    Print("[TGSCHEA] Avviato — file: ", SignalFilePath);
    Print("[TGSCHEA] Common Files path: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH));
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) { EventKillTimer(); }
void OnTick() {}

//+------------------------------------------------------------------+
//| Timer — controlla il file ogni secondo                           |
//+------------------------------------------------------------------+
void OnTimer()
{
    if (!FileIsExist(SignalFilePath, FILE_COMMON)) return;

    int h = FileOpen(SignalFilePath,
                     FILE_READ | FILE_TXT | FILE_COMMON,
                     '\n', CP_UTF8);
    if (h == INVALID_HANDLE) return;

    string content = "";
    while (!FileIsEnding(h))
        content += FileReadString(h);
    FileClose(h);

    if (StringLen(content) < 5) return;

    string processed = JsonStr(content, "processed");
    string timestamp = JsonStr(content, "timestamp");
    if (processed == "true" || timestamp == lastTimestamp) return;

    string action     = JsonStr(content, "action");
    string symbol     = JsonStr(content, "symbol");
    string order_type = JsonStr(content, "order_type");
    double price      = JsonDbl(content, "price");
    double sl         = JsonDbl(content, "sl");
    double tp         = JsonDbl(content, "tp");
    double lot        = JsonDbl(content, "lot");
    if (lot < 0.01) lot = DefaultLotSize;

    lastTimestamp = timestamp;
    MarkProcessed();

    Print("[TGSCHEA] Segnale: ", action, " ", symbol,
          " (", order_type, ") P=", price, " SL=", sl, " TP=", tp, " Lot=", lot);

    if (!SymbolSelect(symbol, true))
    {
        Print("[TGSCHEA] ERRORE: simbolo non trovato -> ", symbol);
        return;
    }

    if      (action == "BUY"    && order_type == "MARKET") DoMarketOrder(symbol, ORDER_TYPE_BUY,        sl, tp, lot);
    else if (action == "SELL"   && order_type == "MARKET") DoMarketOrder(symbol, ORDER_TYPE_SELL,       sl, tp, lot);
    else if (action == "BUY"    && order_type == "LIMIT")  DoPendingOrder(symbol, ORDER_TYPE_BUY_LIMIT,  price, sl, tp, lot);
    else if (action == "SELL"   && order_type == "LIMIT")  DoPendingOrder(symbol, ORDER_TYPE_SELL_LIMIT, price, sl, tp, lot);
    else if (action == "CLOSE")  DoClose(symbol, content);
    else if (action == "CANCEL") DoCancel(symbol);
    else if (action == "MODIFY") DoModify(symbol, price);
    else Print("[TGSCHEA] Azione non riconosciuta: ", action);
}

//+------------------------------------------------------------------+
void DoMarketOrder(string symbol, ENUM_ORDER_TYPE type, double sl, double tp, double lot)
{
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    sl = NormalizeDouble(sl, digits);
    tp = NormalizeDouble(tp, digits);

    bool ok; string dir;
    if (type == ORDER_TYPE_BUY)
    {
        ok  = trade.Buy(lot, symbol, SymbolInfoDouble(symbol, SYMBOL_ASK), sl, tp, "TRFX_MKT");
        dir = "BUY";
    }
    else
    {
        ok  = trade.Sell(lot, symbol, SymbolInfoDouble(symbol, SYMBOL_BID), sl, tp, "TRFX_MKT");
        dir = "SELL";
    }

    if (ok) { Print("[TGSCHEA] ", dir, " aperto. Ticket: ", trade.ResultOrder());
               if (EnableAlerts) Alert("TRFX: ", dir, " ", symbol, " aperto"); }
    else      Print("[TGSCHEA] ERRORE ", dir, ": ", trade.ResultRetcode(),
                    " - ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
void DoPendingOrder(string symbol, ENUM_ORDER_TYPE type, double price,
                    double sl, double tp, double lot)
{
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    price = NormalizeDouble(price, digits);
    sl    = NormalizeDouble(sl,    digits);
    tp    = NormalizeDouble(tp,    digits);

    bool ok = trade.OrderOpen(symbol, type, lot, 0, price, sl, tp,
                               ORDER_TIME_GTC, 0, "TRFX_LMT");
    string dir = (type == ORDER_TYPE_BUY_LIMIT) ? "BUY LIMIT" : "SELL LIMIT";

    if (ok) { Print("[TGSCHEA] ", dir, " @ ", price, " ticket: ", trade.ResultOrder());
               if (EnableAlerts) Alert("TRFX: ", dir, " ", symbol, " @ ", price); }
    else      Print("[TGSCHEA] ERRORE ", dir, ": ", trade.ResultRetcode(),
                    " - ", trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
void DoClose(string symbol, const string jsonContent)
{
    double entryPrices[];
    int count = JsonDblArray(jsonContent, "entry_prices", entryPrices);

    int    digits    = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double tolerance = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;

    int n = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (!posInfo.SelectByIndex(i))       continue;
        if (posInfo.Symbol() != symbol)      continue;
        if (posInfo.Magic()  != MagicNumber) continue;

        bool shouldClose = (count == 0);
        if (!shouldClose)
            for (int k = 0; k < count; k++)
                if (MathAbs(posInfo.PriceOpen() - entryPrices[k]) <= tolerance)
                    { shouldClose = true; break; }

        if (shouldClose && trade.PositionClose(posInfo.Ticket()))
        {
            Print("[TGSCHEA] Chiusa pos. ticket=", posInfo.Ticket(),
                  " aperta @ ", DoubleToString(posInfo.PriceOpen(), digits));
            n++;
        }
    }
    Print("[TGSCHEA] Chiuse ", n, " posizioni su ", symbol);
    if (EnableAlerts && n > 0) Alert("TRFX: chiuse ", n, " pos. ", symbol);
}

//+------------------------------------------------------------------+
void DoCancel(string symbol)
{
    int n = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
        if (ordInfo.SelectByIndex(i) && ordInfo.Symbol() == symbol
            && ordInfo.Magic() == MagicNumber)
            if (trade.OrderDelete(ordInfo.Ticket())) n++;

    Print("[TGSCHEA] Cancellati ", n, " ordini pendenti su ", symbol);
    if (EnableAlerts && n > 0) Alert("TRFX: cancellati ", n, " ordini ", symbol);
}

//+------------------------------------------------------------------+
void DoModify(string symbol, double newPrice)
{
    if (newPrice <= 0) { Print("[TGSCHEA] MODIFY: prezzo non valido"); return; }
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    newPrice = NormalizeDouble(newPrice, digits);

    int n = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
        if (ordInfo.SelectByIndex(i) && ordInfo.Symbol() == symbol
            && ordInfo.Magic() == MagicNumber)
            if (trade.OrderModify(ordInfo.Ticket(), newPrice,
                                   ordInfo.StopLoss(), ordInfo.TakeProfit(),
                                   ORDER_TIME_GTC, 0)) n++;

    Print("[TGSCHEA] Modificati ", n, " ordini su ", symbol, " → ", newPrice);
    if (EnableAlerts && n > 0) Alert("TRFX: ordine ", symbol, " modificato @ ", newPrice);
}

//+------------------------------------------------------------------+
void MarkProcessed()
{
    int h = FileOpen(SignalFilePath, FILE_WRITE | FILE_TXT | FILE_COMMON, '\n', CP_UTF8);
    if (h != INVALID_HANDLE)
    {
        FileWriteString(h, "{\"processed\":true,\"timestamp\":\"done\"}");
        FileClose(h);
    }
}

//+------------------------------------------------------------------+
string JsonStr(const string j, const string key)
{
    string pat = "\"" + key + "\":\"";
    int s = StringFind(j, pat);
    if (s < 0) return "";
    s += StringLen(pat);
    int e = StringFind(j, "\"", s);
    if (e < 0) return "";
    return StringSubstr(j, s, e - s);
}

double JsonDbl(const string j, const string key)
{
    string pat = "\"" + key + "\":";
    int s = StringFind(j, pat);
    if (s < 0) return 0.0;
    s += StringLen(pat);
    while (s < StringLen(j) && StringGetCharacter(j, s) == ' ') s++;
    int e = s;
    while (e < StringLen(j))
    {
        ushort c = StringGetCharacter(j, e);
        if (c == ',' || c == '}') break;
        e++;
    }
    return StringToDouble(StringSubstr(j, s, e - s));
}

int JsonDblArray(const string j, const string key, double &out[])
{
    ArrayResize(out, 0);
    string pat = "\"" + key + "\":[";
    int s = StringFind(j, pat);
    if (s < 0) return 0;
    s += StringLen(pat);
    int end = StringFind(j, "]", s);
    if (end < 0) return 0;
    string inner = StringSubstr(j, s, end - s);
    StringTrimLeft(inner); StringTrimRight(inner);
    if (StringLen(inner) == 0) return 0;

    int count = 0, pos = 0;
    while (pos <= StringLen(inner))
    {
        int comma = StringFind(inner, ",", pos);
        if (comma < 0) comma = StringLen(inner);
        string token = StringSubstr(inner, pos, comma - pos);
        StringTrimLeft(token); StringTrimRight(token);
        if (StringLen(token) > 0)
        {
            double val = StringToDouble(token);
            if (val > 0) { ArrayResize(out, count + 1); out[count++] = val; }
        }
        pos = comma + 1;
    }
    return count;
}
//+------------------------------------------------------------------+
