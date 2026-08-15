{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # Pinned explicitly: home-manager's default for these flipped to false
    # (nixpkgs#492131 dropped python3/ruby providers from neovim's own
    # defaults, and home-manager now only defaults to true while
    # home.stateVersion stays below "26.05" — a gate we'll cross one day).
    withPython3 = true;
    withRuby = true;
    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set shiftwidth=2
      set tabstop=2
      set termguicolors
    '';
  };
}
