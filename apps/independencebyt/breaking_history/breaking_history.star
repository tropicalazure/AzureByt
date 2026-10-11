"""
Applet: Breaking History
Summary: 250 years of breaking news
Description: A "Breaking News" style ticker cycling through 50 pivotal
moments in American history, from the Declaration of Independence to
the Semiquincentennial, grouped into five eras.
Author: markamccray
"""

load("render.star", "render")

WIDTH = 64
HEIGHT = 32

RED = "#C8102E"
DARK_RED = "#5C0A15"
BLUE = "#0A1F44"
GOLD = "#FFD700"
WHITE = "#FFFFFF"
BLACK = "#000000"
DARK = "#141414"

NEWS_FRAMES = 22
ERA_FRAMES = 16
DELAY_MS = 90

ERAS = [
    ("1776-1850", "FOUNDING & FORGING A NATION"),
    ("1851-1900", "INNOVATION & EXPANSION"),
    ("1901-1950", "THE INDUSTRIAL & TECH BOOM"),
    ("1951-1990", "SPACE, RIGHTS & DIGITAL AGE"),
    ("1991-2026", "THE MODERN FRONTIER"),
]

EVENTS_BY_ERA = [
    [
        ("PHILADELPHIA", "JULY 4, 1776", "Rebellion! 13 Colonies Formally Declare Independence"),
        ("PHILADELPHIA", "SEPT 17, 1787", "Miracle in Philly: Delegates Forge a New Constitution"),
        ("SAVANNAH, GA", "MARCH 14, 1794", "Industrial Revolution: Cotton Gin Patented"),
        ("PARIS, FR", "APRIL 30, 1803", "The Great Expansion: US Doubled by Louisiana Purchase"),
        ("ST. LOUIS, MO", "MAY 14, 1804", "Into the Unknown: Lewis & Clark Set Sail West"),
        ("NEW YORK, NY", "AUGUST 17, 1807", "Steamboat Epoch: Fulton Defies the Wind"),
        ("ROME, NY", "OCT 26, 1825", "Engineering Triumph: Erie Canal Officially Opens"),
        ("WASHINGTON", "MAY 24, 1844", "Lightning Speaks: Morse Sends First Instant Message"),
        ("COLOMA, CA", "JAN 24, 1848", "Gold Rush! Fortune Discovered at Sutter's Mill"),
    ],
    [
        ("GETTYSBURG, PA", "NOV 19, 1863", "A New Birth of Freedom: Lincoln Redefines the Nation"),
        ("WASHINGTON", "DEC 6, 1865", "Slavery Abolished! 13th Amendment Formally Ratified"),
        ("PROMONTORY, UT", "MAY 10, 1869", "Coast-to-Coast: Transcontinental Railroad United"),
        ("BOSTON, MA", "MARCH 7, 1876", "The Human Voice, Wired: Bell Patents Telephone"),
        ("MENLO PARK, NJ", "DEC 31, 1879", "Darkness Conquered: Edison Unveils Light Bulb"),
        ("NEW YORK, NY", "MAY 24, 1883", "Eighth Wonder: Mighty Brooklyn Bridge Welcomes Millions"),
        ("NEW YORK, NY", "OCT 28, 1886", "Liberty Enlightens the World: Iconic Statue Dedicated"),
        ("CHICAGO, IL", "MAY 1, 1893", "City of Light: World's Fair Unleashes AC Power"),
        ("DETROIT, MI", "JUNE 4, 1896", "Dawn of the Auto Age: Ford Tests First Quadricycle"),
    ],
    [
        ("KITTY HAWK, NC", "DEC 17, 1903", "Humanity Airborne! Wrights Achieve Powered Flight"),
        ("DETROIT, MI", "OCT 1, 1908", "Revolutionizing the Road: First Model T Rolls Off Line"),
        ("PANAMA", "AUGUST 15, 1914", "Conquering Continents: Panama Canal Opens to Global Trade"),
        ("WASHINGTON", "AUGUST 18, 1920", "Democracy Expanded: 19th Amendment Secures Women's Vote"),
        ("PARIS, FR", "MAY 21, 1927", "Lone Eagle: Lindbergh Conquers the Atlantic Solo"),
        ("NEW YORK, NY", "OCT 6, 1927", "Cinema Speaks: 'The Jazz Singer' Shocks Audiences"),
        ("BOULDER CITY, NV", "MARCH 1, 1936", "Taming the Canyon: Epic Hoover Dam Completed"),
        ("SAN FRANCISCO", "MAY 27, 1937", "Golden Gate Unleashed: Landmark Span Opens"),
        ("PHILADELPHIA", "FEB 15, 1946", "The Electronic Brain: ENIAC Computer Unveiled"),
        ("BROOKLYN, NY", "APRIL 15, 1947", "Breaking the Barrier: Jackie Robinson Takes the Field"),
        ("MUROC, CA", "OCT 14, 1947", "Shattering the Sky: Yeager Breaks the Sound Barrier"),
    ],
    [
        ("PITTSBURGH, PA", "MARCH 26, 1953", "Medical Breakthrough: Salk Announces Polio Vaccine"),
        ("WASHINGTON", "MAY 17, 1954", "Equal Justice: Supreme Court Strikes Down Segregation"),
        ("WASHINGTON", "JUNE 29, 1956", "Building Modern America: Interstate Highway Act Passes"),
        ("WASHINGTON", "JULY 29, 1958", "Destination Stars: Space Age Begins with NASA"),
        ("CAPE CANAVERAL", "FEB 20, 1962", "Friendship 7: John Glenn Orbits the Earth"),
        ("WASHINGTON", "AUGUST 28, 1963", "A Nation Inspired: King Delivers 'I Have a Dream'"),
        ("THE MOON", "JULY 20, 1969", "Eagle Has Landed! Americans Walk on the Moon"),
        ("LOS ANGELES", "OCT 29, 1969", "Dawn of the Net: First Computer-to-Computer Link"),
        ("SANTA CLARA, CA", "NOV 15, 1971", "Silicon Revolution: Intel Launches Microprocessor"),
        ("CAPE CANAVERAL", "SEPT 5, 1977", "Message to the Cosmos: Voyager 1 Rockets into Deep Space"),
        ("CAPE CANAVERAL", "APRIL 12, 1981", "Dawn of the Shuttle: Columbia Roars into Orbit"),
        ("BOCA RATON, FL", "AUGUST 12, 1981", "Tech in the Living Room: IBM Introduces PC"),
        ("CAPE CANAVERAL", "APRIL 24, 1990", "Window to the Universe: Hubble Telescope Deployed"),
    ],
    [
        ("MARS", "JULY 4, 1997", "Red Planet Invasion: Pathfinder Rover Lands on Mars"),
        ("BAIKONUR", "NOV 20, 1998", "Outpost in the Heavens: Space Station Era Begins"),
        ("WASHINGTON", "JUNE 26, 2000", "Cracking the Code of Life: Human Genome Mapped"),
        ("CUPERTINO, CA", "JUNE 29, 2007", "Pocket Revolution: Apple Unveils the iPhone"),
        ("PLUTO", "JULY 14, 2015", "Edge of the Solar System: New Horizons Sweeps Past Pluto"),
        ("KOUROU, GF", "DEC 25, 2021", "Cosmic Time Machine: James Webb Telescope Launches"),
        ("CAPE CANAVERAL", "NOV 16, 2022", "Next Generation Moon Shot: Artemis I Soars"),
        ("MARYSVILLE, OH", "JULY 4, 2026", "The Semiquincentennial: America Celebrates 250 Years!"),
    ],
]

