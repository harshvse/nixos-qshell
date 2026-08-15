{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      # Rebuild your whole system from the flake in one word
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config#laptop";
      hms = "home-manager switch --flake ~/nixos-config#changeme"; # only if you split home-manager standalone later
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
}
