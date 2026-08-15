# kitty

Source: `home/programs/kitty.nix`.

```nix
{ config, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      confirm_os_window_close = 0;
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty-wallust-socket";
    };
    extraConfig = ''
      include ${config.home.homeDirectory}/.cache/wallust/kitty-colors.conf
    '';
  };
}
```

## Settings

- `font.name` / `font.size`: JetBrainsMono Nerd Font, size 11 — matches the
  Nerd Font installed system-wide in `hosts/nixos/configuration.nix` (see
  [system.md](system.md)) and the font every other themed app references.
- `confirm_os_window_close = 0`: closing the last kitty window doesn't
  prompt for confirmation.
- `allow_remote_control = "yes"` + `listen_on =
  "unix:/tmp/kitty-wallust-socket"`: a **fixed** control-socket path, not
  kitty's default per-instance socket. This exists specifically so
  wallust's reload hook (`kitty @ --to unix:/tmp/kitty-wallust-socket
  load-config`, see [theming.md](theming.md)) can reach a running kitty
  instance from *outside* any kitty session — the hook process has no
  `$KITTY_LISTEN_ON` env var to fall back on, since it isn't running inside
  kitty itself.

## Colors: no static values here

Earlier versions of this file set `background`/`foreground`/`color0`–`color7`
directly from a static `home/theme.nix` palette, passed in as a module
argument (`{ theme }: { pkgs, ... }: { ... }`). That's gone — colors now
come entirely from `extraConfig`'s `include` line, which pulls in
`~/.cache/wallust/kitty-colors.conf` at *config-load* time, not Nix
build time. See [theming.md](theming.md) for the full architecture; the
short version is that this lets a wallpaper change re-theme kitty instantly
without a rebuild, by reloading kitty's config (which re-reads the
`include`), rather than by changing anything Nix-managed.

## Reloading after a wallpaper change

New kitty windows/tabs pick up the new colors immediately. Already-open
windows update as soon as wallust's hook fires
`kitty @ --to unix:/tmp/kitty-wallust-socket load-config` — no manual action
needed if that hook succeeds silently in the background.
