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

## `systemd.enable = false` — required alongside UWSM

```nix
wayland.windowManager.hyprland.systemd.enable = false;
```

2026-08-15: login would drop to SDDM, log in, briefly show the desktop
cursor, then bounce straight back to the login screen — no crash report,
Hyprland's own log just stopped mid-startup. Root cause: home-manager's
`wayland.windowManager.hyprland` module defaults `systemd.enable = true`,
which injects a `hyprland.start` hook running
`systemctl --user stop hyprland-session.target && systemctl --user start
hyprland-session.target` to push env vars into systemd/dbus for
autostart units.

`hyprland-session.target` has `BindsTo=graphical-session.target` +
`PropagatesStopTo=graphical-session.target`. Since this machine uses UWSM
(`programs.hyprland.withUWSM` in `configuration.nix`), UWSM's own
`wayland-session@Hyprland.target` is *also* `BindsTo=graphical-session.target`,
and the actual compositor unit, `wayland-wm@Hyprland.service`, is
`BindsTo=wayland-session@Hyprland.target`. So stopping
`hyprland-session.target` cascades: → stops `graphical-session.target` →
stops `wayland-session@Hyprland.target` → stops `wayland-wm@Hyprland.service`
— i.e. home-manager's own startup hook was killing Hyprland itself a couple
seconds after login, every time. Confirmed via a SIGSEGV coredump
(`coredumpctl list`) during Aquamarine's session teardown in that hook's
wake, and via `systemctl --user cat` on all four units to trace the
`BindsTo`/`PropagatesStopTo` chain above.

UWSM already owns systemd/env integration for the session (its own
env-preloader service + `wayland-session-waitenv.service`), so
home-manager's competing integration is both redundant and actively
harmful here — disable it whenever `withUWSM = true` is set.

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
- HDMI-A-1 (`monRight`) is wired to the NVIDIA GPU, not the Intel iGPU that
  eDP-1 is on. It will show up as disconnected/absent in `hyprctl monitors`
  unless the NVIDIA card (`/dev/dri/card0`) is included in the system-level
  `AQ_DRM_DEVICES` env var — see [system.md](system.md). Aquamarine only
  scans cards listed there; a card left out never has its connectors
  scanned at all, monitor settings here notwithstanding.

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
local hasRequiredKeys = ok and hyprColors
    and hyprColors.active_border_1 and hyprColors.active_border_2 and hyprColors.inactive_border
if not hasRequiredKeys then
    hyprColors = { active_border_1 = "#f38ba8", active_border_2 = "#f5c2e7", inactive_border = "#45475a" }
end

hl.config({
    ...
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
        col = {
            active_border = {
                colors = {
                    "rgba(" .. hyprColors.active_border_1:gsub("#", "") .. "ff)",
                    "rgba(" .. hyprColors.active_border_2:gsub("#", "") .. "ff)",
                },
                angle = 45,
            },
            inactive_border = "rgb(" .. hyprColors.inactive_border:gsub("#", "") .. ")",
        },
    },

    decoration = {
        rounding = 2,

        -- Compositor-wide blur-behind: only visually applies to
        -- windows/surfaces that are actually semi-transparent, so this
        -- alone doesn't blur anything by itself — see kitty.md's
        -- `background_opacity` for the one app currently using it.
        blur = {
            enabled = true,
            size = 3,
            passes = 2,
        },
    },
})
```

Border colors come from wallust's generated palette (see
[theming.md](theming.md)) rather than a hardcoded value, so they follow the
wallpaper. The active border is a 45° gradient between `color1` and
`color5` (see `wallust.nix`'s `[templates.hyprland]`) rather than a solid
color; the inactive border stays solid `color0`. The hardcoded `hyprColors`
fallback covers two cases: before the very first `wallust run`, and a stale
`~/.cache/wallust/hyprland-colors.lua` left over from before the template's
key names changed (it still `dofile()`s fine, just without the keys the
current config expects — hence checking for the specific keys, not just
`ok`/non-nil).

> **Gotcha hit building this**: the Lua API's gradient syntax is *not* the
> same as hyprlang's legacy `"<color> <color> <angle>deg"` string — it's a
> table, `{ colors = {"rgba(...)", "rgba(...)"}, angle = <number> }` (see
> `/nix/store/*-hyprland-*/share/hypr/hyprland.lua`, the reference config
> shipped with the package, for the canonical example). Each color needs
> its alpha channel explicit (`rgba`, 8 hex digits) — plain `rgb()` only
> works for a solid color. Also, `rounding` lives under `decoration` in
> 0.56, not `general` — `general.rounding` is silently rejected as an
> unknown key. Getting either of these wrong doesn't just fail to apply:
> Hyprland drops into emergency mode (a bare fallback config) on the next
> reload/restart until the error is fixed. `hyprctl configerrors` after a
> `hyprctl reload` is the fastest way to see the actual parse error instead
> of guessing from symptoms.

`decoration.blur` is enabled compositor-wide but is a no-op until some
window actually has a semi-transparent background — currently that's just
kitty (`background_opacity` in [kitty.md](kitty.md)). To blur a different
app instead/also, give it its own opacity setting (or a `windowrulev2
opacity ...,class:^(...)$` rule) rather than lowering `general`'s
`active_opacity`/`inactive_opacity` here, which would make every window
transparent.

## Autostart

```lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 0.5 && awww restore")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("mako")
end)
```

`hl.on("hyprland.start", fn)` is the Lua-API equivalent of `exec-once` —
fires only on a fresh compositor start, not on every config reload (there is
a separate `"config.reloaded"` event for that, unused here). Launches the
wallpaper daemon (`awww-daemon`), restores the last wallpaper, and starts
quickshell + mako. See [theming.md](theming.md) for why these are launched here
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
| `SUPER + S` | Launch `lazyspotify` (Spotify TUI) in a kitty window — see [lazyspotify.md](lazyspotify.md) for setup |
| `SUPER + SHIFT + S` | Launch `spotify_player` (Spotify TUI) in a kitty window — see [spotify-player.md](spotify-player.md) |
| `SUPER + ←/→/↑/↓` | Move focus between windows in that direction |
| `SUPER + left-click drag` | Move a floating window (drag across monitors to move it to that monitor's workspace) |
| `SUPER + right-click drag` | Resize a floating window |
| `SUPER + [0-9]` | Switch to workspace 1–10 (`0` maps to workspace 10) |
| `SUPER + SHIFT + [0-9]` | Move focused window to workspace 1–10 |
| `SUPER + scroll wheel` | Cycle to next/previous existing workspace |
| `SUPER + comma` / `SUPER + period` | Jump focus to the left/right monitor |
| `SUPER + SHIFT + comma` / `SUPER + SHIFT + period` | Move the active workspace to the left/right monitor |

## Mouse move/resize

```lua
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
```

`{ mouse = true }` is the Lua-API's equivalent of hyprlang's legacy `bindm =`
— it makes the bind track the mouse for the duration of the button press
instead of firing once. `mouse:272`/`mouse:273` are the left/right button
codes. `hl.dsp.window.drag()` moves a floating window under the cursor;
dragging it across a monitor boundary is native Hyprland behavior — the
window gets re-parented onto that monitor's active workspace mid-drag, so
this is also how you move a window to a different workspace by dragging
rather than `SUPER + SHIFT + [0-9]`.

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
