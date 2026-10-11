"""
DeepSeek Fun Fact - a simple AI-powered Pixlet app for Tidbyt / TronByt.
Asks the DeepSeek API for one short fun fact and scrolls it on the display.
Single data source: the DeepSeek chat API (OpenAI-compatible).
The API key is read from the app config so it is never hardcoded.
64x32 display.
"""

load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("schema.star", "schema")

# --- Constants ---------------------------------------------------------------

DEEPSEEK_URL = "https://api.deepseek.com/chat/completions"
MODEL = "deepseek-chat"

WHITE = "#ffffff"
BLUE = "#4d6bff"  # DeepSeek-ish blue for the header
GREY = "#9aa4b2"
BLACK = "#000000"

# Keep the reply tiny so it fits a 64x32 grid.
SYSTEM_PROMPT = "Write a single delightful fun fact about a random animal. Max 90 characters. " + \
                "No quotes, no preamble, no emoji. Just the fact."

# --- Data fetch --------------------------------------------------------------

def get_fact(api_key):
    if api_key == "":
        return None

    # Including today's date makes the fact roll over daily; ttl_seconds caps
    # how often we actually call DeepSeek (so Tidbyt re-renders are free).
    today = time.now().format("2006-01-02")
    body = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": "Give me a fun fact for " + today},
        ],
        "max_tokens": 60,
        "temperature": 1.1,
        "stream": False,
    }

    resp = http.post(
        DEEPSEEK_URL,
        headers = {"Authorization": "Bearer " + api_key},
        json_body = body,
        ttl_seconds = 21600,  # cache 6h
    )
    if resp.status_code != 200:
        return None

    choices = resp.json().get("choices", [])
    if len(choices) == 0:
        return None
    return choices[0]["message"]["content"].strip()

# --- Render ------------------------------------------------------------------

def header():
    return render.Box(
        width = 64,
        height = 8,
        color = BLUE,
        child = render.Text("ANIMAL FACTS", font = "tom-thumb", color = WHITE),
    )

def body_text(text, color):
    return render.Marquee(
        height = 24,
        scroll_direction = "vertical",
        child = render.WrappedText(
            content = text,
            font = "tom-thumb",
            color = color,
            width = 64,
            align = "center",
        ),
    )

# --- Main --------------------------------------------------------------------

def main(config):
    api_key = config.str("api_key", "")

    fact = get_fact(api_key)
    if fact == None:
        if api_key == "":
            text, color = ("Add your DeepSeek API key in settings", GREY)
        else:
            text, color = ("DeepSeek unavailable - check key/quota", GREY)
    else:
        text, color = (fact, WHITE)

    return render.Root(
        delay = 80,
        child = render.Box(
            color = BLACK,
            child = render.Column(
                children = [
                    header(),
                    body_text(text, color),
                ],
            ),
        ),
    )

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
        ],
    )
