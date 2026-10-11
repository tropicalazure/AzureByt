# AzureByt -- agent guide

Personal Pixlet / Starlark applications for Tidbyt displays, served through Tronbyt on the Azure home server.

## Structure

- Every app lives in its own subdirectory under `apps/<app_id>/`.
- Standard files per app:
  - `<filename>.star`: Starlark code targeting 64x32 display resolution.
  - `manifest.yaml`: Required Tronbyt metadata schema (`id`, `name`, `summary`, `desc`, `author: marka`, `fileName`, `packageName`).
  - Optional `.webp` or `.gif` visual preview.

## Rules

- Never commit API keys, personal tokens, passwords, or IP secrets into `.star` files. Use Pixlet schema inputs (`schema.Text`, `schema.Toggle`, etc.) for user-configurable options.
- The repository must keep the top-level `apps/` directory intact so Tronbyt's indexer can locate applications.
- Run `pixlet check apps/<app_id>/<filename>.star` to validate syntax and imports before committing new apps.
