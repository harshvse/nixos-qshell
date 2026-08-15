# Just the package. mako's config file (~/.config/mako/config) is owned
# entirely by wallust at runtime (see wallust.nix's [templates.mako] and its
# activation seed) — it is NOT home-manager-managed here, since a Nix-store
# symlink at that path would fight wallust for ownership on every wallpaper
# change. Launched via the hyprland.start autostart block in hyprland.nix.
{ pkgs, ... }:
{
  home.packages = [ pkgs.mako ];
}
