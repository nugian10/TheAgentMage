# The Agent Mage — Smart Contract (SELESAI, BELUM DI-DEPLOY)

File kontrak: [`TheAgentMage.sol`](sandbox://workspace/projects/the-agent-mage/contract/TheAgentMage.sol)

> **Status: kode selesai dan terverifikasi compile. Belum di-deploy, belum ada alamat kontrak, belum keluar biaya apa pun.**

## Hasil compile (25 Nov 2026, setelah tambah deck)

- **COMPILE OK** — 0 error, 0 warning.
- Compiler: **solc v0.8.24** (sama dengan THYRK v2), OpenZeppelin **5.4.0**, optimizer on 200 runs, EVM cancun.
- Bytecode 9.871 byte, deployed 8.939 byte (sebelum deck: 9.401 / 8.475 — tambah deck cuma +470 byte; jauh di bawah batas ukuran kontrak 24.576 byte, jadi tidak ada masalah gas deploy karena deck), ABI 72 entries.
- Build lokal: `contract/build/` (`compile.js`, jalankan `node compile.js` untuk compile ulang).
- ABI terverifikasi berisi: `mint()`, `deckHash`, `holdsAgentId(address)`, `royaltyInfo`, `setMintActive`, `setBaseURI`, `setPlaceholderURI`, `placeholderURI`, `setAgentIdRegistry` — dan **tidak ada** fungsi ERC-20 (`transfer(address,uint256)`, `allowance`, `totalSupply` tidak ada; `approve` yang muncul di ABI adalah `approve` ERC-721, bukan ERC-20).

## Keputusan Bryan yang sudah masuk ke kontrak

| Keputusan | Isi |
|---|---|
| Token/coin | **Tidak ada.** Kontrak ini hanya NFT. |
| Owner | **Agentic Wallet** `0x89c37649Ba3BAA9E1ce028612b7DE4e9c3a947B7` |
| Revenue mint | **Agentic Wallet** — BNB mint berbayar langsung diteruskan ke Agentic di transaksi yang sama, tidak mengendap di kontrak. |
| Royalti | **5%** dari jual-beli di market (ERC-2981) → Agentic Wallet. |
| Supply | **10.000** NFT. |
| Mint | Pertama **GRATIS 1x per Agent ID**, berikutnya **flat 0.0003 BNB** (tanpa tangga harga). **Token ID ditarik ACAK dari deck** (bukan urut) — keputusan Bryan 25 Nov 2026 ~08:02 WIB ("Acak"). Lihat bagian deck di bawah. |
| Siapa boleh mint | Hanya pemegang **Agent ID** (SPACE ID gate), seperti THYRK/Zigzoo. |
| Harga di situs | Tetap **tidak tampil** di situs — hanya di skill.md. |
| Reveal | **Per-token 24 jam** (pola DRIXOR Core) — bukan reveal global. Lihat bawah. |

## Cara kerja mint (singkat)

1. Agen memanggil `mint()` (tanpa argumen) dari wallet-nya.
2. Kontrak cek ke SPACE ID: wallet itu memegang minimal 1 NFT Agent ID .ai (`balanceOf > 0` di registry).
3. Kalau itu mint pertama untuk wallet itu → **gratis**, kirim 0 BNB.
4. Kalau sudah pernah gratis → bayar **tepat 0.0003 BNB**, langsung masuk Agentic Wallet.
5. NFT dikirim ke wallet pemanggil — **token ID-nya acak dari deck** (lihat bawah). 1 NFT per panggilan.

## DECK — UNDIAN TOKEN ID ACAK (keputusan Bryan 25 Nov 2026 ~08:02 WIB: "Acak")

Nomor token **tidak urut** (1, 2, 3, …). Setiap mint menarik satu token ID acak dari deck — pola **hash-only THYRK v2** (murah deploy, terbukti live), diadaptasi ke supply 10.000:

- **Deck** = Fisher-Yates shuffle token ID 1..10.000 dari seed **`"AGENTMAGE"`** (`0x4147454e544d414745`). File: [`collection/deck.json`](sandbox://workspace/projects/the-agent-mage/collection/deck.json) — berisi deck (10.000 angka unik 1..10.000, terverifikasi), seed, deckHash, dan `drawOrder` (urutan mint hasil replay).
- **deckHash** (tersimpan di kontrak sebagai constant): **`0xf88a6599c4fa30dc55541ee5c84adc6ea3742c76a6d2d7d62bebc4a42eb08c88`** = keccak256 dari encoding deck (per token: 2 byte big-endian, urutan deck; 10.000 × 2 = 20.000 byte).
- **Undian on-chain** (lazy Fisher-Yates, sama persis dengan `_drawMain` THYRK v2): draw #d (0-based), `remaining = 10.000 - d`, `j = keccak256(deckHash, d) % remaining`, `tokenId = valueAt(j)`, lalu swap posisi j dengan posisi terakhir. Deck penuh **tidak pernah disimpan on-chain** — hanya deckHash. Karena setiap draw mengeluarkan tokennya dari pool, token ID yang ditarik unik dan semua 10.000 akan ditarik tepat sekali saat pool habis.
- **Verifikasi:** siapa pun bisa membangun ulang deck dari seed (`contract/generate-deck.js`, jalankan `node generate-deck.js` — butuh `js-sha3`, sudah ada di `contract/build/node_modules/`), meng-encode ulang, dan memeriksa deckHash-nya sama. Urutan draw juga bisa di-replay dari deckHash (`drawOrder` di deck.json).
- **10 draw pertama** (urutan mint): 8054, 6696, 7329, 1945, 2310, 448, 345, 7593, 3397, 2499.
- **Batas jujur** (sama seperti THYRK): ini pseudo-randomness deterministik dari seed publik — **BUKAN VRF / provably fair randomness**. Siapa pun yang tahu seed bisa menghitung seluruh urutan draw di muka. Deck-nya transparan, bukan rahasia.
- **Gas:** tambah deck cuma +470 byte bytecode (9.401 → 9.871 byte); jauh di bawah batas 24.576 byte. Tidak ada masalah gas deploy karena deck — deck tidak disimpan on-chain.

## REVEAL PER-TOKEN 24 JAM (keputusan Bryan 25 Nov 2026)

**Bukan satu reveal global untuk semua token.** Setiap token punya waktunya sendiri:

1. Saat token di-mint, kontrak mencatat `mintedAt[tokenId] = block.timestamp`.
2. Selama **24 jam pertama** setelah mint, `tokenURI(tokenId)` mengarah ke **SATU metadata placeholder yang sama untuk semua token** (`placeholderURI`) — kartu misteri, gambarnya sama untuk semua token. Tidak ada 10.000 file placeholder.
3. Setelah **24 jam lewat**, `tokenURI(tokenId)` **otomatis** mengarah ke metadata **asli** (`baseURI + tokenId + ".json"`). Tidak ada tombol reveal, tidak ada transaksi reveal — waktunya jalan sendiri per token.

Konstanta di kontrak: `REVEAL_DELAY = 24 hours`.

### Kenapa sistem ini

- Mint bisa dibuka **tanpa menunggu upload 10.000 file apa pun** — itu yang Bryan minta ("Saya gamau upload 10.000 file").
- **Hanya ada SATU file placeholder** (`mystery.json`) untuk semua token yang belum reveal — bukan 10.000 file. Folder `collection/metadata-placeholder/` (10.000 JSON) yang sempat dibuat **sudah dihapus** dan tidak pernah di-upload ke mana pun.
- Gambar asli hanya perlu dibuat untuk token yang **benar-benar sudah di-mint** — bukan 10.000 sekaligus.
- Kolektor tetap dapat kejutan: 24 jam pertama NFT-nya misteri.

### Catatan operasional — PENTING

- **Gambar asli tiap token yang di-mint HARUS sudah di-upload sebelum 24 jamnya habis.** Kalau belum, setelah 24 jam token itu menampilkan metadata asli yang belum ada filenya (404 di marketplace) sampai gambarnya di-upload. Jadi setelah mint dibuka, perlu ada yang memantau mint baru dan membuatkan gambarnya dalam 24 jam.
- **`placeholderURI` WAJIB diisi sebelum mint dibuka** (owner-only `setPlaceholderURI`). Kalau kosong, tokenURI 24 jam pertama mengarah ke alamat kosong.
- `baseURI` (metadata asli) boleh diisi belakangan, tapi harus sudah terisi sebelum token pertama melewati 24 jam.

### File placeholder (sudah dibuat + di-upload 25 Nov 2026)

- Kartu misteri: [`collection/mystery.webp`](sandbox://workspace/projects/the-agent-mage/collection/mystery.webp) — siluet chibi mage + tanda "?" emas, latar hitam #0B0E11.
- Gambar IPFS (Pinata): **`ipfs://bafybeif2ufm7yrgzp6lml4uipuybcfslnk4qf6i4g5xccpovw7ruvix5qu`** (CID `bafybeif2ufm7yrgzp6lml4uipuybcfslnk4qf6i4g5xccpovw7ruvix5qu`).
- Metadata placeholder — **SATU file saja**: `collection/mystery.json`, isinya nama "The Agent Mage — Mystery", deskripsi "mystery mage, not revealed yet. Reveals 24 hours after mint.", image = IPFS kartu misteri, attributes Status = Unrevealed.
- Metadata placeholder IPFS (Pinata, satu file): **`ipfs://bafkreieyz2g4crgbakx4ghyl3rimiwffe7siz5relxw3vyw667di6j4t4m`** (CID `bafkreieyz2g4crgbakx4ghyl3rimiwffe7siz5relxw3vyw667di6j4t4m`, terverifikasi gateway HTTP 200, isi cocok dengan file lokal).
- **Nilai `placeholderURI` yang diisi on-chain setelah deploy: `ipfs://bafkreieyz2g4crgbakx4ghyl3rimiwffe7siz5relxw3vyw667di6j4t4m`**
- 10.000 file placeholder lama (`collection/metadata-placeholder/1.json` … `10000.json`) **SUDAH DIHAPUS** — tidak dipakai, tidak pernah di-upload.

## SPACE ID gate — terverifikasi dari kontrak live

- Registry: **`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`** (SPACE ID `HandleRegistry`, BscScan-verified).
- Dipakai sebagai `DEFAULT_AGENT_ID_REGISTRY` oleh **THYRK v2** (`0x4D90fFC3075FB8897EDFf6d7c6269c906664a20e`) dan **Zigzoo v2** (`0x09ADA5A12293C30D75b97c56E34967E8a4326a3C`) — dicek langsung dari source terverifikasi keduanya di BscScan, 25 Nov 2026.
- Pengecekan memakai `balanceOf(wallet) > 0` via staticcall (pola THYRK/Zigzoo). **Koreksi dari draft awal:** registry TIDAK punya fungsi `holdsAgentId(wallet, agentId)` dengan string Agent ID — jadi `mint()` tidak menerima nama Agent ID, dan jatah gratis dihitung **per wallet** (1 gratis per wallet pemegang Agent ID), sama seperti THYRK v2.
- Alamat registry masih bisa diubah owner setelah deploy (`setAgentIdRegistry`), dan cek Agent ID bisa dimatikan owner (`setAgentIdCheckRequired`) bila perlu.

## Yang masih harus diputuskan sebelum deploy

1. **`placeholderURI`** — SATU URI file metadata placeholder: `ipfs://bafkreieyz2g4crgbakx4ghyl3rimiwffe7siz5relxw3vyw667di6j4t4m` (sudah di IPFS). Wajib diisi sebelum mint dibuka.
2. **`baseURI` metadata asli** — diisi setelah gambar asli token yang di-mint di-upload (IPFS / GitHub raw).

(Simbol `AGMAGE` sudah dikunci Bryan 25 Nov; alamat SPACE ID sudah terisi dari THYRK/Zigzoo; **deck acak sudah dikunci Bryan 25 Nov ~08:02 WIB** — ketiganya bukan lagi hal terbuka.)

## Yang dikunci di kontrak (tidak bisa diubah setelah deploy)

- Harga mint 0.0003 BNB — tidak ada fungsi ubah harga.
- Royalti 5% — tidak ada fungsi ubah royalti.
- Jeda reveal 24 jam (`REVEAL_DELAY`) — constant.
- Deck undian (`deckHash`) — constant; urutan draw deterministik dari deckHash.
- Tidak ada batas per wallet untuk mint berbayar — batasnya hanya 1 gratis per Agent ID.

## Yang bisa diubah owner setelah deploy

- Buka/tutup mint (`mintActive`, mulai dari **tutup**).
- `baseURI` metadata asli + `placeholderURI` (satu file kartu misteri).
- Alamat `agentIdRegistry` (SPACE ID) + nyalakan/matikan cek Agent ID.
- Tarik BNB nyasar yang tertinggal di kontrak (kalau ada).

## Catatan deploy

- Deploy pertama **tidak bisa** lewat Agentic CLI (`baw` tidak bisa broadcast pembuatan kontrak mentah). Deploy harus manual dari wallet Bryan atau lewat factory — tapi constructor langsung memindahkan ownership ke Agentic Wallet, jadi siapa pun yang deploy, owner-nya tetap Agentic.
- Setelah deploy: verifikasi source di BscScan (seperti proyek-proyek sebelumnya), lalu isi `placeholderURI` (`ipfs://bafkreieyz2g4crgbakx4ghyl3rimiwffe7siz5relxw3vyw667di6j4t4m`) (+ `baseURI` bila sudah ada), baru buka mint.
- **Kontrak ini belum diaudit** — verifikasi BscScan bukan audit, sama seperti proyek sebelumnya.
