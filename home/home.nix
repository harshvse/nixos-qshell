{ config, pkgs, inputs, ... }:

{
  # CHANGE these two to match your actual username
  home.username = "harshvse";
  home.homeDirectory = "/home/harshvse";

  # Match whatever release you installed from; don't bump this casually later.
  home.stateVersion = "25.05";

  imports = [
    (import ./programs/fish.nix)
    (import ./programs/kitty.nix)
    (import ./programs/neovim.nix)
    (import ./programs/hyprland.nix)
    (import ./programs/wallust.nix)
    (import ./programs/waybar.nix)
    (import ./programs/wofi.nix)
    (import ./programs/mako.nix)
    (import ./programs/btop.nix)
    (import ./programs/gtk-qt.nix)
  ];

  # wofi and btop are configured (not just installed) by their own modules
  # above; wallust.nix pulls in wallust; mako.nix pulls in mako.
  home.packages = with pkgs; [
    wl-clipboard
    grim       # screenshot
    slurp      # region select for screenshots
    fastfetch
    ripgrep
    fd
    awww # wallpaper daemon; nixpkgs renamed this from `swww`
    vim
    firefox
    git
    gh # GitHub CLI; `gh auth login` sets up passwordless HTTPS push
    claude-code

    # Verifying NVIDIA is actually doing the rendering:
    # - nvidia-smi is already on PATH system-wide via hardware.nvidia in
    #   configuration.nix; it lists processes/utilization per GPU.
    # - nvtop: live TUI GPU monitor, watches both the Intel iGPU and the
    #   NVIDIA card side by side so you can see which one lights up.
    # - mesa-demos: `glxinfo` — check `glxinfo | grep "OpenGL renderer"` vs
    #   `nvidia-offload glxinfo | grep "OpenGL renderer"` to confirm offload
    #   is actually switching the renderer to the NVIDIA GPU.
    # - vulkan-tools: `vulkaninfo --summary` / `vkcube` for the Vulkan path.
    # - glmark2: a real GPU benchmark, so nvtop/nvidia-smi has something to
    #   show — run it via `nvidia-offload glmark2` and watch GPU load jump.
    nvtopPackages.full
    mesa-demos
    vulkan-tools
    glmark2
  ];

  programs.home-manager.enable = true;
}
