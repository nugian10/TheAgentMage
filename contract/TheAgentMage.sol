// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================================
//  THE AGENT MAGE — NFT Contract (BELUM DI-DEPLOY)
//  ---------------------------------------------------------------------------
//  Keputusan Bryan (25 Nov 2026):
//    - TIDAK ada token/coin dulu (kontrak ini hanya NFT, tanpa ERC-20)
//    - Owner DAN revenue = Agentic Wallet Bryan:
//        0x89c37649Ba3BAA9E1ce028612b7DE4e9c3a947B7
//    - Royalti 5% dari jual-beli di market -> ke Agentic Wallet (ERC-2981)
//    - Supply 10.000, mint pertama GRATIS 1x per Agent ID,
//      mint berikutnya flat 0.0003 BNB (harga TIDAK tampil di situs,
//      hanya di skill.md untuk agen)
//    - Mint hanya oleh pemegang Agent ID (SPACE ID gate), seperti THYRK/Zigzoo
//
//  SPACE ID GATE — TERVERIFIK DARI KONTRAK LIVE (25 Nov 2026):
//    Registry = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
//    (SPACE ID HandleRegistry, BscScan-verified). Dipakai sebagai
//    DEFAULT_AGENT_ID_REGISTRY oleh THYRK v2 (0x4D90fFC3075FB8897EDFf6d7c6269c906664a20e)
//    dan Zigzoo v2 (0x09ADA5A12293C30D75b97c56E34967E8a4326a3C).
//    Cara ceknya: balanceOf(wallet) > 0 di registry itu — wallet memegang
//    minimal 1 NFT Agent ID .ai. TIDAK ada fungsi holdsAgentId(wallet,
//    agentId) di registry; draft lama yang memakai string agentId SUDAH
//    DIPERBAIKI mengikuti pola THYRK/Zigzoo yang terbukti live.
//    Konsekuensinya: mint() tanpa argumen, dan jatah gratis dihitung
//    per wallet (1 gratis per wallet yang memegang Agent ID), sama
//    seperti THYRK v2 ("free mint: automatic first/wallet").
//
//  REVEAL PER-TOKEN 24 JAM (keputusan Bryan, 25 Nov 2026 ~07:53 WIB —
//  pola DRIXOR Core): BUKAN satu reveal global. Setiap token punya
//  waktunya sendiri: tokenURI menampilkan SATU metadata PLACEHOLDER
//  yang sama (kartu misteri) selama 24 jam pertama setelah token itu
//  di-mint, lalu OTOMATIS menampilkan metadata asli. Satu file
//  placeholder saja — TIDAK ADA 10.000 file placeholder (Bryan 25 Nov
//  2026 ~07:57 WIB: "Saya gamau upload 10.000 file"). Jadi mint bisa
//  dibuka TANPA upload 10.000 file apa pun — gambar asli hanya perlu
//  dibuat untuk token yang BENAR-BENAR sudah di-mint, dan harus sudah
//  di-upload sebelum 24 jam token itu habis (kalau tidak, tokenURI asli
//  akan 404 sampai gambarnya di-upload). Tidak ada tombol reveal global.
//
//  THE DECK — RANDOM TOKEN-ID DRAW (keputusan Bryan, 25 Nov 2026
//  ~08:02 WIB: "Acak" — nomor token juga acak, bukan urut).
//  Pola hash-only THYRK v2 (murah deploy), diadaptasi ke supply 10.000:
//    Deck = Fisher-Yates shuffle token ID 1..10.000 dari seed
//    "AGENTMAGE" (0x4147454e544d414745). Deck, seed dan deckHash
//    dipublikasikan off-chain (collection/deck.json), jadi siapa pun
//    bisa membangun ulang deck dan memverifikasi deckHash.
//    deckHash = keccak256 dari encoding deck (per token: 2 byte
//    big-endian, urutan deck; 10.000 x 2 = 20.000 byte).
//    Undian di kontrak adalah lazy Fisher-Yates yang di-seed deckHash,
//    dieksekusi on-chain satu draw demi satu draw:
//      draw #d (0-based), remaining = 10.000 - d
//      j = uint256(keccak256(deckHash, d)) % remaining
//      tokenId = valueAt(j); lalu swap posisi j dengan posisi
//      (remaining - 1) di map _swapped (entry kosong = identitas:
//      posisi i memegang tokenId i+1).
//    Karena setiap draw mengeluarkan tokennya dari pool, token ID yang
//    ditarik unik dan semua 10.000 akan ditarik tepat sekali saat pool
//    habis. Urutan draw sepenuhnya deterministik dari deckHash —
//    deck-nya transparan, bukan rahasia.
//    HONEST LIMITS (sama seperti THYRK): ini pseudo-randomness
//    deterministik dari seed publik — BUKAN VRF / provably fair
//    randomness; siapa pun yang tahu seed bisa menghitung urutan
//    draw di muka. (2) Deck tetap setelah deploy (deckHash constant)
//    dan tidak bisa di-shuffle ulang.
//
//  YANG MASIH HARUS DIPUTUSKAN SEBELUM DEPLOY (lihat README.md):
//    1. placeholderURI — SATU URI file metadata placeholder
//       (collection/mystery.json, sudah di IPFS). Diisi sebelum
//       mint dibuka.
//    2. baseURI metadata asli — diisi setelah gambar asli token
//       yang di-mint di-upload (IPFS / GitHub raw).
//  ---------------------------------------------------------------------------
//  CATATAN DEPLOY: baw (Agentic CLI) TIDAK bisa broadcast pembuatan kontrak
//  mentah. Deploy pertama harus manual dari wallet Bryan (My Wallet) atau
//  lewat factory. Constructor langsung memindahkan ownership ke Agentic
//  Wallet, jadi siapa pun yang deploy, owner-nya tetap Agentic.
// =============================================================================

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheAgentMage is ERC721, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // ------------------------------------------------------------------------
    //  KONFIGURASI YANG DIKUNCI (tidak bisa diubah setelah deploy)
    // ------------------------------------------------------------------------
    string public constant COLLECTION_NAME = "The Agent Mage";
    string public constant COLLECTION_SYMBOL = "AGMAGE";

    /// @notice Dompet Agentic Bryan — owner, penerima revenue, penerima royalti.
    address public constant AGENTIC_WALLET = 0x89c37649Ba3BAA9E1ce028612b7DE4e9c3a947B7;

    /// @notice SPACE ID HandleRegistry (.ai Agent ID NFT) di BNB Chain.
    /// @dev Terverifikasi dari THYRK v2 + Zigzoo v2 (keduanya BscScan-verified).
    address public constant DEFAULT_AGENT_ID_REGISTRY = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant MINT_PRICE = 0.0003 ether; // flat, tanpa tangga harga
    uint256 public constant FREE_MINTS_PER_AGENT_ID = 1;

    /// @notice Jeda reveal per-token: 24 jam setelah token di-mint.
    uint256 public constant REVEAL_DELAY = 24 hours;

    /// @notice Royalti 5% = 500 basis poin (dari 10.000).
    uint96 public constant ROYALTY_BPS = 500;

    /// @notice keccak256 commitment dari deck, lihat THE DECK di atas.
    /// Deck penuh TIDAK PERNAH disimpan on-chain — hanya hash-nya.
    /// Dibangun dari seed "AGENTMAGE" (lihat contract/generate-deck.js
    /// + collection/deck.json untuk verifikasi).
    bytes32 public constant deckHash =
        0xf88a6599c4fa30dc55541ee5c84adc6ea3742c76a6d2d7d62bebc4a42eb08c88;

    // ------------------------------------------------------------------------
    //  STATE
    // ------------------------------------------------------------------------
    uint256 public totalMinted;
    bool public mintActive; // mulai false — dibuka owner setelah registry + baseURI siap
    string public baseURI; // metadata ASLI — contoh: "ipfs://.../metadata/"
    string public placeholderURI; // SATU URI metadata PLACEHOLDER (kartu misteri)
    address public agentIdRegistry; // default = SPACE ID HandleRegistry
    bool public agentIdCheckRequired = true; // owner bisa matikan bila perlu

    /// @notice Wallet -> apakah jatah mint gratisnya sudah dipakai.
    mapping(address => bool) public freeMintUsed;

    /// @notice Token ID -> waktu (block.timestamp) token itu di-mint.
    /// @dev Dipakai tokenURI untuk menghitung kapan 24 jam reveal habis.
    mapping(uint256 => uint256) public mintedAt;

    /// @dev Token yang belum ditarik di pool lazy Fisher-Yates.
    /// Mulai dari 10.000; setiap deck draw menguranginya tepat 1.
    uint256 private _remaining = MAX_SUPPLY;
    /// @dev Counter draw global: men-seed setiap draw supaya tidak ada
    /// dua draw yang berbagi seed, bahkan di dalam satu bulk mint.
    uint256 private _drawIndex;
    /// @dev Sparse Fisher-Yates swap map: _swapped[i] = tokenId yang
    /// sekarang dipegang posisi i, atau 0 = belum diisi (identitas:
    /// posisi i memegang tokenId i+1).
    mapping(uint256 => uint256) private _swapped;

    // ------------------------------------------------------------------------
    //  EVENTS
    // ------------------------------------------------------------------------
    event Minted(address indexed minter, uint256 indexed tokenId, uint256 paid);
    event MintActiveChanged(bool active);
    event BaseURIChanged(string baseURI);
    event PlaceholderURIChanged(string placeholderURI);
    event AgentIdRegistryUpdated(address indexed agentIdRegistry);
    event AgentIdCheckChanged(bool required);

    // ------------------------------------------------------------------------
    //  ERRORS
    // ------------------------------------------------------------------------
    error NoAgentId();
    error InvalidAddress();
    error SoldOut();

    // ------------------------------------------------------------------------
    //  CONSTRUCTOR — ownership langsung ke Agentic Wallet.
    // ------------------------------------------------------------------------
    constructor() ERC721(COLLECTION_NAME, COLLECTION_SYMBOL) Ownable(AGENTIC_WALLET) {
        agentIdRegistry = DEFAULT_AGENT_ID_REGISTRY;
        _setDefaultRoyalty(AGENTIC_WALLET, ROYALTY_BPS);
    }

    // ------------------------------------------------------------------------
    //  AGENT ID CHECK — pola THYRK v2 / Zigzoo v2 (terbukti live)
    // ------------------------------------------------------------------------
    /// @notice True bila `wallet` memegang minimal 1 NFT Agent ID .ai
    ///         di registry SPACE ID yang dikonfigurasi.
    /// @dev Low-level staticcall sengaja: panggilan balanceOf ke alamat
    ///      tanpa code mengembalikan data kosong, dan ABI decoder revert
    ///      di luar try/catch. Staticcall mengembalikan ok=false / data
    ///      pendek, yang di sini dipetakan ke false — jadi registry yang
    ///      rusak tidak pernah nge-brick mint, hanya memblokirnya.
    function holdsAgentId(address wallet) public view returns (bool) {
        if (agentIdRegistry == address(0)) return false;
        (bool ok, bytes memory data) = agentIdRegistry.staticcall(
            abi.encodeWithSelector(IERC721.balanceOf.selector, wallet)
        );
        if (!ok || data.length < 32) return false;
        return abi.decode(data, (uint256)) > 0;
    }

    // ------------------------------------------------------------------------
    //  DECK DRAW — lazy Fisher-Yates, pola THYRK v2 (terbukti live)
    // ------------------------------------------------------------------------
    /// @dev Token ID yang saat ini dipegang posisi pool `i` (0-based).
    /// Entry map yang belum diisi = identitas (i + 1).
    function _valueAt(uint256 i) internal view returns (uint256) {
        uint256 v = _swapped[i];
        return v == 0 ? i + 1 : v;
    }

    /// @dev Ambil token di posisi pool `pos`: swap dengan posisi
    /// terakhir yang belum ditarik, lalu kecilkan pool satu.
    /// Caller harus menjamin pos < _remaining.
    function _takeAt(uint256 pos) internal returns (uint256 tokenId) {
        tokenId = _valueAt(pos);
        uint256 last = _valueAt(_remaining - 1);
        if (pos != _remaining - 1) {
            _swapped[pos] = last;
        }
        _remaining--;
    }

    /// @dev Tarik satu token dari pool bersama — dipakai setiap mint:
    /// lazy Fisher-Yates di atas pool. Tidak ada batasan rarity:
    /// token ID berapa pun bisa ditarik. Karena setiap draw
    /// mengeluarkan tokennya dari pool, token ID yang ditarik unik
    /// dan semua 10.000 akan ditarik tepat sekali saat pool habis.
    function _drawMain() internal returns (uint256) {
        if (_remaining == 0) revert SoldOut();
        uint256 j = uint256(keccak256(abi.encodePacked(deckHash, _drawIndex))) % _remaining;
        _drawIndex++;
        return _takeAt(j);
    }

    // ------------------------------------------------------------------------
    //  MINT — hanya pemegang Agent ID (SPACE ID gate), 1 NFT per panggilan
    // ------------------------------------------------------------------------
    /// @notice Mint pertama per wallet GRATIS (kirim 0 BNB).
    ///         Mint berikutnya bayar tepat 0.0003 BNB, langsung diteruskan
    ///         ke Agentic Wallet di transaksi yang sama (tidak mengendap
    ///         di kontrak). Token ID ditarik ACAK dari deck (bukan urut).
    function mint() external payable nonReentrant {
        require(mintActive, "Mint belum dibuka");
        require(totalMinted < MAX_SUPPLY, "Sudah habis (10.000)");
        if (agentIdCheckRequired && !holdsAgentId(msg.sender)) revert NoAgentId();

        if (!freeMintUsed[msg.sender]) {
            require(msg.value == 0, "Mint gratis: jangan kirim BNB");
            freeMintUsed[msg.sender] = true;
        } else {
            require(msg.value == MINT_PRICE, "Harus tepat 0.0003 BNB");
            (bool ok, ) = AGENTIC_WALLET.call{value: msg.value}("");
            require(ok, "Gagal teruskan revenue ke Agentic");
        }

        uint256 tokenId = _drawMain(); // ID ACAK dari deck, 1..10.000
        totalMinted += 1;
        mintedAt[tokenId] = block.timestamp;
        _safeMint(msg.sender, tokenId);
        emit Minted(msg.sender, tokenId, msg.value);
    }

    // ------------------------------------------------------------------------
    //  METADATA — REVEAL PER-TOKEN 24 JAM
    // ------------------------------------------------------------------------
    /// @notice Selama 24 jam pertama setelah mint, tokenURI mengarah ke
    ///         SATU metadata PLACEHOLDER yang sama untuk semua token
    ///         (kartu misteri). Setelah 24 jam, otomatis mengarah ke
    ///         metadata ASLI per-token (baseURI). Tidak ada tombol
    ///         reveal — waktunya jalan sendiri per token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Token ID ditarik ACAK dari deck, jadi keberadaan token dicek
        // dari mintedAt (bukan tokenId <= totalMinted seperti ID urut).
        require(mintedAt[tokenId] != 0, "Token belum ada");
        if (block.timestamp < mintedAt[tokenId] + REVEAL_DELAY) {
            return placeholderURI;
        }
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // ------------------------------------------------------------------------
    //  OWNER-ONLY (owner = Agentic Wallet — jadi perubahan ini harus
    //  ditandatangani lewat Agentic, bukan dari wallet lain)
    // ------------------------------------------------------------------------
    function setMintActive(bool active) external onlyOwner {
        mintActive = active;
        emit MintActiveChanged(active);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    /// @notice Isi/ubah SATU URI metadata PLACEHOLDER (kartu misteri,
    ///         sama untuk semua token yang belum reveal).
    ///         Wajib diisi SEBELUM mint dibuka — kalau kosong, tokenURI
    ///         24 jam pertama akan mengarah ke alamat kosong.
    function setPlaceholderURI(string calldata newPlaceholderURI) external onlyOwner {
        placeholderURI = newPlaceholderURI;
        emit PlaceholderURIChanged(newPlaceholderURI);
    }

    /// @notice Arahkan cek Agent ID ke registry lain (mis. bila SPACE ID
    ///         memindahkan kontrak .ai NFT-nya).
    function setAgentIdRegistry(address agentIdRegistry_) external onlyOwner {
        if (agentIdRegistry_ == address(0)) revert InvalidAddress();
        agentIdRegistry = agentIdRegistry_;
        emit AgentIdRegistryUpdated(agentIdRegistry_);
    }

    /// @notice Nyalakan/matikan cek Agent ID on-chain. Kalau dimatikan,
    ///         mint jadi terbuka untuk semua wallet (hanya di UI saja
    ///         tetap agent-only). Perubahan ini publik di chain.
    function setAgentIdCheckRequired(bool required) external onlyOwner {
        agentIdCheckRequired = required;
        emit AgentIdCheckChanged(required);
    }

    /// @notice Tarik BNB nyasar yang tertinggal di kontrak ke Agentic.
    ///         (BNB mint normal tidak pernah mengendap — langsung diteruskan.)
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Tidak ada BNB di kontrak");
        (bool ok, ) = AGENTIC_WALLET.call{value: balance}("");
        require(ok, "Withdraw gagal");
    }

    // ------------------------------------------------------------------------
    //  ROYALTI (ERC-2981) — 5% ke Agentic di setiap jual-beli sekunder
    //  yang menghormati standar ini (market on-site + Element, dll).
    // ------------------------------------------------------------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ------------------------------------------------------------------------
    //  YANG SENGAJA TIDAK ADA DI KONTRAK INI
    // ------------------------------------------------------------------------
    //  - Token/coin ($MAGE dsb): TIDAK ADA, sesuai perintah Bryan.
    //  - Fungsi ubah harga: MINT_PRICE constant — harga 0.0003 BNB terkunci.
    //  - Fungsi ubah royalti: ROYALTY_BPS constant — royalti 5% terkunci.
    //  - Fungsi ubah owner ke alamat lain: Ownable standar tetap ada
    //    (transferOwnership), tapi hanya owner (Agentic) yang bisa pakai.
    //  - Fungsi reveal global / flag `revealed`: TIDAK ADA, sesuai
    //    keputusan Bryan (reveal per-token 24 jam, otomatis per token).
    //  - Batas per wallet: TIDAK ADA — batasnya per Agent ID (1 gratis),
    //    mint berbayar tidak dibatasi jumlahnya.
}
