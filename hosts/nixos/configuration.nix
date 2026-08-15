{ config, pkgs, lib, inputs, ... }:

let
  # Personal video wallpaper for the SDDM greeter — lives in the user's home
  # (not the Nix store, not git; it's a personal ~15MB file), moved here from
  # ~/Downloads. sddm-astronaut-theme's Background loader (Qt.resolvedUrl in
  # its Main.qml) accepts an absolute path fine, but SDDM's greeter runs as
  # its own system user, and $HOME is 700 — it can't read into
  # ~/Videos/wallpapers directly. So system.activationScripts.sddmBackground
  # below copies it out to a world-readable path on every `nixos-rebuild
  # switch` instead of loosening home directory permissions.
  sddmBackgroundSource = "/home/harshvse/Videos/wallpapers/girl-behind-curtains-live-wallpaper.mp4";
  sddmBackgroundTarget = "/var/lib/sddm-astronaut/background.mp4";
in
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
    #
    # This alone (plus the hyprland package's own bundled session entry,
    # registered unconditionally by the module) is enough: it ships a
    # "Hyprland (uwsm-managed)" /share/wayland-sessions/hyprland-uwsm.desktop
    # that already runs `uwsm start -e -D Hyprland hyprland.desktop` — i.e.
    # explicitly sets XDG_CURRENT_DESKTOP=Hyprland and resolves through the
    # start-hyprland wrapper internally, so it never triggers the "Hyprland
    # is being launched without start-hyprland" warning either. Do NOT also
    # add a `programs.uwsm.waylandCompositors.hyprland` block: it generates
    # a *second* file at that exact same path with no `-D` flag (defaults
    # XDG_CURRENT_DESKTOP to the compositor binary's basename), which
    # collides with and shadows this good one — that's what caused
    # `XDG_CURRENT_DESKTOP=start-hyprland:Hyprland` (basename `start-hyprland`
    # from a binPath pointed at the wrapper, with `Hyprland` appended on top
    # by uwsm's own hyprland.sh plugin).
    withUWSM = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Graphical login screen. regreet (run inside cage) never got past the
  # greeter on this box, so use SDDM instead — it has native Wayland
  # session support and is one of the few display managers Hyprland's own
  # docs call out as working without caveats. Presents a session picker
  # built from /share/wayland-sessions, so pick "Hyprland (uwsm-managed)"
  # at login rather than the plain "Hyprland" entry.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # sddm-astronaut-theme adds an animated (video) background. ThemeDir is
    # resolved from /run/current-system/sw/share/sddm/themes, so the theme
    # package must live in environment.systemPackages below, not
    # sddm.extraPackages.
    theme = "sddm-astronaut-theme";
    # The mp4 background is rendered via a QML QtMultimedia element, which
    # lives in the *greeter's own* Qt plugin/QML path, separate from the
    # system profile above — without this the greeter logs "qtmultimedia is
    # not installed" and falls back to a static background.
    extraPackages = [ pkgs.kdePackages.qtmultimedia ];
  };

  # Secret Service (org.freedesktop.secrets D-Bus API) — apps that store
  # OAuth tokens/passwords (e.g. lazyspotify, see docs/lazyspotify.md) need
  # a keyring provider registered, which nothing here provides otherwise.
  # `enableGnomeKeyring` on sddm's PAM stack unlocks it automatically with
  # the login password (creating the "login" keyring on first login if one
  # doesn't exist yet) — no separate keyring prompt/password to manage.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # Copies the personal wallpaper video (see `let` above) out to a
  # world-readable system path on every switch, since the greeter can't read
  # into the user's 700 $HOME. `|| true` on the copy: harmless if the source
  # is ever missing (e.g. building this repo fresh on another machine before
  # the user has dropped their own video in).
  system.activationScripts.sddmBackground = ''
    mkdir -p $(dirname ${sddmBackgroundTarget})
    cp ${sddmBackgroundSource} ${sddmBackgroundTarget} 2>/dev/null || true
    chmod 644 ${sddmBackgroundTarget} 2>/dev/null || true
  '';

  environment.systemPackages = [
    (pkgs.sddm-astronaut.override {
      embeddedTheme = "hyprland_kath";
      # Colors come from hosts/nixos/sddm-colors.nix, which is a wallust
      # template output a human syncs in (see wallust.nix's
      # `sddm-theme-sync` script) — not live-reactive like the rest of the
      # theming system, since this whole attrset is baked into a Nix-store
      # `.conf.user` file at build time. See docs/theming.md.
      themeConfig = (import ./sddm-colors.nix) // {
        Background = sddmBackgroundTarget;
      };
    })
  ];

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
