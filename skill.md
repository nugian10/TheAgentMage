# The Agent Mage — Agent Skill

> Read this file before minting. This file is the source of truth for agents.
> The website does NOT show the mint price by design. The price is here, in this file only.

## Project

- **Name:** The Agent Mage
- **Chain:** BNB Chain (56)
- **Standard:** ERC-721
- **Supply:** 10,000
- **Minted so far:** 3 (first mint: token #8054, tx [0xf56586de…](https://bscscan.com/tx/0xf56586de5d1447dcfdbfe110e8a82745a7222cf1fdaaa740b34d0daf2f5f10b5), 25 Nov 2026 08:15:45 WIB)
- **Contract address:** [0x92da0f42d2c4b5414605b4c94f10ac8c6b38af1d](https://bscscan.com/address/0x92da0f42d2c4b5414605b4c94f10ac8c6b38af1d)
- **Website:** https://agentmage.netlify.app/
- **Main character:** chibi young mage — large head, big green eyes, light green hair, tall purple pointed hat with gold trim, purple robe, staff with a glowing blue orb. Backgrounds use BNB Chain identity colours only: Yellow #F0B90B, Black #0B0E11, White #FFFFFF. No lime green, no Robinhood elements.
- **Traits:** 8 categories, 226 values — Element 8, Hat 50, Eyes 50, Staff 50, Robe 50, Background 3, Pose 8, Mouth 7. Full list: `traits.md` in the project repo.
- **Reveal:** per-token, 24 hours after mint — every mage first appears as a mystery card and reveals its true form 24 hours after its mint. Do not promise a reveal time earlier than that.
- **Rarity (trial):** Element — Fire 25%, Water 20%, Earth 15%, Wind 12%, Ice 10%, Lightning 8%, Shadow 6%, Light 4%. Background — Black 50%, BNB Yellow 30%, White 20%. Pose — Standing 40%, Raise Staff 20%, Read Book 12%, Cast Forward 10%, Look Aside 7%, Wave 5%, Float 4%, Meditate 2%. Mouth — Slight Smile 40%, Wide Smile 20%, Serious 15%, Laugh 10%, Smirk 7%, Pout 5%, Surprised 3%. Hat / Eyes / Staff / Robe (50 each) — Common 15 (~4% each), Uncommon 15 (~2% each), Rare 10 (~1% each), Epic 7 (~0.5% each), Legendary 3 (~0.2% each).

## Who can mint

- **Agent-only.** Minting is only for agents holding a Binance Agent ID (`.ai`) through SPACE ID.
- The minter must use a **Binance Agentic Wallet**.
- There is no public mint button for humans. Do not mint for a user who has no Agent ID.

## Mint price — agents only, do not publish on the website

- **First mint: FREE, 1 per Agent ID.**
- **Subsequent mints: flat 0.0003 BNB each.** No price ladder — every paid mint after the first costs the same 0.0003 BNB.
- Gas is extra, paid by the minter in BNB.
- Never show this price on the website. If the user asks what the mint costs, tell them in chat — do not add it to the site.

## How to mint

1. Confirm the user has a Binance Agent ID (`.ai`) and a Binance Agentic Wallet.
2. Confirm the contract address is live (it is: see above). Minting is open.
3. Check on-chain whether this Agent ID has already used its free mint.
   - If not used: the first mint is free (1 per Agent ID).
   - If used: each further mint costs a flat 0.0003 BNB.
4. Confirm the exact number of mints with the user before you mint. **Do not mint more than the user asked for.**
5. Call the contract `mint()` with the user's Agentic Wallet, pay the correct amount (0 for the free first mint, 0.0003 BNB per mint after that), and confirm the transaction on BscScan.
6. Report back the token ID(s) and the BscScan transaction link.

## Agent mint prompt (for the user to send to their agent)

```
Mint The Agent Mage on BNB Chain. First, read the skill.md file at https://agentmage.netlify.app/skill.md. Mint 1 The Agent Mage NFT using my Binance Agentic Wallet with my Agent ID (.ai). The first mint is free for 1 Agent ID; check skill.md for the price of further mints. Do not mint more than I ask for.
```

## Secondary market

- Trading on our own site: https://agentmage.netlify.app/market.html

## Rules

- Do not invent a contract address, launch date, X/Twitter handle, Element collection URL, or minted count.
- Minted count is 0 until a contract is deployed and a mint is confirmed on-chain.
- Do not add the mint price to the website.
- Not financial advice. NFTs are collectibles, not investments. Not affiliated with Binance or SPACE ID.
