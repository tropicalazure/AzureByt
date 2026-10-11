load("render.star", "render")
load("http.star", "http")
load("random.star", "random")

POKEAPI_BASE = "https://pokeapi.co/api/v2/pokemon/"

def main():
    # Pick a random Pokémon ID from Generation 1 to 9 (1 to 1025)
    pokemon_id = str(random.number(1, 1025))
    
    # Fetch data from PokéAPI
    res = http.get(POKEAPI_BASE + pokemon_id)
    if res.status_code != 200:
        return render.Root(child = render.Text("API Error"))
        
    pokemon_data = res.json()
    name = pokemon_data["name"].capitalize()
    
    # Navigate to the official high-resolution artwork URL
    artwork_url = pokemon_data["sprites"]["other"]["official-artwork"]["front_default"]
    
    if not artwork_url:
        return render.Root(child = render.Text("No Image"))

    # Resize the image to 26x26 to leave exactly 6 pixels of vertical room for the bottom banner
    resized_url = "https://wsrv.nl/?url=" + artwork_url + "&w=26&h=26&fit=contain"

    # Download the optimized, pre-shrunk image bytes
    image_res = http.get(resized_url)
    if image_res.status_code != 200:
        return render.Root(child = render.Text("Scale Error"))
        
    image_bytes = image_res.body()

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                # Top Box: Centered image area
                render.Box(
                    width = 64,
                    height = 26,
                    child = render.Image(
                        src = image_bytes,
                        width = 26,
                        height = 26,
                    )
                ),
                # Bottom Box: Edge-to-edge blue banner with centered marquee layout
                render.Box(
                    width = 64,
                    height = 6,
                    color = "#1B54A1", # Pokémon Blue
                    child = render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Marquee(
                                width = 60,
                                align = "center", # Centers the text when it's short enough to fit
                                child = render.Text(
                                    content = name,
                                    font = "tb-8", # Clean, tiny pixel font
                                    color = "#FFCC01" # Pokémon Yellow
                                )
                            )
                        ]
                    )
                )
            ]
        )
    )