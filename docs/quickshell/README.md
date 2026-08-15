# quickshell

QML lives in `quickshell/` at the repo root; `home/programs/quickshell.nix`
just links that folder into `~/.config/quickshell`. Replaced waybar (see git history /
`docs/theming.md` for what waybar's setup looked like) as the status bar,
launched the same way — from Hyprland's `hyprland.start` autostart block in
`hyprland.nix`, not a home-manager systemd service.

This is a deliberately thin bootstrap, not a full bar. The current
`shell.qml` is one `PanelWindow` per screen with a clock, wired to
wallust's colors, and nothing else. The workspaces/window-title/tray/
network/audio modules waybar used to have are intentionally not
reimplemented — the point of switching to Quickshell is to build those up
by hand while learning its QML API, not to have them appear for free.

## Where things live

- **Structural QML**: `quickshell/shell.qml` at the repo root — plain QML,
  not Nix-templated. `home/programs/quickshell.nix`'s
  `xdg.configFile."quickshell".source` points at the `quickshell/` folder
  and links the whole thing into `~/.config/quickshell`.
- **Colors**: `~/.cache/wallust/quickshell-colors.json`, rendered by
  wallust (`[templates.quickshell]` in `wallust.nix`) — read *live* via a
  `FileView` with `watchChanges: true`, so a wallpaper change re-themes the
  bar instantly with no rebuild and no reload signal (unlike waybar, which
  needed `pkill -SIGUSR2`). The path is built with `Quickshell.env("HOME")`
  in the QML itself (not Nix string interpolation) since the QML is no
  longer templated. See `docs/theming.md` for the overall architecture this
  fits into.

## Iterating on the QML

Kill the autostarted instance and run it in a terminal to see QML errors
live (Quickshell prints them straight to stdout, no log file to go dig
through):

```bash
pkill quickshell
quickshell
```

Since `quickshell/` is a plain folder (not inlined into the Nix file
anymore), edit `quickshell/shell.qml` directly and `nrs` to pick up the
change — home-manager symlinks the whole folder, so no Nix edits are needed
for QML-only changes. For faster iteration without a full rebuild, point
`quickshell -p <path-to-repo>/quickshell` directly at the repo copy while
experimenting, instead of going through `~/.config/quickshell`.

## Reference

- [Quickshell docs](https://quickshell.org/docs/) — the types actually
  used so far: `PanelWindow`, `Variants` (+ `Quickshell.screens` for
  multi-monitor), `FileView` + `JsonAdapter` (live JSON reload).
- Types worth reading next, in roughly the order waybar's modules would map
  to them: `Quickshell.Hyprland` (`Hyprland.workspaces`,
  `Hyprland.dispatch()`) for workspaces, `Quickshell.Wayland`
  (`ToplevelManager.activeToplevel`) for the focused window's title,
  `Quickshell.Services.Pipewire` (`Pipewire.defaultAudioSink`, needs a
  `PwObjectTracker` to actually populate `.audio.volume`/`.muted`) for
  volume, `Quickshell.Services.SystemTray` (`SystemTray.items`) for the
  tray, and `Quickshell.Io.Process` + `SplitParser` for anything with no
  dedicated service (CPU/memory from `/proc`, network from `nmcli`) — this
  last one is the general escape hatch: shell out and parse the output.

Notes worth keeping as you actually build these out: which properties
needed a tracker/binder to populate, any QML gotchas specific to this
version (`0.3.0`, pinned via nixpkgs), whatever ends up being non-obvious
in six months. This file is the place for it.
