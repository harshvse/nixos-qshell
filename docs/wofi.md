# wofi

Source: `home/programs/wofi.nix`. Covers both the app launcher itself and
the wallpaper picker built on top of it — they share one file since the
picker is just a wofi invocation plus a small wrapper script.

## App launcher

```nix
programs.wofi = {
  enable = true;
  settings = {
    width = 500;
    height = 400;
    location = "center";
    show = "drun";
    prompt = "Search";
    allow_images = true;
  };
  style = '' ... '';
};
```

Bound to `SUPER + R` in `hyprland.nix` (`wofi --show drun` — app-launcher
mode, listing installed `.desktop` entries). `allow_images = true` lets it
render app icons in that mode.

## Styling — same pattern as waybar

```nix
style = ''
  @import url("file://${config.home.homeDirectory}/.cache/wallust/wofi-colors.css");

  window { background-color: @background; color: @foreground; border: 2px solid @color4; ... }
  #entry:selected { background-color: @color4; color: @background; ... }
'';
```

Colors come from wallust's generated `wofi-colors.css` via `@import`, same
mechanism as waybar — see [theming.md](theming.md). Font: JetBrainsMono
Nerd Font, 13px.

## The wallpaper picker (`wallpaper-select`)

```nix
wallpaperSelect = pkgs.writeShellApplication {
  name = "wallpaper-select";
  runtimeInputs = [ pkgs.wofi pkgs.wallust pkgs.awww pkgs.findutils pkgs.coreutils ];
  text = ''
    mkdir -p "${wallpaperDir}"

    selected=$(find "${wallpaperDir}" -maxdepth 1 -type f | sort | wofi --dmenu -p "Wallpaper")
    [ -z "$selected" ] && exit 0

    awww img "$selected" --transition-type wipe --transition-fps 60
    wallust run "$selected"
  '';
};
```

Bound to `SUPER + W`. Lists every file directly under
`~/Pictures/wallpapers/` (non-recursive) as a `wofi --dmenu` text list —
**no thumbnails**: wofi has no image-preview mode for arbitrary files
(unlike rofi's icon-mode scripting), so this is filenames only. Known,
accepted limitation, not a bug to fix casually — switching launchers would
be a bigger decision than this task warranted.

Picking a file:
1. `awww img <file> --transition-type wipe --transition-fps 60` — sets the
   wallpaper via the `awww` daemon (nixpkgs's renamed `swww` — see
   [theming.md](theming.md)) with a wipe transition at 60fps.
2. `wallust run <file>` — regenerates every themed app's palette from that
   image (see [theming.md](theming.md) for the full template/hook list).

Note the package is still referenced as `pkgs.awww` in `runtimeInputs` (not
`pkgs.swww` — that alias exists but the actual binaries inside are
`awww`/`awww-daemon`, confirmed by inspecting the built package's `bin/`).

## Requires `awww-daemon` to already be running

This script only *tells* the daemon what to show — it doesn't start one.
`awww-daemon` is launched via Hyprland's autostart block (see
[hyprland.md](hyprland.md)); if it isn't running (e.g. a live session that
predates that config), `awww img` fails silently against a missing socket
and nothing visibly changes even though `wallust run` still succeeds.
