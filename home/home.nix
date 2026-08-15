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
    firefox
    git
    wofi

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
