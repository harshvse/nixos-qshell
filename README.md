# nixos-config

Flake-based NixOS + Home Manager config. Hosts live under `hosts/<name>/`,
so a second machine later is just a new folder plus one line in `flake.nix`.

## First-time setup on a freshly installed machine

1. **Get this repo onto the machine.** Either `git clone` it (if you've
   already pushed it somewhere) or copy these files into `~/nixos-config`.

2. **Find your real username and set it everywhere.** Every file with
   `changeme` needs it:
   ```bash
   cd ~/nixos-config
   grep -rl changeme . | xargs sed -i "s/changeme/$(whoami)/g"
   ```

3. **Get your real hardware config:**
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix hosts/laptop/hardware-configuration.nix
   ```

4. **Find your GPU bus IDs** (needed for the NVIDIA PRIME section in
   `hosts/laptop/configuration.nix`):
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

5. **Check the timezone** (`time.timeZone` in `configuration.nix`) is right.

6. **Build it.** The very first time, flakes may not be enabled yet in the
   installer's default config, so pass the flag explicitly:
   ```bash
   sudo nixos-rebuild switch --flake ~/nixos-config#laptop \
     --extra-experimental-features "nix-command flakes"
   ```
   This will take a while the first time — it's compiling/fetching Hyprland,
   the NVIDIA driver, and everything else in the config.

7. **Reboot.** You should land on the `tuigreet` login screen; log in and
   it drops you straight into Hyprland.

8. **Commit and push:**
   ```bash
   git add -A
   git commit -m "Initial NixOS + Hyprland config"
   git remote add origin git@github.com:you/nixos-config.git
   git push -u origin main
   ```

## Day-to-day workflow

Edit files in `~/nixos-config`, then:

```bash
nrs   # alias for: sudo nixos-rebuild switch --flake ~/nixos-config#laptop
```

Home-manager changes (things in `home/`) get picked up by the same command —
it rebuilds the whole system including your user environment in one shot,
since home-manager is wired in as a NixOS module rather than run standalone.

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

## Where the theming system is headed (phase 2, not needed yet)

`home/theme.nix` is the single file every themed program reads its colors
from — right now `kitty.nix` is the only one wired up, as a template for
the pattern. Later:

1. Install `wallust` (`pkgs.wallust`), point it at a wallpaper.
2. A small script (or a systemd user service watching your wallpaper
   symlink) has wallust regenerate `home/theme.nix` from the new palette.
3. `home-manager switch` re-themes kitty, and — once you extend the same
   `{ theme }: { ... }` pattern to `hyprland.nix`, `neovim.nix`, and a
   status bar (waybar is the natural next addition) — everything else too.

No need to build this now; the point of doing it this way from day one is
that adding each new themed program later is copy-pasting the same
15-line pattern, not a redesign.