def banner(label, bg_color):
    return render.Box(
        width = WIDTH,
        height = 9,
        color = bg_color,
        child = render.Padding(
            pad = (2, 2, 0, 0),
            child = render.Text(content = label, font = "tom-thumb", color = WHITE),
        ),
    )

def ticker(text, bg_color, text_color):
    return render.Box(
        width = WIDTH,
        height = HEIGHT - 9 - 1,
        color = bg_color,
        child = render.Padding(
            pad = (0, 7, 0, 0),
            child = render.Marquee(
                width = WIDTH,
                child = render.Text(content = text, font = "tb-8", color = text_color),
            ),
        ),
    )

def divider(color):
    return render.Box(width = WIDTH, height = 1, color = color)

def news_card(loc, date, headline):
    text = (loc + " - " + date + ": " + headline).upper()
    return render.Column(
        children = [
            banner("BREAKING NEWS", RED),
            divider(GOLD),
            ticker(text, BLACK, GOLD),
        ],
    )

def era_card(year_range, subtitle):
    text = (year_range + ": " + subtitle).upper()
    return render.Column(
        children = [
            banner("NEW ERA", BLUE),
            divider(GOLD),
            ticker(text, BLUE, WHITE),
        ],
    )

def main(config):
    segments = []

    for era_index, era in enumerate(ERAS):
        year_range, subtitle = era
        card = era_card(year_range, subtitle)
        segments.append(render.Animation(children = [card for _ in range(ERA_FRAMES)]))

        for (loc, date, headline) in EVENTS_BY_ERA[era_index]:
            card = news_card(loc, date, headline)
            segments.append(render.Animation(children = [card for _ in range(NEWS_FRAMES)]))

    return render.Root(
        delay = DELAY_MS,
        child = render.Sequence(children = segments),
    )
