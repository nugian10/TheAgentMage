# The Agent Mage — Smart Contract (SELESAI, BELUM DI-DEPLOY)

File kontrak: [`TheAgentMage.sol`](sandbox://workspace/projects/the-agent-mage/contract/TheAgentMage.sol)

> **Status: kode selesai dan terverifikasi compile. Belum di-deploy, belum ada alamat kontrak, belum keluar biaya apa pun.**

## Hasil compile (25 Nov 2026)

- **COMPILE OK** — 0 error, 0 warning.
- Compiler: **solc v0.8.24** (sama dengan THYRK v2), OpenZeppelin **5.4.0**, optimizer on 200 runs, EVM cancun.
- Bytecode 9.401 byte, deployed 8.475 byte, ABI 70 entries.
- Build lokal: `contract/build/` (`compile.js`, jalankan `node compile.js` untuk compile ulang).
- ABI terverifikasi berisi: `mint()`, `holdsAgentId(address)`, `royaltyInfo`, `setMintActive`, `setBaseURI`, `setPlaceholderURI`, `placeholderURI`, `setAgentIdRegistry` — dan **tidak ada** fungsi ERC-20 (`transfer(address,uint256)`, `allowance`, `totalSupply` tidak ada).

## Keputusan Bryan yang sudah masuk ke kontrak

| Keputusan | Isi |
|---|---|
| Token/coin | **Tidak ada.** Kontrak ini hanya NFT. |
| Owner | **Agentic Wallet** `0x89c37649Ba3BAA9E1ce028612b7DE4e9c3a947B7` |
| Revenue mint | **Agentic Wallet** — BNB mint berbayar langsung diteruskan ke Agentic di transaksi yang sama, tidak mengendap di kontrak. |
| Royalti | **5%** dari jual-beli di market (ERC-2981) → Agentic Wallet. |
| Supply | **10.000** NFT. |
| Mint | Pertama **GRATIS 1x per Agent ID**, berikutnya **flat 0.0003 BNB** (tanpa tangga harga). |
| Siapa boleh mint | Hanya pemegang **Agent ID** (SPACE ID gate), seperti THYRK/Zigzoo. |
| Harga di situs | Tetap **tidak tampil** di situs — hanya di skill.md. |
| Reveal | **Per-token 24 jam** (pola DRIXOR Core) — bukan reveal global. Lihat bawah. |

## Cara kerja mint (singkat)

1. Agen memanggil `mint()` (tanpa argumen) dari wallet-nya.
2. Kontrak cek ke SPACE ID: wallet itu memegang minimal 1 NFT Agent ID .ai (`balanceOf > 0` di registry).
3. Kalau itu mint pertama untuk wallet itu → **gratis**, kirim 0 BNB.
4. Kalau sudah pernah gratis → bayar **tepat 0.0003 BNB**, langsung masuk Agentic Wallet.
5. NFT dikirim ke wallet pemanggil. 1 NFT per panggilan.

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
3. **Token ID urut (1, 2, 3, …).** Kalau mau acak pakai deck seperti THYRK/Zigzoo, bilang — bisa ditambahkan deckHash.

(Simbol `AGMAGE` sudah dikunci Bryan 25 Nov; alamat SPACE ID sudah terisi dari THYRK/Zigzoo — keduanya bukan lagi hal terbuka.)

## Yang dikunci di kontrak (tidak bisa diubah setelah deploy)

- Harga mint 0.0003 BNB — tidak ada fungsi ubah harga.
- Royalti 5% — tidak ada fungsi ubah royalti.
- Jeda reveal 24 jam (`REVEAL_DELAY`) — constant.
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
