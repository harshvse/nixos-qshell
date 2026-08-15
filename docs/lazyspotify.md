# lazyspotify

A terminal Spotify client ([dubeyKartikay/lazyspotify](https://github.com/dubeyKartikay/lazyspotify)).
The package is installed via `home.packages` in `home/home.nix`; there's no
dedicated `home/programs/lazyspotify.nix` because its config holds a
per-account Spotify client ID that must never end up in this (public) repo
— see below.

Launched with `SUPER + S` (kitty, class `lazyspotify` — see `hyprland.nix`),
or just run `lazyspotify` in any terminal.

## Why this isn't Nix-managed

Every other program in this repo has its config written declaratively via
Nix (`xdg.configFile`, `programs.*.settings`, etc.), tracked in git. This
one is the exception: lazyspotify's config file holds `auth.client_id`,
which is tied to a Spotify Developer app registered under *your own*
Spotify account. Committing it to `home/programs/*.nix` would mean it ends
up readable in this repo's git history, on a public GitHub repo, forever.
So instead `~/.config/lazyspotify/config.yml` is a plain file living
outside the Nix store, edited directly — same reasoning as the wallust
cache files in [theming.md](theming.md), just for a secret instead of a
live-reloadable value.

## One-time setup

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   and create an app:
   - Name/description: anything (e.g. "lazyspotify")
   - Redirect URI: `http://127.0.0.1:8287/callback` (lazyspotify's default —
     change this and the config's `auth.port`/`auth.redirect-endpoint`
     together if you ever need a different port)
   - APIs used: Web API, Web Playback SDK
2. Copy the app's **Client ID** (not the client secret — lazyspotify's
   default config doesn't need it).
3. Edit `~/.config/lazyspotify/config.yml`:

   ```yaml
   auth:
     client_id: <paste your client ID here>
   ```

4. Run `lazyspotify` — first run opens a browser for the Spotify OAuth
   login/consent, then stores the resulting token in your system keyring
   (service `spotify`, key `token-v2`). Subsequent runs reuse it silently.
   This needs a Secret Service provider actually running — a bare Hyprland
   setup doesn't have one by default; see
   [system.md](system.md#secret-service-keyring-gnome-keyring) for the
   `gnome-keyring` + SDDM PAM integration that provides it.

## Config reference

Full path: `~/.config/lazyspotify/config.yml` (YAML). Anything under `auth`
can also be set via environment variable instead, with `.`/`-` replaced by
`_` (e.g. `AUTH_CLIENT_ID`), if you'd rather not put it in the file at all.

| Key | Default | Purpose |
|---|---|---|
| `auth.client_id` | — (required) | Your Spotify app's client ID |
| `auth.host` | `127.0.0.1` | OAuth callback server host |
| `auth.port` | `8287` | OAuth callback server port |
| `auth.redirect-endpoint` | `/callback` | OAuth callback path |
