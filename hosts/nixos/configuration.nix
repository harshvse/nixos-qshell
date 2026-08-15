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
  # Windows lives on a separate physical disk (nvme0n1) with its own EFI
  # System Partition. GRUB + os-prober scans every disk's ESP at boot-config
  # build time and adds a chainload entry for whatever it finds, so it
  # handles the cross-disk case without a manually-supplied device handle.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
  };

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
    # eDP-1 is wired to the Intel iGPU (card1, PCI 00:02.0), HDMI-A-1 to the
    # NVIDIA GPU (card0). Aquamarine only scans/uses cards listed here, so
    # both must be present or the card not listed simply won't show its
    # monitor. List is `:`-separated, first entry is primary.
    #
    # Must be raw /dev/dri/cardN nodes, NOT /dev/dri/by-path/* symlinks:
    # Aquamarine parses AQ_DRM_DEVICES as a `:`-separated list, and by-path
    # names contain colons themselves (pci-0000:00:02.0-card), so a by-path
    # value gets shredded into 3 bogus paths, Aquamarine finds zero GPUs, and
    # Hyprland aborts in CCompositor::initServer before a single frame is
    # drawn. (card1 confirmed as the Intel device via
    # `readlink /dev/dri/by-path/pci-0000:00:02.0-card`.)
    #
    # A previous version of this pinned Intel-only (card1) after Hyprland
    # crashed a few seconds after login with "Cannot commit when a
    # page-flip is awaiting" during a cross-GPU commit. That pin was
    # written before the colon-parsing bug above was diagnosed, so it's
    # unclear whether that crash was a genuine multi-GPU issue or just this
    # same zero-GPUs-found bug — worth re-testing with both cards listed
    # (as below) before assuming HDMI-A-1 needs Intel-only. If Hyprland
    # crashes again a few seconds in, revert to `"/dev/dri/card1"` alone and
    # treat HDMI-A-1 as unsupported until fixed upstream.
    AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
  };

  ##################
  # Hyprland
  ##################
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Launch via UWSM so Hyprland gets folded into systemd's
    # graphical-session.target/xdg-desktop-autostart.target instead of
    # running as a bare unmanaged process — silences the "Hyprland was
    # started without hyprland-session.target, not recommended unless
    # debugging" warning and gives XDG autostart units + a proper user
    # session for free.
    withUWSM = true;
  };

  # Registers a "Hyprland (UWSM)" entry in /share/wayland-sessions so
  # the greeter's session picker launches it via `uwsm start -F --`,
  # matching what withUWSM above expects instead of execing Hyprland bare.
  #
  # binPath must be `start-hyprland`, not the raw `Hyprland` binary: the
  # bare binary logs "WARNING: Hyprland is being launched without
  # start-hyprland. This is highly advised against." on every startup.
  # `start-hyprland` is the wrapper Hyprland itself ships for exactly this
  # (systemd/uwsm) launch path — see hyprwm/Hyprland discussion #12661.
  programs.uwsm.waylandCompositors.hyprland = {
    prettyName = "Hyprland";
    comment = "Hyprland compositor managed by UWSM";
    binPath = "/run/current-system/sw/bin/start-hyprland";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Graphical login screen. regreet (run inside cage) never got past the
  # greeter on this box, so use SDDM instead — it has native Wayland
  # session support and is one of the few display managers Hyprland's own
  # docs call out as working without caveats. Presents a session picker
  # built from /share/wayland-sessions, so pick "Hyprland (UWSM)" at login
  # rather than the plain "Hyprland" entry.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
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
    noto-fonts-color-emoji
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
