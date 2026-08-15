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
| [waybar.md](waybar.md) | `home/programs/waybar.nix` |
| [wofi.md](wofi.md) | `home/programs/wofi.nix` — launcher + the wallpaper picker |
| [mako.md](mako.md) | `home/programs/mako.nix` |
| [btop.md](btop.md) | `home/programs/btop.nix` |
| [neovim.md](neovim.md) | `home/programs/neovim.nix` |
| [fish.md](fish.md) | `home/programs/fish.nix` — shell + starship prompt |
| [gtk-qt.md](gtk-qt.md) | `home/programs/gtk-qt.nix` — GTK/Qt app theming |

## How the pieces fit together

```
flake.nix
  └─ hosts/nixos/configuration.nix   (system: boot, drivers, SDDM, users)
       └─ home-manager module
            └─ home/home.nix          (imports every module below + loose packages)
                 ├─ programs/fish.nix
                 ├─ programs/kitty.nix
                 ├─ programs/neovim.nix
                 ├─ programs/hyprland.nix
                 ├─ programs/wallust.nix   ← palette engine, everything else reads from it
                 ├─ programs/waybar.nix
                 ├─ programs/wofi.nix
                 ├─ programs/mako.nix
                 ├─ programs/btop.nix
                 └─ programs/gtk-qt.nix
```

`home/theme.nix` (a static hardcoded palette) existed early on and has since
been deleted — `wallust.nix` replaced it as the single source of truth for
color. If you find an old reference to it anywhere outside these docs'
history, it's stale.
