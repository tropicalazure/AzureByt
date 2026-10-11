# AzureByt

A collection of custom, handcrafted [Pixlet / Starlark](https://github.com/tidbyt/pixlet) apps designed for Tidbyt displays and managed via [Tronbyt Server](https://github.com/tronbyt/server).

## Apps in this Repository

| App ID | Name | Description |
| :--- | :--- | :--- |
| `america250byt` | **America250Byt** | Semiquincentennial celebration animation with fireworks & official logo |
| `clockbyt` | **ClockByt** | Seamless retro animated clock with flip and digital styling |
| `deepbyt` | **DeepByt** | Live reasoning status, tokens, and AI insights from DeepSeek |
| `dolphinbyt` | **DolphinByt** | Smooth pixel-art animated scene of dolphins swimming through the ocean |
| `hauntbyt` | **HauntByt** | Spooky animated haunted house with ghosts, bats, lightning, and pumpkins |
| `independencebyt` | **IndependenceByt** | 4th of July celebration with fireworks and historic scenes |
| `mlbstandingsbyt` | **MLBStandingsByt** | Live Major League Baseball division standings and wild card races |
| `petbyt` | **PetByt** | Virtual animated pixel desktop pet that idles and celebrates |
| `pokebyt` | **PokeByt** | Random Pokémon sprite, stats, and Pokédex info display |
| `serverbyt` | **ServerByt** | Home server health monitor (CPU, memory, disk, temps) |
| `tropicbyt` | **TropicByt** | Animated tropical pirate beach scene with palm trees, waves, and ships |
| `vestabyt` | **VestaByt** | Vesta board and smart home tracker |
| `worldcupbyt` | **WorldCupByt** | FIFA World Cup live match tracker, fixtures, and group standings |
| `yankeebyt` | **YankeeByt** | New York Yankees live game tracker with score, count, and bases |
| `yankeenewsbyt` | **YankeeNewsByt** | New York Yankees news headlines and roster updates |

## Usage with Tronbyt

To add these apps to your Tronbyt Server:

1. Open **Tronbyt Manager** (`http://<your-server-ip>:8000`).
2. Go to **System Settings** -> **Custom Apps Repository**.
3. Set the repository URL to:
   ```text
   https://github.com/tropicalazure/AzureByt.git
   ```
4. Click **Save**. Tronbyt will automatically clone the repository and index all apps into your App Catalog.

## Developing Apps

Each app resides in `apps/<app_id>/` and contains:
- `<filename>.star`: The Starlark source code rendered by Pixlet.
- `manifest.yaml`: Metadata (`id`, `name`, `summary`, `desc`, `author`, `fileName`, `packageName`).
- Optional preview images (`.webp`, `.gif`, `.png`).

Preview an app locally with Pixlet:
```bash
pixlet serve apps/<app_id>/<filename>.star
```
Render an app to WebP:
```bash
pixlet render apps/<app_id>/<filename>.star
```
