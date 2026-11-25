// generate-deck.js — The Agent Mage deck generator + verifier.
// ---------------------------------------------------------------------------
// Usage (from this folder):
//   node generate-deck.js
// Writes: ../collection/deck.json
// Prints: seed, deckHash, verification results.
//
// THE DECK (same pattern as THYRK v2, adapted to 10,000 supply):
//   - Deck content = Fisher-Yates shuffle of token IDs 1..10,000,
//     built from seed "AGENTMAGE" (0x4147454e544d414745).
//     Shuffle randomness: for i = 9999..1, j = keccak256(seed || i) % (i+1).
//   - deckHash = keccak256 of the deck encoding: per token, 2 bytes
//     big-endian, in deck order (10,000 x 2 = 20,000 bytes).
//     This is the value stored in the contract as `deckHash`.
//   - The on-chain draw is a LAZY Fisher-Yates seeded by deckHash
//     (THYRK _drawMain): draw #d (0-based), remaining = 10000 - d,
//     j = keccak256(deckHash || d) % remaining, tokenId = valueAt(j),
//     then swap position j with position (remaining - 1).
//     The full draw order is replayed here and published in deck.json
//     as "drawOrder" so anyone can verify it without replaying.
//   - HONEST LIMITS (same as THYRK): deterministic pseudo-randomness
//     from a public seed — NOT VRF / provably fair randomness. Anyone
//     who knows the seed can compute the whole order in advance. The
//     deck is transparent, not secret.
// ---------------------------------------------------------------------------
const fs = require('fs');
const path = require('path');

let keccak256;
try {
  ({ keccak256 } = require('js-sha3'));
} catch (e) {
  try {
    ({ keccak256 } = require('./build/node_modules/js-sha3'));
  } catch (e2) {
    console.error('js-sha3 not found. Run: cd contract/build && npm install js-sha3');
    process.exit(1);
  }
}

const SUPPLY = 10000;
const SEED_TEXT = 'AGENTMAGE';
const SEED = Buffer.from(SEED_TEXT, 'ascii'); // 0x4147454e544d414745
const OUT = path.resolve(__dirname, '..', 'collection', 'deck.json');

// --- helpers ---------------------------------------------------------------
function keccakBigInt(bytes) {
  return BigInt('0x' + keccak256(bytes));
}
function u256be(n) {
  const b = Buffer.alloc(32);
  b.writeBigUInt64BE(BigInt(n), 24); // n < 2^64 for our uses (i, d < 10000)
  return b;
}

// --- 1. Fisher-Yates shuffle of 1..10000 from the seed ----------------------
const deck = Array.from({ length: SUPPLY }, (_, i) => i + 1);
for (let i = SUPPLY - 1; i >= 1; i--) {
  const j = Number(keccakBigInt(Buffer.concat([SEED, u256be(i)])) % BigInt(i + 1));
  const tmp = deck[i];
  deck[i] = deck[j];
  deck[j] = tmp;
}

// --- 2. deckHash = keccak256(deck encoding: 2 bytes BE per token) -----------
const encoding = Buffer.alloc(SUPPLY * 2);
deck.forEach((id, k) => encoding.writeUInt16BE(id, k * 2));
const deckHashHex = keccak256(encoding);
const deckHash = '0x' + deckHashHex;
const deckHashBytes = Buffer.from(deckHashHex, 'hex');

// --- 3. Replay the on-chain lazy Fisher-Yates draw --------------------------
function replayDraw() {
  const swapped = new Map(); // position -> tokenId (unset = identity i+1)
  const valueAt = (i) => (swapped.has(i) ? swapped.get(i) : i + 1);
  let remaining = SUPPLY;
  const order = [];
  for (let d = 0; d < SUPPLY; d++) {
    const j = Number(
      keccakBigInt(Buffer.concat([deckHashBytes, u256be(d)])) % BigInt(remaining)
    );
    const tokenId = valueAt(j);
    const last = valueAt(remaining - 1);
    if (j !== remaining - 1) swapped.set(j, last);
    remaining--;
    order.push(tokenId);
  }
  return order;
}
const drawOrder = replayDraw();

// --- 4. Verify ---------------------------------------------------------------
function isPermutation(arr) {
  if (arr.length !== SUPPLY) return false;
  const seen = new Uint8Array(SUPPLY + 1);
  for (const v of arr) {
    if (!Number.isInteger(v) || v < 1 || v > SUPPLY || seen[v]) return false;
    seen[v] = 1;
  }
  return true;
}
const deckOk = isPermutation(deck);
const orderOk = isPermutation(drawOrder);
const rehashOk = '0x' + keccak256(encoding) === deckHash;
console.log('seed text :', SEED_TEXT);
console.log('seed hex  :', '0x' + SEED.toString('hex'));
console.log('deckHash  :', deckHash);
console.log('deck is permutation 1..10000 :', deckOk);
console.log('drawOrder is permutation 1..10000 :', orderOk);
console.log('deckHash re-verified from encoding :', rehashOk);
console.log('first 10 deck entries :', deck.slice(0, 10).join(','));
console.log('first 10 draws (mint order) :', drawOrder.slice(0, 10).join(','));
if (!deckOk || !orderOk || !rehashOk) {
  console.error('VERIFICATION FAILED');
  process.exit(1);
}

// --- 5. Write deck.json ------------------------------------------------------
fs.mkdirSync(path.dirname(OUT), { recursive: true });
const out = {
  name: 'The Agent Mage deck',
  supply: SUPPLY,
  seed: SEED_TEXT,
  seedHex: '0x' + SEED.toString('hex'),
  deckHash,
  encoding: 'per token: 2 bytes big-endian, in deck order (10000 x 2 = 20000 bytes)',
  draw: 'lazy Fisher-Yates seeded by deckHash (THYRK _drawMain): draw #d (0-based), j = keccak256(deckHash || d) % remaining, tokenId = valueAt(j), swap j with remaining-1. "drawOrder" below is the replayed mint order.',
  deck,
  drawOrder,
};
fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
console.log('wrote', OUT);
console.log('VERIFICATION PASSED');
