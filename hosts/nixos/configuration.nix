{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Optional: uncomment and pick your exact model for battery/thermal fixes:
    #   ls $(nix eval --raw nixos-hardware#) to browse, or check
    #   https://github.com/NixOS/nixos-hardware for your laptop vendor.
    # inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05  # example
  ];

  ##################
  # Boot
  ##################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ##################
  # Networking
  ##################
  networking.hostName = "nixos"; # must match the key in flake.nix
  networking.networkmanager.enable = true;

  ##################
  # Locale / time
  ##################
  time.timeZone = "Asia/Kolkata"; # change if this isn't right for you
  i18n.defaultLocale = "en_US.UTF-8";

  ##################
  # Nix settings
  ##################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true; # required for the NVIDIA driver
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  ##################
  # Graphics: Intel iGPU + NVIDIA 1650 Ti (hybrid/Optimus)
  ##################
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # lets the GPU fully power down when idle
    open = false; # proprietary driver — safest choice for a 1650 Ti (Turing) today
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # gives you the `nvidia-offload <cmd>` helper
      };
      # !! REQUIRED: replace these with YOUR actual bus IDs.
      # Find them with: lspci | grep -E "VGA|3D"
      # e.g. "00:02.0" -> "PCI:0:2:0"
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Common fixes for NVIDIA + Wayland compositors
  environment.sessionVariables = {
    LIBVA_VDPAU_DRIVER = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1"; # fixes invisible/corrupt cursor on nvidia
  };

  ##################
  # Hyprland
  ##################
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Lightweight login manager that hands off straight into Hyprland
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  ##################
  # Audio (Pipewire)
  ##################
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ##################
  # Fonts (useful now, essential once theming syncs everything)
  ##################
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-emoji
  ];

  ##################
  # User
  ##################
  programs.fish.enable = true; # must be enabled at system level to be a valid login shell

  users.users.harshvse = { # CHANGE "changeme" to your actual username
    isNormalUser = true;
    description = "Harsh Verma";
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
    shell = pkgs.fish;
  };

  # Leave as whatever nixos-generate-config originally wrote for you.
  system.stateVersion = "25.05";
}
