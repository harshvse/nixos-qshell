# GTK / Qt app theming

Source: `home/programs/gtk-qt.nix`.

## Scope, stated up front

Fully recoloring arbitrary GTK/Qt chrome to match a wallpaper's exact
palette isn't realistic without a much heavier tool (e.g. Gradience). This
module deliberately does **not** attempt that. What it actually delivers:

- **GTK3/4**: a fixed dark base theme + icon/cursor themes for visual
  consistency, *plus* a genuinely wallpaper-reactive accent color
  (selections, scrollbars, focus rings) via `extraCss`.
- **Qt**: qt5ct/qt6ct + Kvantum paired to the same dark base, for a matching
  look — but **static**, not wallpaper-reactive. Kvantum's color-override
  format wasn't verified enough during research to template safely, so it
  was left out rather than guessed at.

## Packages

```nix
home.packages = [
  pkgs.libsForQt5.qt5ct
  pkgs.qt6Packages.qt6ct
  pkgs.libsForQt5.qtstyleplugin-kvantum
  pkgs.qt6Packages.qtstyleplugin-kvantum
];
```

Both Qt5 and Qt6 variants of qt*ct and the Kvantum style engine are
installed, since different Qt apps on the system may link against either
major version.

Attribute-name gotchas confirmed while building this (nixpkgs has renamed/
relocated several of these — verify against actual `nix eval` output before
trusting any of these names in a different nixpkgs revision):
- top-level `qt5ct`/`qt6ct` no longer exist directly — `qt6ct` in
  particular throws `'qt6ct' has been renamed to/replaced by
  'qt6Packages.qt6ct'`.
- Correct paths: `pkgs.libsForQt5.qt5ct`, `pkgs.qt6Packages.qt6ct`,
  `pkgs.libsForQt5.qtstyleplugin-kvantum` (Qt5 engine, package name
  `qtstyleplugin-kvantum5`), `pkgs.qt6Packages.qtstyleplugin-kvantum` (Qt6
  engine).

## GTK

```nix
gtk = {
  enable = true;
  theme = {
    name = "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };
  gtk4.theme = config.gtk.theme;
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
  cursorTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };

  gtk3.extraCss = ''
    @import url("file://${config.home.homeDirectory}/.cache/wallust/gtk-accent.css");
    *:selected { background-color: @accent; }
    scrollbar slider { background-color: @accent; }
    entry:focus, button:checked { border-color: @accent; }
  '';
  gtk4.extraCss = ''  ... same as gtk3 ...  '';
};
```

- **Base theme**: `adw-gtk3` (dark variant) — a GTK3 theme built to visually
  match modern libadwaita/GNOME styling, since GTK3 apps don't get
  libadwaita's own theming. `gtk4.theme = config.gtk.theme` is set
  explicitly rather than left at its default, because home-manager's
  default behavior for `gtk.gtk4.theme` is changing (currently falls back
  to `gtk.theme` only while `home.stateVersion < "26.05"`; the new default
  will be `null`). Explicit here avoids both the evaluation warning and a
  silent behavior change whenever `stateVersion` is eventually bumped (see
  also the same `stateVersion` gate noted in [neovim.md](neovim.md)).
- **Icons**: Papirus-Dark. **Cursor**: Adwaita.
- **The wallpaper-reactive part**: `extraCss` first `@import`s wallust's
  generated `gtk-accent.css` (a single `@define-color accent {{color4}};`
  declaration — see [theming.md](theming.md)), then uses that `@accent`
  variable for a specific, deliberately narrow set of selectors: selected
  items, scrollbar sliders, and focus/checked borders. This is *not* a full
  theme recolor — it's a targeted accent override layered on top of the
  fixed `adw-gtk3-dark` base.
- **Reload caveat**: already-running GTK apps do not hot-reload CSS.
  Only apps launched *after* a wallpaper change pick up the new accent
  color.

## Qt

```nix
qt = {
  enable = true;
  platformTheme.name = "qtct";
  style.name = "kvantum";
};
```

`platformTheme.name = "qtct"` routes Qt apps through qt5ct/qt6ct for
theme/font settings; `style.name = "kvantum"` uses the Kvantum SVG-based
style engine for the actual widget rendering. This pairing is static —
whatever Kvantum theme/colors are configured (currently whatever qt5ct/
qt6ct's own defaults resolve to) stay fixed regardless of wallpaper. No
wallust template feeds into Kvantum's config.

## If you want to close the Qt gap later

The honest next step (not done here) would be researching Kvantum's actual
`.kvconfig` color-override key names (e.g. under a `[General]` or similar
section) against a specific Kvantum theme, verifying them by hand, and only
then adding a `[templates.kvantum]` entry to `wallust.toml` mirroring the
`gtk-accent` pattern above. Don't invent those key names from guesswork —
an incorrect override silently no-ops rather than erroring.
