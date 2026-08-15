# Colors come from a wallust-generated file at runtime, not from Nix — see
# wallust.nix. `include` re-reads that file every time kitty's config is
# reloaded, so a wallpaper change re-themes kitty without a rebuild.
# `listen_on` uses a fixed path (rather than the default per-instance socket)
# because wallust's reload hook runs outside any kitty session, so it can't
# rely on $KITTY_LISTEN_ON being set.
{ config, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      confirm_os_window_close = 0;
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty-wallust-socket";

      # Blur itself is Hyprland's job (decoration.blur in hyprland.nix,
      # compositor-wide) — this just makes the background semi-transparent
      # so there's something for it to blur.
      background_opacity = "0.85";
    };
    extraConfig = ''
      include ${config.home.homeDirectory}/.cache/wallust/kitty-colors.conf
    '';
  };
}
