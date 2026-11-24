// Tests of the standalone page's category migration and chain rules, without a browser or dependencies.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('index.html', 'utf8');
const names = ['validChainIds', 'chainRoot', 'chainOperational', 'multipleClose', 'resolveChain', 'decorateChains', 'needsReview', 'newOrderKind', 'legacyTarget', 'convertLegacy'];
const functions = names.map(name => {
  const line = html.split('\n').find(line => line.startsWith(`function ${name}(`));
  assert.ok(line, `Missing function ${name}`);
  return line;
}).join('\n');
const context = vm.createContext({});
vm.runInContext(`const LEGACY_CATS=['newop','updateop','closeop','opening'];\n${functions}\nglobalThis.api={${names.join(',')}};`, context);
const api = context.api;
const plain = value => JSON.parse(JSON.stringify(value));
const record = (position, telegramId, category, text, replyToId = null) => ({position, telegramId, categories:[category], text, replyToId});

test('migrate clear legacy actions while retaining uncertain categories and provenance', () => {
  const input = [
    record(1, 101, 'newop', '📉SELL LIMIT EUR/USD Prezzo 1.10000'),
    record(2, 102, 'updateop', '(SELL LIMIT EUR/USD) - MODIFICARE IL PREZZO DI INGRESSO DA 1.10000 A 1.10100', 101),
    record(3, 103, 'opening', 'Ordine Sell EUR/USD Aperto Livello di ingresso 1.10100', 102),
    record(4, 104, 'updateop', 'STOP LOSS EUR/USD (1.10100)', 103),
    record(5, 105, 'newop', "ATTENZIONE QUESTA E' UNA OPERAZIONE IN BUY DIRETTA A MERCATO:\nBUY GBP/USD"),
    record(6, 106, 'closeop', 'GBP/USD CHIUDERE MANUALMENTE UNA POSIZIONE'),
    record(7, 107, 'updateop', 'ANNULLARE SELL LIMIT GBP/USD (1.2)'),
    record(8, 108, 'updateop', 'STOP LOSS GBP/USD (1.2)'),
    record(9, 109, 'opening', 'Ordine Sell GBP/USD Aperto Livello di ingresso 1.2'),
  ];
  const output = api.convertLegacy(input);
  assert.deepEqual(plain(output.map(m => m.categories)), [['neword'],['updord'],['openord'],['warning'],['newpos'],['clspos'],['clsord'],['updateop'],['opening']]);
  assert.deepEqual(plain(output[3].legacyCategories), ['updateop']);
  assert.equal(output[3].replyToId, 103);
  assert.equal(api.needsReview(output[7]), true);
  assert.equal(api.needsReview(output[8]), true);
  assert.deepEqual(plain(api.convertLegacy(output)), plain(output));
});

test('chains follow responses, preserve multiple roots and do not guess missing references', () => {
  const records = [
    record(1, 101, 'neword', 'SELL LIMIT'),
    record(2, 102, 'updord', 'modifica', 101),
    record(3, 103, 'openord', 'aperto', 102),
    record(4, 104, 'warning', 'stop loss', 103),
    record(5, 105, 'newpos', 'BUY a mercato'),
    record(6, 106, 'clspos', 'CHIUDERE MANUALMENTE DUE POSIZIONI', 103),
    record(7, 107, 'clspos', 'CHIUDERE MANUALMENTE DUE POSIZIONI'),
  ];
  let result = api.decorateChains(records);
  assert.equal(result[0].chainStatus, 'root');
  assert.equal(result[3].chainId, 101);
  assert.equal(result[3].chainStatus, 'reply');
  assert.equal(result[5].chainId, 101);
  assert.equal(result[5].chainStatus, 'partial');
  assert.equal(result[6].chainStatus, 'unresolved');
  records[6].manualChainIds = [101, 105];
  result = api.decorateChains(records);
  assert.deepEqual(plain(result[6].chainIds), [101, 105]);
  assert.equal(result[6].chainId, null);
  assert.equal(result[6].chainStatus, 'manual');
  records[0].categories = ['trash'];
  result = api.decorateChains(records);
  assert.equal(result[3].chainStatus, 'unresolved');
  assert.equal(result[6].chainStatus, 'unresolved');
});

test('filtered snapshots retain known external references without claiming a verified local link', () => {
  const records = [record(1, 101, 'neword', 'SELL LIMIT'), record(2, 102, 'openord', 'aperto', 101), record(3, 103, 'warning', 'stop', 102)];
  const full = api.decorateChains(records);
  const filtered = full.slice(1).map((m, i) => ({...m, position:i+1}));
  const result = api.decorateChains(filtered);
  assert.equal(result[1].chainId, 101);
  assert.equal(result[1].chainStatus, 'external');
});
