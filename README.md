# nixos-qshell

Flake-based NixOS + Home Manager config. Hosts live under `hosts/<name>/`,
so a second machine later is just a new folder plus one line in `flake.nix`.

This machine is wired up as `nixosConfigurations.nixos` (see `flake.nix`),
config lives in `hosts/nixos/`, and the repo is expected to live at
`~/nixos-qshell` (that exact path is baked into the `nrs`/`hms` shell
aliases in `home/programs/fish.nix`).

For detailed, per-subsystem reference docs (what's configured and why, down
to specific settings and the bugs that shaped them), see **[docs/](docs/)**.
This file is just the quickstart.

## First-time setup on a freshly installed machine

1. **Get this repo onto the machine** at `~/nixos-qshell`. Either `git
   clone` it (if you've already pushed it somewhere) or copy these files
   into that path.

2. **If you're reusing this config for a different user or a fresh
   machine**, replace the `harshvse` username throughout (it's no longer a
   `changeme` placeholder — this copy is already personalized):
   ```bash
   cd ~/nixos-qshell
   grep -rl harshvse . | xargs sed -i "s/harshvse/$(whoami)/g"
   ```
   Otherwise skip this step.

3. **Get your real hardware config:**
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix hosts/nixos/hardware-configuration.nix
   ```

4. **Find your GPU bus IDs** (needed for the NVIDIA PRIME section in
   `hosts/nixos/configuration.nix`):
   ```bash
   lspci | grep -E "VGA|3D"
   ```
   You'll see two lines, something like:
   ```
   00:02.0 VGA compatible controller: Intel Corporation ...
   01:00.0 3D controller: NVIDIA Corporation TU117M [GeForce GTX 1650 Ti] ...
   ```
   Convert `00:02.0` → `PCI:0:2:0` and `01:00.0` → `PCI:1:0:0`, and put
   those in `intelBusId` / `nvidiaBusId`.

5. **Check the timezone** (`time.timeZone` in `hosts/nixos/configuration.nix`)
   is right.

6. **Drop a login-screen background video into `~/Videos/wallpapers/`**
   (optional — `sddmBackgroundSource` in `hosts/nixos/configuration.nix`
   falls back to skipping this gracefully if the file isn't there, so this
   can wait). Point `sddmBackgroundSource` at it if the filename differs
   from the default.

7. **Build it.** The very first time, flakes may not be enabled yet in the
   installer's default config, so pass the flag explicitly:
   ```bash
   sudo nixos-rebuild switch --flake ~/nixos-qshell#nixos \
     --extra-experimental-features "nix-command flakes"
   ```
   This will take a while the first time — it's compiling/fetching Hyprland,
   the NVIDIA driver, and everything else in the config.

8. **Reboot.** You should land on the SDDM login screen; pick the
   "Hyprland (uwsm-managed)" session, log in, and it drops you into Hyprland.

9. **Commit and push:**
   ```bash
   git add -A
   git commit -m "Initial NixOS + Hyprland config"
   git remote add origin git@github.com:you/nixos-qshell.git
   git push -u origin main
   ```

## Day-to-day workflow

Edit files in `~/nixos-qshell`, then:

```bash
nrs   # alias for: sudo nixos-rebuild switch --flake ~/nixos-qshell#nixos
```

Home-manager changes (things in `home/`) get picked up by the same command —
it rebuilds the whole system including your user environment in one shot,
since home-manager is wired in as a NixOS module rather than run standalone
(see [docs/flake.md](docs/flake.md)). The `hms` alias exists too but only
works if you separately install a standalone `home-manager` CLI — `nrs` is
the one that actually works out of the box here.

To catch config mistakes without touching the live system, build without
activating:

```bash
nixos-rebuild build --flake ~/nixos-qshell#nixos
```

Commit whenever a config actually works well, so you can always roll back to
a known-good `flake.lock` + config pair:

```bash
git add -A && git commit -m "describe the change"
```

To roll back the *system* itself (not just the files) if a build breaks
something at runtime, pick an older generation at boot from the
systemd-boot menu — every successful `nixos-rebuild switch` adds one.

## Troubleshooting hybrid graphics

- **Black screen / hangs on boot after enabling NVIDIA**: double check the
  bus IDs from step 4 — a wrong ID is the most common cause.
- **Cursor invisible or corrupted in Hyprland**: already handled by
  `WLR_NO_HARDWARE_CURSORS=1` in `configuration.nix`; if you still see it,
  also try launching Hyprland with `env WLR_NO_HARDWARE_CURSORS=1 Hyprland`.
- **GPU-heavy apps should run on the NVIDIA card, everything else on Intel**:
  that's what PRIME offload does. Force an app onto NVIDIA with:
  ```bash
  nvidia-offload <command>
  ```
- **Login screen appears, you log in, but you never land in Hyprland**: this
  is a Hyprland crash, not a display-manager problem — check
  `~/.cache/hyprland/hyprlandCrashReport*.txt` for a crash at startup (often
  the `AQ_DRM_DEVICES` env var pointing at a `/dev/dri/by-path/*` symlink
  instead of a raw `/dev/dri/cardN` node), or `coredumpctl list` for a crash
  a couple seconds into a session that briefly rendered something (often
  home-manager's `wayland.windowManager.hyprland.systemd.enable` fighting
  with UWSM). See docs/system.md for both.
- **External monitor never shows up in `hyprctl monitors`**: `AQ_DRM_DEVICES`
  only scans the GPU(s) listed in it — if your external monitor's cable is
  on a different GPU than the one currently listed, add it (colon-separated,
  e.g. `"/dev/dri/card1:/dev/dri/card0"`). See docs/system.md.

See [docs/system.md](docs/system.md) for the full breakdown of the graphics
setup.

## Theming

Wallpaper-driven theming is fully built: changing the wallpaper (`SUPER+W`
opens a picker) re-themes the terminal, status bar, launcher, notifications,
editor, and GTK/Qt apps via [wallust](https://codeberg.org/explosion-mental/wallust),
with no rebuild required. `home/theme.nix` (an earlier static-palette
placeholder) no longer exists — `home/programs/wallust.nix` is the current
source of truth. The SDDM login screen also pulls its colors from wallust,
but is the one exception to "no rebuild required" — see below.

Full architecture, the template/reload-hook system, and gotchas hit while
building it (a monitor-scaling cursor-gap bug, wallust failing on
low-color placeholder images, nixpkgs's `swww`→`awww` rename) are documented
in **[docs/theming.md](docs/theming.md)**.

## Status bar: quickshell

The status bar is [Quickshell](https://quickshell.org/), replacing an
earlier waybar setup. QML lives in `quickshell/` at the repo root (plain
QML, not Nix-templated); `home/programs/quickshell.nix` just links that
folder into `~/.config/quickshell`. It's a deliberately minimal bootstrap
(one panel, a clock, wallust colors wired up live) — build it out yourself
as you learn Quickshell's QML API. See
**[docs/quickshell/](docs/quickshell/README.md)** for how it's wired and
where to go next.

## SDDM login background

The login screen uses [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)
with a personal video background and a color palette sourced from wallust.
Unlike everything above, this **does** need a rebuild to pick up changes:

- **Video**: drop an mp4/gif/image into `~/Videos/wallpapers/` and update
  `sddmBackgroundSource` in `hosts/nixos/configuration.nix` to point at it,
  then `nrs`. (The greeter runs as its own system user and can't read into
  a `700` `$HOME`, so a `system.activationScripts` step copies it out to a
  world-readable system path on every switch — see
  [docs/system.md](docs/system.md#animated-login-background).)
- **Colors**: pick a wallpaper you like, run `sddm-theme-sync` to copy
  wallust's current palette into `hosts/nixos/sddm-colors.nix`, then `nrs`.

Full details, including *why* this one thing can't be live like the rest,
in [docs/system.md](docs/system.md#animated-login-background) and
[docs/theming.md](docs/theming.md#sddm-a-rebuild-time-exception).
