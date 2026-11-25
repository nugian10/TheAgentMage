# TheAgentMage

The Agent Mage — 10,000 chibi mage NFTs on BNB Chain (56), ERC-721, minted by agents only.

## Project

- **Supply:** 10,000
- **Minted:** 0 / 10,000 (contract not deployed yet)
- **Contract address:** TBD
- **Mint:** agent-only via Binance Agentic Wallet with a Binance Agent ID (`.ai`) through SPACE ID. First mint per Agent ID follows the rule in `skill.md`.
- **Traits:** 8 categories, 226 values (Element 8, Hat 50, Eyes 50, Staff 50, Robe 50, Background 3, Pose 8, Mouth 7)
- **Design:** BNB Chain identity colours only — Yellow #F0B90B, Black #0B0E11, White #FFFFFF. No lime green, no Robinhood elements.

## Files

- `index.html` — the whole site, single self-contained page (inline CSS/JS, mobile-first). No mint price is shown on the site by design.
- `skill.md` — agent skill file. This is the ONLY place the mint price appears. Agents must read it before minting.
- `llms.txt` — agent discovery file, points to `skill.md`.
- `assets/` — hero image and trait samples.
- `netlify.toml` — Netlify config (publish this folder, no build command).

## Deploy on Netlify

1. Push this folder to GitHub as repo **TheAgentMage**.
2. In Netlify: New site from Git → pick the repo → publish directory is the site root (`.`), build command empty.
3. Deploy. The site URL becomes `[site URL]` — replace the `[site URL]` placeholders in `skill.md`, `llms.txt`, and the agent prompt in `index.html` with the real Netlify URL.

## Agent mint prompt

```
Mint The Agent Mage on BNB Chain. First, read the skill.md file at [site URL]/skill.md. Mint 1 The Agent Mage NFT using my Binance Agentic Wallet with my Agent ID (.ai). The first mint is free for 1 Agent ID; check skill.md for the price of further mints. Do not mint more than I ask for.
```

Not financial advice. NFTs are collectibles, not investments. Not affiliated with Binance or SPACE ID.
