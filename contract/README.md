# The Agent Mage — Smart Contract (SELESAI, BELUM DI-DEPLOY)

File kontrak: [`TheAgentMage.sol`](sandbox://workspace/projects/the-agent-mage/contract/TheAgentMage.sol)

> **Status: kode selesai dan terverifikasi compile. Belum di-deploy, belum ada alamat kontrak, belum keluar biaya apa pun.**

## Hasil compile (25 Nov 2026)

- **COMPILE OK** — 0 error, 0 warning.
- Compiler: **solc v0.8.24** (sama dengan THYRK v2), OpenZeppelin **5.4.0**, optimizer on 200 runs, EVM cancun.
- Bytecode 8.962 byte, deployed 8.036 byte, ABI 65 entries.
- Build lokal: `contract/build/` (`compile.js`, jalankan `node compile.js` untuk compile ulang).
- ABI terverifikasi berisi: `mint()`, `holdsAgentId(address)`, `royaltyInfo`, `setMintActive`, `setBaseURI`, `setAgentIdRegistry` — dan **tidak ada** fungsi ERC-20 (`transfer(address,uint256)`, `allowance`, `totalSupply` tidak ada).

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

## Cara kerja mint (singkat)

1. Agen memanggil `mint()` (tanpa argumen) dari wallet-nya.
2. Kontrak cek ke SPACE ID: wallet itu memegang minimal 1 NFT Agent ID .ai (`balanceOf > 0` di registry).
3. Kalau itu mint pertama untuk wallet itu → **gratis**, kirim 0 BNB.
4. Kalau sudah pernah gratis → bayar **tepat 0.0003 BNB**, langsung masuk Agentic Wallet.
5. NFT dikirim ke wallet pemanggil. 1 NFT per panggilan.

## SPACE ID gate — terverifikasi dari kontrak live

- Registry: **`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`** (SPACE ID `HandleRegistry`, BscScan-verified).
- Dipakai sebagai `DEFAULT_AGENT_ID_REGISTRY` oleh **THYRK v2** (`0x4D90fFC3075FB8897EDFf6d7c6269c906664a20e`) dan **Zigzoo v2** (`0x09ADA5A12293C30D75b97c56E34967E8a4326a3C`) — dicek langsung dari source terverifikasi keduanya di BscScan, 25 Nov 2026.
- Pengecekan memakai `balanceOf(wallet) > 0` via staticcall (pola THYRK/Zigzoo). **Koreksi dari draft awal:** registry TIDAK punya fungsi `holdsAgentId(wallet, agentId)` dengan string Agent ID — jadi `mint()` tidak menerima nama Agent ID, dan jatah gratis dihitung **per wallet** (1 gratis per wallet pemegang Agent ID), sama seperti THYRK v2.
- Alamat registry masih bisa diubah owner setelah deploy (`setAgentIdRegistry`), dan cek Agent ID bisa dimatikan owner (`setAgentIdCheckRequired`) bila perlu.

## Yang masih harus diputuskan sebelum deploy

1. **baseURI metadata** — alamat folder metadata 226 trait (IPFS atau GitHub raw), diisi setelah trait di-upload.
2. **Token ID urut (1, 2, 3, …).** Kalau mau acak pakai deck seperti THYRK/Zigzoo, bilang — bisa ditambahkan deckHash.

(Simbol `AGMAGE` sudah dikunci Bryan 25 Nov; alamat SPACE ID sudah terisi dari THYRK/Zigzoo — keduanya bukan lagi hal terbuka.)

## Yang dikunci di kontrak (tidak bisa diubah setelah deploy)

- Harga mint 0.0003 BNB — tidak ada fungsi ubah harga.
- Royalti 5% — tidak ada fungsi ubah royalti.
- Tidak ada batas per wallet untuk mint berbayar — batasnya hanya 1 gratis per Agent ID.

## Yang bisa diubah owner setelah deploy

- Buka/tutup mint (`mintActive`, mulai dari **tutup**).
- `baseURI` metadata.
- Alamat `agentIdRegistry` (SPACE ID) + nyalakan/matikan cek Agent ID.
- Tarik BNB nyasar yang tertinggal di kontrak (kalau ada).

## Catatan deploy

- Deploy pertama **tidak bisa** lewat Agentic CLI (`baw` tidak bisa broadcast pembuatan kontrak mentah). Deploy harus manual dari wallet Bryan atau lewat factory — tapi constructor langsung memindahkan ownership ke Agentic Wallet, jadi siapa pun yang deploy, owner-nya tetap Agentic.
- Setelah deploy: verifikasi source di BscScan (seperti proyek-proyek sebelumnya), lalu isi `agentRegistry` + `baseURI`, baru buka mint.
- **Kontrak ini belum diaudit** — verifikasi BscScan bukan audit, sama seperti proyek sebelumnya.
