# Hyprland

Source: `home/programs/hyprland.nix`.

## Config format: Lua, not hyprlang

```nix
wayland.windowManager.hyprland = {
  enable = true;
  xwayland.enable = true;
  configType = "lua";
  extraConfig = '' ... '';
};
```

Hyprland's native config language used here is Lua (`hyprland.lua`), not the
older `hyprlang`/`.conf` format. The whole config is written as raw
`extraConfig` text rather than home-manager's `settings` attrset, because
home-manager's Nix→Lua generator currently mangles the `"$mod"`-style
variable trick used for keybind modifiers (see
[nix-community/home-manager#9468](https://github.com/nix-community/home-manager/issues/9468)).
A plain `local mainMod = "SUPER"` inside real Lua sidesteps that bug
entirely.

## Monitors

```lua
local monLeft  = "eDP-1"
local monRight = "HDMI-A-1"

hl.monitor({ output = monLeft,  mode = "1920x1080@144", position = "0x0",    scale = 1.25 })
hl.monitor({ output = monRight, mode = "1920x1080@100", position = "1536x0", scale = 1.25 })
```

- `monLeft`/`monRight` are the real connector names for this machine
  (`eDP-1` = laptop panel, `HDMI-A-1` = external monitor) — found via
  `hyprctl monitors` after first boot with both plugged in.
- **`position` is in logical (post-scale) space, not physical pixels.**
  `monLeft` is 1920 physical px wide at `scale = 1.25`, so its logical width
  is `1920 / 1.25 = 1536`. `monRight` must start at `x = 1536`, not `x =
  1920` — the naive physical-pixel value. Using the physical width leaves a
  384px logical gap between the two monitors that the mouse cursor cannot
  cross (nothing occupies that space in Hyprland's layout). This was an
  actual bug hit and fixed in this repo — if you ever add a third monitor or
  change either monitor's resolution/scale, recompute this the same way:
  `position of monitor N = sum of (physical_width / scale) for all monitors
  to its left`.

## Input

```lua
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = -0.5,
    },
    ...
})
```

`sensitivity` ranges `-1.0` (slowest) to `1.0` (fastest), default `0`.
Set to `-0.5` because the default cursor speed felt too fast on this
hardware. Adjust up/down in that range to taste.

## Borders — palette-driven

```lua
local ok, hyprColors = pcall(dofile, os.getenv("HOME") .. "/.cache/wallust/hyprland-colors.lua")
if not ok or not hyprColors then
    hyprColors = { active_border = "#89b4fa", inactive_border = "#45475a" }
end

hl.config({
    ...
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
        col = {
            active_border   = "rgb(" .. hyprColors.active_border:gsub("#", "") .. ")",
            inactive_border = "rgb(" .. hyprColors.inactive_border:gsub("#", "") .. ")",
        },
    },
})
```

Border colors come from wallust's generated palette (see
[theming.md](theming.md)) rather than a hardcoded value, so they follow the
wallpaper. The hardcoded `hyprColors` fallback only matters before the very
first `wallust run` has ever produced
`~/.cache/wallust/hyprland-colors.lua`.

> **Note**: `general.col.*` key naming here (mirroring hyprlang's dotted
> `general:col.active_border` key) is a best-effort translation into the Lua
> API's nested-table convention — it has not been independently confirmed
> against Hyprland's own Lua API docs. If borders don't pick up the
> generated colors after a `hyprctl reload`, this is the first thing to
> double-check.

## Autostart

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 0.5 && awww restore")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
end)
```

`hl.on("hyprland.start", fn)` is the Lua-API equivalent of `exec-once` —
fires only on a fresh compositor start, not on every config reload (there is
a separate `"config.reloaded"` event for that, unused here). Launches the
wallpaper daemon (`awww-daemon`), restores the last wallpaper, and starts
waybar + mako. See [theming.md](theming.md) for why these are launched here
rather than via each program's own home-manager `systemd.enable` /
`services.*` option, and for the operational gotcha that a *live* session
predating this block won't have these processes until the next
login/reboot.

## Animations

```lua
hl.curve("linear",       { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "windows",       enabled = true, speed = 2.5, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 2,   spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1,   bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1,   bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1,   bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 0.6, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1,   bezier = "almostLinear", style = "fade" })
```

- Named curves (`hl.curve(...)`) must be declared *before* any
  `hl.animation()` call references them — referencing an undeclared curve
  name (e.g. `"easy"` or `"almostLinear"` without the corresponding
  `hl.curve` call above them) produces a runtime error
  (`no such bezier "..."` / `no such spring "..."`). This was hit and fixed
  in this repo.
- `speed` is in deciseconds (`1 speed unit = 100ms`).
- Values here are roughly half Hyprland's own defaults — window
  open/close and workspace-switch animations felt too slow at the defaults,
  so speeds were tuned down (lower `speed` = faster).
- Key naming: `bezier = "..."` vs `spring = "..."` are **not**
  interchangeable — a spring-type curve (like `"easy"`) must be passed via
  the `spring` key, and a bezier-type curve (like `"linear"`,
  `"almostLinear"`) via the `bezier` key. Mixing them up produces the same
  "no such curve" error as an undeclared curve name.

## Keybinds

`mainMod = "SUPER"` throughout.

| Bind | Action |
|---|---|
| `SUPER + Return` | Launch kitty |
| `SUPER + Q` | Close focused window |
| `SUPER + M` | Exit Hyprland |
| `SUPER + V` | Toggle floating on focused window |
| `SUPER + R` | Launch wofi (`drun` mode — app launcher) |
| `SUPER + W` | Launch `wallpaper-select` — the wallpaper picker, see [theming.md](theming.md) |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + ←/→/↑/↓` | Move focus between windows in that direction |
| `SUPER + [0-9]` | Switch to workspace 1–10 (`0` maps to workspace 10) |
| `SUPER + SHIFT + [0-9]` | Move focused window to workspace 1–10 |
| `SUPER + scroll wheel` | Cycle to next/previous existing workspace |
| `SUPER + comma` / `SUPER + period` | Jump focus to the left/right monitor |
| `SUPER + SHIFT + comma` / `SUPER + SHIFT + period` | Move the active workspace to the left/right monitor |

## General

```lua
general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    layout = "dwindle",
}
```

Standard dwindle tiling layout with small gaps and a thin border (colored
per the palette-driven section above).
