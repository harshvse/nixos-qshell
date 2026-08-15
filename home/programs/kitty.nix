# This module takes `theme` as an argument instead of reading it from
# specialArgs, which is what lets home.nix pass in a *different* palette
# later (e.g. wallust output) without touching this file at all.
{ theme }:
{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      background = theme.background;
      foreground = theme.foreground;
      color0 = theme.black;
      color1 = theme.red;
      color2 = theme.green;
      color3 = theme.yellow;
      color4 = theme.blue;
      color5 = theme.magenta;
      color6 = theme.cyan;
      color7 = theme.white;
      confirm_os_window_close = 0;
    };
  };
}
