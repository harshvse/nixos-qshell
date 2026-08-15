# waybar

Source: `home/programs/waybar.nix`.

## Launch model

```nix
programs.waybar = {
  enable = true;
  systemd.enable = false;
  ...
};
```

`systemd.enable = false` deliberately — waybar is launched from Hyprland's
own `hyprland.start` autostart block (see [hyprland.md](hyprland.md)) rather
than home-manager's own systemd user service, to keep all autostart
processes (waybar, mako, the wallpaper daemon) declared in one place.

## Layout (`settings.mainBar`)

```
modules-left   = [ "hyprland/workspaces" "hyprland/window" ]
modules-center = [ "clock" ]
modules-right  = [ "pulseaudio" "network" "cpu" "memory" "tray" ]
```

- `hyprland/workspaces`: workspace pills, `format = "{icon}"`, clicking
  activates that workspace (`on-click = "activate"`).
- `hyprland/window`: currently focused window's title.
- `clock`: center, `%a %d %b  %H:%M` format; tooltip shows a full calendar
  month view.
- `cpu` / `memory`: percentage usage, polled every 5s.
- `network`: WiFi SSID / "Connected" (ethernet) / "Offline", with Nerd Font
  icons.
- `pulseaudio`: icon + volume%, click toggles mute via `wpctl set-mute
  @DEFAULT_AUDIO_SINK@ toggle` (needs PipeWire's `pulse` compatibility layer
  — see [system.md](system.md)).
- `tray`: system tray, 8px spacing.

`height = 32`, `position = "top"`, `layer = "top"` (renders above tiled
windows).

## Styling — colors are not Nix-managed

```nix
style = ''
  @import url("file://${config.home.homeDirectory}/.cache/wallust/waybar-colors.css");

  window#waybar { background-color: @background; color: @foreground; }
  #workspaces button.active { color: @background; background: @color4; border-radius: 6px; }
  ...
'';
```

The `@import` at the top pulls in wallust's generated
`waybar-colors.css` (a set of `@define-color` declarations — see
[theming.md](theming.md)) from *outside* the Nix store at CSS-parse time.
Everything below it is structural CSS (padding, font, layout) that
references those `@color*`/`@background`/`@foreground` GTK-CSS color
variables rather than hardcoding hex values.

**Reload model**: waybar has no live CSS-reload API. wallust's `[hooks]`
table sends `pkill -SIGUSR2 waybar` after regenerating the palette, which is
the documented way to get waybar to reload its config/style. If a wallpaper
change doesn't visibly re-theme the bar, check whether that signal actually
reached a running waybar process.

## Font

`JetBrainsMono Nerd Font`, 12px — same font family used everywhere else
themed (kitty, wofi, mako).
