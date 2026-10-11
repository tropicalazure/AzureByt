# VestaByt

A Tidbyt/Tronbyt app that mimics the *look* of a Vestaboard split-flap
display — a black tile grid with white characters — without talking to
any Vestaboard hardware or API. Content (quotes, facts, jokes, "on this
day" trivia, word of the day) is generated live by the DeepSeek API.

## How it works

Tidbyt/Tronbyt apps are Starlark scripts that render **entirely on the
server** (Tronbyt renders a WebP animation and pushes it to the
physical device — the device itself never runs code or makes network
calls). That means the DeepSeek API key you enter lives only in
Tronbyt's own app config storage and is used only in the server-side
`http.post` call in this script — it never reaches the Tidbyt device.

Each render:
1. If Content is set to "Custom phrase", skips DeepSeek entirely and
   just displays whatever you typed into the Custom phrase field --
   no API key needed for this mode.
2. Otherwise, checks a cache (keyed by category + model, TTL = your
   configured refresh interval) for existing content.
3. On a cache miss, picks a category (or a random one, if you chose
   "Surprise me") and asks DeepSeek for one short item.
4. Word-wraps the result into a tile grid (10 chars × 4 lines, 40
   characters total). Content that doesn't fit is truncated -- a real
   Vestaboard is a fixed grid too, it doesn't scroll either.
5. Letters reveal one at a time, typewriter-style: each character
   flips through a couple of glyphs before landing, and the next
   letter doesn't start until the previous one has settled. Blank
   spaces aren't animated. The full board then rests, fully readable,
   before the loop repeats.

## Setup

1. Get a DeepSeek API key from your DeepSeek account/dashboard.
2. In your Tronbyt server's web UI, add this app (point it at
   `vestabyt.star` or paste its contents in).
3. Open the app's config and fill in:
   - **DeepSeek API Key** — not needed if you only plan to use "Custom
     phrase"
   - **Content** — a specific category, "Surprise me" for a random mix
     each refresh, or "Custom phrase" to show your own text
   - **Custom phrase** — only used when Content is "Custom phrase"
   - **Refresh interval** — how often new content is fetched (10 min
     to 3 hrs)
   - **DeepSeek model** — Flash (fast/cheap, default) or Pro

## Local development

```sh
# Render a single frame to preview.webp
pixlet render vestabyt.star api_key=YOUR_KEY category=quote refresh_minutes=30 -o preview.webp

# Or serve it live in a browser with hot reload
pixlet serve vestabyt.star
```

Available `category` values: `random`, `quote`, `fact`, `joke`,
`onthisday`, `word`, `custom` (pair with `custom_phrase=...`).

## Notes / known limitations

- **"On this day" accuracy**: DeepSeek occasionally gets historical
  dates slightly wrong (LLMs aren't a fact database). Treat it as fun
  trivia, not a verified almanac.
- **Model note**: `deepseek-chat` / `deepseek-reasoner` are being
  deprecated 2026-07-24; this app uses the current `deepseek-v4-flash`
  / `deepseek-v4-pro` models instead. `thinking` is explicitly disabled
  in the request since we only want a short direct answer, not
  chain-of-thought reasoning eating the token budget.
