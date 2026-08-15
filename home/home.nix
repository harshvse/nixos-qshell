{ config, pkgs, inputs, ... }:

let
  theme = import ./theme.nix;
in
{
  # CHANGE these two to match your actual username
  home.username = "harshvse";
  home.homeDirectory = "/home/harshvse";

  # Match whatever release you installed from; don't bump this casually later.
  home.stateVersion = "25.05";

  imports = [
    (import ./programs/fish.nix)
    (import ./programs/kitty.nix { inherit theme; })
    (import ./programs/neovim.nix)
    (import ./programs/hyprland.nix)
  ];

  home.packages = with pkgs; [
    wl-clipboard
    grim       # screenshot
    slurp      # region select for screenshots
    fastfetch
    ripgrep
    fd
    btop
    vim
  ];

  programs.home-manager.enable = true;
}
