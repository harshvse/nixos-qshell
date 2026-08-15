# mako

Source: `home/programs/mako.nix`.

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.mako ];
}
```

That's the entire file — just the package. This is deliberate, not
incomplete: mako's config file (`~/.config/mako/config`) is owned entirely
by wallust at runtime (its `[templates.mako]` entry in `wallust.toml`
targets that path directly and renders the whole file — font, size,
padding, border, timeout, *and* colors — from a single template; see
[theming.md](theming.md)).

It is intentionally **not** managed here via home-manager's `services.mako`
module, because that module would create `~/.config/mako/config` as a
read-only symlink into the Nix store. wallust needs to overwrite that exact
path as a plain mutable file every time the palette regenerates — a
home-manager-managed symlink there would fight it (either failing to write,
since the store is read-only, or requiring wallust to unlink and replace
the symlink, which isn't how this was verified to behave).

## What actually populates the config

`wallust.nix`'s `home.activation.wallustSeed` ensures
`~/.config/mako/` exists, and the first `wallust run` (either that seed run,
or the first time you pick a wallpaper via `SUPER+W`) writes the real
`config` file from the `mako-config` template — see
[theming.md](theming.md)'s template table for the full content (font,
dimensions, `[urgency=low]`/`[urgency=high]` overrides, and colors from the
current palette).

## Launch and reload

Launched via Hyprland's `hyprland.start` autostart block (see
[hyprland.md](hyprland.md)), not a home-manager systemd service — same
reasoning as waybar (keep autostart centralized). Reloaded after a
wallpaper change via wallust's `[hooks]` entry: `makoctl reload`.

Test it any time with `notify-send "title" "body"`.
