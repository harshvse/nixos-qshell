# wofi itself (app launcher, SUPER+R) plus the wallpaper picker built on top
# of it. Style @imports a generated stylesheet (see wallust.nix) so wofi
# re-colors with everything else on a wallpaper change.
{ config, pkgs, ... }:
let
  wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";

  # Lists files in ~/Pictures/wallpapers as a wofi dmenu, then re-themes and
  # sets whichever one is picked. wofi has no image-preview mode (unlike
  # rofi), so this is a plain filename list, not thumbnails.
  #
  # nixpkgs renamed the `swww` package to `awww` upstream (same CLI
  # subcommands, just `awww`/`awww-daemon` binaries) — confirmed by building
  # this config, so using the new names directly rather than the old ones.
  wallpaperSelect = pkgs.writeShellApplication {
    name = "wallpaper-select";
    runtimeInputs = [ pkgs.wofi pkgs.wallust pkgs.awww pkgs.findutils pkgs.coreutils ];
    text = ''
      mkdir -p "${wallpaperDir}"

      selected=$(find "${wallpaperDir}" -maxdepth 1 -type f | sort | wofi --dmenu -p "Wallpaper")
      [ -z "$selected" ] && exit 0

      awww img "$selected" --transition-type wipe --transition-fps 60
      wallust run "$selected"
    '';
  };
in
{
  home.packages = [ wallpaperSelect ];

  programs.wofi = {
    enable = true;
    settings = {
      width = 500;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Search";
      allow_images = true;
    };

    style = ''
      @import url("file://${config.home.homeDirectory}/.cache/wallust/wofi-colors.css");

      window {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        background-color: @background;
        color: @foreground;
        border: 2px solid @color4;
        border-radius: 8px;
      }

      #input {
        background-color: @color0;
        color: @foreground;
        border: none;
        margin: 6px;
        padding: 6px;
      }

      #entry:selected {
        background-color: @color4;
        color: @background;
        border-radius: 6px;
      }
    '';
  };
}
