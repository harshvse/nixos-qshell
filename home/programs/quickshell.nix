# Bootstrap only — this is a deliberately minimal starter config, not a
# full bar. The workspaces/tray/network/etc. modules waybar used to provide
# are intentionally NOT reimplemented here; build those up yourself as you
# learn Quickshell's QML API. See docs/quickshell/ for how this is wired and
# where to go next.
#
# The one thing worth keeping from waybar's setup: colors still come from
# wallust, live, with no rebuild — see wallust.nix's [templates.quickshell]
# and shell.qml's FileView below. QML lives in the `quickshell/` folder at
# the repo root (not inlined here) so it can be edited/run directly with
# ordinary QML tooling; this file just links it into place.
#
# Launched via the hyprland.start autostart block in hyprland.nix, not a
# home-manager systemd service, to keep autostart processes declared in one
# place (see hyprland.nix).
{ pkgs, ... }:
{
  home.packages = [ pkgs.quickshell ];

  xdg.configFile."quickshell".source = ../../quickshell;
}
