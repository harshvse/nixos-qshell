# docs/

Detailed reference for everything configured in this repo — one file per
program/subsystem, written against the config as it exists right now. The
top-level `../README.md` is the quickstart (first boot, day-to-day rebuild
workflow, hybrid-graphics troubleshooting); these files are the "what is
actually configured, and why" reference for when you need to change or
understand something specific.

Every file below cites the Nix source path it documents — when in doubt,
that file on disk is the ground truth; these docs describe it.

## Index

| File | Covers |
|---|---|
| [system.md](system.md) | NixOS system layer: `hosts/nixos/configuration.nix` — boot, networking, hybrid NVIDIA/Intel graphics, SDDM, audio, fonts, user account |
| [flake.md](flake.md) | `flake.nix` — inputs, how the host and home-manager are wired together |
| [theming.md](theming.md) | The wallust-driven, wallpaper-reactive theming system — the architecture that ties every app below together |
| [hyprland.md](hyprland.md) | `home/programs/hyprland.nix` — monitors, input, keybinds, animations, autostart |
| [kitty.md](kitty.md) | `home/programs/kitty.nix` |
| [quickshell/README.md](quickshell/README.md) | `quickshell/` (QML) + `home/programs/quickshell.nix` (links it in) — status bar (bootstrap only, WIP) |
| [wofi.md](wofi.md) | `home/programs/wofi.nix` — launcher + the wallpaper picker |
| [mako.md](mako.md) | `home/programs/mako.nix` |
| [btop.md](btop.md) | `home/programs/btop.nix` |
| [neovim.md](neovim.md) | `home/programs/neovim.nix` |
| [vscode.md](vscode.md) | `home/programs/vscode.nix` — extensions, settings, wallust-driven theme |
| [fish.md](fish.md) | `home/programs/fish.nix` — shell + starship prompt |
| [gtk-qt.md](gtk-qt.md) | `home/programs/gtk-qt.nix` — GTK/Qt app theming |
| [lazyspotify.md](lazyspotify.md) | Spotify TUI — package in `home/home.nix`, config deliberately NOT Nix-managed (holds a personal Spotify client ID) |
| [spotify-player.md](spotify-player.md) | Spotify TUI alternative — fully Nix-managed, no personal Spotify app/secret needed |

## How the pieces fit together

```
flake.nix
  └─ hosts/nixos/configuration.nix   (system: boot, drivers, SDDM, users)
       └─ home-manager module
            └─ home/home.nix          (imports every module below + loose packages)
                 ├─ programs/fish.nix
                 ├─ programs/kitty.nix
                 ├─ programs/neovim.nix
                 ├─ programs/vscode.nix
                 ├─ programs/hyprland.nix
                 ├─ programs/wallust.nix   ← palette engine, everything else reads from it
                 ├─ programs/quickshell.nix   ← links in ../../quickshell/ (QML, repo root)
                 ├─ programs/wofi.nix
                 ├─ programs/mako.nix
                 ├─ programs/btop.nix
                 └─ programs/gtk-qt.nix

quickshell/              (repo root, not under home/) — plain QML, not Nix-templated
  └─ shell.qml
```

`home/theme.nix` (a static hardcoded palette) existed early on and has since
been deleted — `wallust.nix` replaced it as the single source of truth for
color. If you find an old reference to it anywhere outside these docs'
history, it's stale.
