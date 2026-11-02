# Setting up the co-op relay (once)

Online co-op needs a small server that hands out lobby codes and passes the two players' messages to each other:
the **relay**, a Cloudflare Worker (`server/relay`). It runs on Cloudflare's free plan. You set it up once; after
that, every push to `main` updates it automatically (the `deploy-relay` job in CI).

The game already points at `wss://necropathy-relay.smoketsu.workers.dev` (`scripts/data/coop_net_data.gd`).

## Steps

1. **Make a free Cloudflare account** at <https://dash.cloudflare.com/sign-up> and confirm your e-mail.
   (Done: the account's Workers address is `smoketsu.workers.dev`.)
2. **Pick your workers.dev subdomain** if Cloudflare asks: in the dashboard open **Workers & Pages**; the first visit
   asks for a subdomain. (Done: `smoketsu`.)
3. **Copy your Account ID**: in **Workers & Pages**, the right-hand column shows **Account ID** with a copy button.
4. **Make an API token**: click your profile icon (top right) → **My Profile** → **API Tokens** → **Create Token** →
   next to **Edit Cloudflare Workers** click **Use template**. Under **Account Resources** choose your account,
   under **Zone Resources** choose **All zones** (nothing else needs changing) → **Continue to summary** →
   **Create Token**. Copy the token now: Cloudflare shows it only once.
5. **Add the two GitHub secrets**: on GitHub open the game's repository → **Settings** → **Secrets and variables** →
   **Actions** → **New repository secret**, twice:
   - name `CLOUDFLARE_API_TOKEN`, value: the token from step 4;
   - name `CLOUDFLARE_ACCOUNT_ID`, value: the Account ID from step 3.
6. **Deploy**: push anything to `main`, or open **Actions** → **CI** → **Run workflow** on `main`. When the run is
   green, the **deploy-relay** job's log ends with a line like `https://necropathy-relay.smoketsu.workers.dev`.
7. **Check it**: open <https://necropathy-relay.smoketsu.workers.dev/health> in a browser. It should say
   `{"ok":true,"protocol":1}`.
8. **Send the lead the address** from step 6 (only if it differs from `necropathy-relay.smoketsu.workers.dev`: the
   lead then changes `RELAY_URL` in `scripts/data/coop_net_data.gd`).

## Good to know

- **Cost:** the free plan is enough for playtesting. It allows 100,000 Durable Object requests a day; the relay
  counts 20 game messages as one request, so roughly a dozen full 20-minute co-op runs a day fit before Cloudflare
  starts refusing for the rest of the day (`server/relay/PROTOCOL.md`, "Cost note"). Waiting lobbies cost nothing.
- **Nothing to look after:** lobbies close by themselves after 10 idle minutes, and every code is freed once its
  lobby is gone.
- **Testing on your own machine** needs no Cloudflare at all: `python3 tools/coop_relay.py` runs the same relay
  locally; start the desktop game with `-- --relay=ws://127.0.0.1:8765`, or open the Web build with
  `?relay=ws://127.0.0.1:8765` after its address.

## Limiting join attempts (recommended)

Lobby codes are 6 letters (64M codes), and the relay itself refuses a client IP's joins for the rest of a 10-minute
window after 30 wrong codes (`join_rate`, `server/relay/PROTOCOL.md` "Rules"). That count lives in each Worker
instance's memory, so it is best effort: someone spreading guesses over many addresses or instances gets past it.
The hard limit is a Cloudflare **rate-limiting rule** in front of the Worker (GDD §15.0 "Co-op relay hardening"):

1. A WAF rule needs the relay on a **custom domain** of a zone in your account (a `workers.dev` address has no
   zone, so its rules cannot be set). If you add one: **Workers & Pages** → `necropathy-relay` → **Settings** →
   **Domains & Routes** → **Add** → **Custom domain** (e.g. `relay.example.com`), then point `RELAY_URL` in
   `scripts/data/coop_net_data.gd` at `wss://relay.example.com`.
2. In that zone: **Security** → **WAF** → **Rate limiting rules** → **Create rule**:
   - **If incoming requests match**: *URI Path* *wildcard* `/lobby/*/ws` (or the expression
     `starts_with(http.request.uri.path, "/lobby/") and ends_with(http.request.uri.path, "/ws")`);
   - **With the same characteristics**: *IP*;
   - **When rate exceeds**: about 20 requests a minute (the free plan offers only a 10-second period: use
     10 requests per 10 seconds);
   - **Then take action**: *Block*, for the longest duration the plan allows.
   A player joins once per lobby, so a real player never reaches it.
3. Without a custom domain, the per-IP count in the Worker is the only limit. Check now and then in **Workers &
   Pages** → `necropathy-relay` → **Metrics** that the daily Durable Object requests stay well under the free
   plan's 100,000.
