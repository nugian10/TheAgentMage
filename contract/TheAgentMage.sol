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
//  YANG MASIH HARUS DIPUTUSKAN SEBELUM DEPLOY (lihat README.md):
//    1. baseURI metadata (IPFS / GitHub raw) — diisi setelah 226 trait
//       di-upload.
//    2. Token ID di sini URUT (1, 2, 3, ...). Kalau mau acak pakai deck
//       seperti THYRK/Zigzoo, bilang — deckHash bisa ditambahkan.
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

    /// @notice Royalti 5% = 500 basis poin (dari 10.000).
    uint96 public constant ROYALTY_BPS = 500;

    // ------------------------------------------------------------------------
    //  STATE
    // ------------------------------------------------------------------------
    uint256 public totalMinted;
    bool public mintActive; // mulai false — dibuka owner setelah registry + baseURI siap
    string public baseURI; // contoh: "ipfs://.../metadata/" atau GitHub raw
    address public agentIdRegistry; // default = SPACE ID HandleRegistry
    bool public agentIdCheckRequired = true; // owner bisa matikan bila perlu

    /// @notice Wallet -> apakah jatah mint gratisnya sudah dipakai.
    mapping(address => bool) public freeMintUsed;

    // ------------------------------------------------------------------------
    //  EVENTS
    // ------------------------------------------------------------------------
    event Minted(address indexed minter, uint256 indexed tokenId, uint256 paid);
    event MintActiveChanged(bool active);
    event BaseURIChanged(string baseURI);
    event AgentIdRegistryUpdated(address indexed agentIdRegistry);
    event AgentIdCheckChanged(bool required);

    // ------------------------------------------------------------------------
    //  ERRORS
    // ------------------------------------------------------------------------
    error NoAgentId();
    error InvalidAddress();

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
    //  MINT — hanya pemegang Agent ID (SPACE ID gate), 1 NFT per panggilan
    // ------------------------------------------------------------------------
    /// @notice Mint pertama per wallet GRATIS (kirim 0 BNB).
    ///         Mint berikutnya bayar tepat 0.0003 BNB, langsung diteruskan
    ///         ke Agentic Wallet di transaksi yang sama (tidak mengendap
    ///         di kontrak).
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

        totalMinted += 1;
        uint256 tokenId = totalMinted; // ID urut 1..10.000
        _safeMint(msg.sender, tokenId);
        emit Minted(msg.sender, tokenId, msg.value);
    }

    // ------------------------------------------------------------------------
    //  METADATA
    // ------------------------------------------------------------------------
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId >= 1 && tokenId <= totalMinted, "Token belum ada");
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
    //  - Batas per wallet: TIDAK ADA — batasnya per Agent ID (1 gratis),
    //    mint berbayar tidak dibatasi jumlahnya.
}
