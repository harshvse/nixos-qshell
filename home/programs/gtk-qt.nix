# GTK/Qt theming, scoped honestly: fully recoloring arbitrary GTK/Qt chrome
# to match any wallpaper's exact palette isn't realistic without a much
# heavier tool (e.g. Gradience). What this delivers instead:
#   - GTK3/4: a fixed dark base theme + icon/cursor themes for visual
#     consistency, PLUS a real wallpaper-reactive accent color (scrollbars,
#     selections, focus rings) via `extraCss` importing a wallust-generated
#     file — see wallust.nix's [templates.gtk-accent].
#   - Qt: qt5ct/qt6ct + Kvantum paired to the same fixed dark base, for a
#     matching look. This side is static, not wallpaper-reactive — Kvantum's
#     override format isn't verified enough to template safely yet.
{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.qt6Packages.qtstyleplugin-kvantum
  ];

  # `home.pointerCursor` is the one option that wires a cursor theme up
  # everywhere at once: XCURSOR_THEME/XCURSOR_SIZE session variables (for
  # Xwayland/GTK/Qt apps and anything else that reads them), gtk.cursorTheme
  # (below, via gtk.enable), and an X11 Xcursor.theme resource.
  # catppuccin-cursors is a multi-output derivation — one output per
  # flavor+accent combo (`mochaDark`, `frappeBlue`, etc.); `mochaDark` ships
  # both XCursor and native Hyprland `hyprcursor` formats.
  home.pointerCursor = {
    enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    # Explicit rather than relying on the (currently legacy, soon-changing)
    # default of falling back to `gtk.theme` for GTK4 apps too.
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraCss = ''
      @import url("file://${config.home.homeDirectory}/.cache/wallust/gtk-accent.css");
      *:selected { background-color: @accent; }
      scrollbar slider { background-color: @accent; }
      entry:focus, button:checked { border-color: @accent; }
    '';
    gtk4.extraCss = ''
      @import url("file://${config.home.homeDirectory}/.cache/wallust/gtk-accent.css");
      *:selected { background-color: @accent; }
      scrollbar slider { background-color: @accent; }
      entry:focus, button:checked { border-color: @accent; }
    '';
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };
}
