# spotify-player

A terminal Spotify client ([aome510/spotify-player](https://github.com/aome510/spotify-player)),
package name `spotify-player` in nixpkgs (binary `spotify_player`).

Launched with `SUPER + SHIFT + S` (kitty, class `spotify-player` — see
`hyprland.nix`), or just run `spotify_player` in any terminal.

## Why this one, alongside lazyspotify

[lazyspotify](lazyspotify.md) needs a personal Spotify Developer Dashboard
app (its own `client_id`) and does its own OAuth dance through a browser +
system keyring, which is where the `INVALID_CREDENTIALS` /
"max daemon retry breached" trouble came from. `spotify-player` avoids all
of that:

- It ships with its own default OAuth client baked into the binary — no
  Developer Dashboard app to register, no `client_id` to keep out of git.
- Its nixpkgs build (`pkgs/by-name/sp/spotify-player/package.nix`) already
  enables `streaming` + `rodio-backend` (ALSA on Linux) by default, so it
  has a working built-in `librespot` playback engine out of the box —
  nothing extra to wire up in this repo.

Because it needs no secrets, it's fully Nix-managed via plain
`home.packages` (`home/home.nix`) — unlike lazyspotify there's no
`xdg.configFile` here either; its config is optional and, if you want to
customize it, lives at `~/.config/spotify-player/app.toml` (not tracked by
Nix, since it's just user preference, not secrets — feel free to leave it
untouched).

## First run

1. Run `spotify_player` (or `SUPER + SHIFT + S`).
2. It prints an OAuth URL and opens your browser for Spotify login/consent.
3. Token gets cached under `~/.cache/spotify-player/`; subsequent runs
   reuse it silently.
4. Requires a Spotify Premium account for playback, same as any
   librespot-based client (lazyspotify included).

## Troubleshooting

If playback fails to start, check `spotify_player`'s own log
(`~/.cache/spotify-player/spotify-player.log` by default) rather than
guessing from the TUI — same lesson learned from lazyspotify's
`daemon.log` masking its real error behind a generic
"daemon exited"-style message.
