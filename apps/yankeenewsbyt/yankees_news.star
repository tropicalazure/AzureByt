"""
Yankees News - an AI-powered Pixlet app for Tidbyt / TronByt.
Pulls live Yankees headlines from Google News RSS, then asks DeepSeek to
summarize them into a short blurb. Refreshes at most every 30 minutes.

Why RSS + DeepSeek? deepseek-chat has no internet access, so we feed it real,
current headlines (RAG) instead of asking it to recall the news from memory.
64x32 display.
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")
load("xpath.star", "xpath")

# --- Constants ---------------------------------------------------------------

NEWS_RSS = "https://news.google.com/rss/search?q={}&hl=en-US&gl=US&ceid=US:en"
DEEPSEEK_URL = "https://api.deepseek.com/chat/completions"
MODEL = "deepseek-chat"

REFRESH = 1800  # seconds -> re-fetch + re-summarize at most every 30 min

NAVY = "#0c2340"
WHITE = "#ffffff"
GREY = "#9aa4b2"
BLACK = "#000000"

SYSTEM_PROMPT = "You summarize sports news. Given recent headlines, write a " + \
                "2-sentence summary of the latest news. Max 160 characters. " + \
                "No preamble, no emoji, no hashtags."

# --- Data fetch --------------------------------------------------------------

def get_headlines(query):
    url = NEWS_RSS.format(query.replace(" ", "%20"))
    resp = http.get(url, ttl_seconds = REFRESH)
    if resp.status_code != 200:
        return []
    doc = xpath.loads(resp.body())
    titles = doc.query_all("/rss/channel/item/title")
    return titles[:6]

def summarize(api_key, headlines):
    context = "\n".join(["- " + h for h in headlines])
    body = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": "Recent headlines:\n" + context},
        ],
        "max_tokens": 120,
        "temperature": 0.4,
        "stream": False,
    }
    resp = http.post(
        DEEPSEEK_URL,
        headers = {"Authorization": "Bearer " + api_key},
        json_body = body,
        ttl_seconds = REFRESH,
    )
    if resp.status_code != 200:
        return None
    choices = resp.json().get("choices", [])
    if len(choices) == 0:
        return None
    return choices[0]["message"]["content"].strip()

# --- Render ------------------------------------------------------------------

def root(label, text, color):
    return render.Root(
        delay = 80,
        child = render.Box(
            color = BLACK,
            child = render.Column(
                children = [
                    render.Box(
                        width = 64,
                        height = 8,
                        color = NAVY,
                        child = render.Text(label, font = "tom-thumb", color = WHITE),
                    ),
                    render.Marquee(
                        height = 24,
                        scroll_direction = "vertical",
                        child = render.WrappedText(
                            content = text,
                            font = "tom-thumb",
                            color = color,
                            width = 64,
                            align = "center",
                        ),
                    ),
                ],
            ),
        ),
    )

# --- Main --------------------------------------------------------------------

def main(config):
    api_key = config.str("api_key", "")
    query = config.str("query", "New York Yankees")

    # Short header label from the query (e.g. "New York Yankees" -> "YANKEES").
    label = query.split(" ")[-1].upper()[:10]

    if api_key == "":
        return root("NEWS", "Add your DeepSeek API key in settings", GREY)

    headlines = get_headlines(query)
    if len(headlines) == 0:
        return root(label, "No headlines found right now", GREY)

    summary = summarize(api_key, headlines)
    if summary == None:
        return root(label, "DeepSeek unavailable - check key/quota", GREY)

    return root(label, summary, WHITE)

# --- Schema ------------------------------------------------------------------

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "DeepSeek API Key",
                desc = "Your DeepSeek API key (starts with sk-).",
                icon = "key",
            ),
            schema.Text(
                id = "query",
                name = "News topic",
                desc = "What to summarize, e.g. 'New York Yankees'.",
                icon = "baseball",
            ),
        ],
    )
