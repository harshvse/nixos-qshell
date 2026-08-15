# VS Code

Source: `home/programs/vscode.nix`. Extensions + settings for Rust, C/C++,
Nix, JS/TS, Lua, and Quickshell's QML, plus a wallust-driven color theme.
Complements `neovim.md`, not a replacement — this repo doesn't assume you
only use one editor.

## Module setup

```nix
programs.vscode = {
  enable = true;
  package = pkgs.vscode;
  profiles.default = {
    extensions = [ ... ];
    userSettings = { ... };
  };
};
```

`profiles.default` with no other profiles declared means home-manager's
`mutableExtensionsDir` defaults to `true` (see the home-manager module
source) — extensions listed here are Nix-pinned and land in
`~/.vscode/extensions/` as read-only store symlinks, but installing more
from the Marketplace/`code --install-extension` on top still works, same
"declarative core, mutable on top" spirit as the rest of this repo.

## Extensions

| Language | Extension | Source |
|---|---|---|
| Rust | `rust-lang.rust-analyzer` | `pkgs.vscode-extensions` |
| C/C++ | `llvm-vs-code-extensions.vscode-clangd` | `pkgs.vscode-extensions` |
| Nix | `jnoortheen.nix-ide` | `pkgs.vscode-extensions` |
| Lua | `sumneko.lua` | `pkgs.vscode-extensions` |
| JS/TS lint | `dbaeumer.vscode-eslint` | `pkgs.vscode-extensions` |
| JS/TS format | `esbenp.prettier-vscode` | `pkgs.vscode-extensions` |
| QML (Quickshell) | `cutetee.qml` | fetched from the Marketplace directly, pinned by hash (see below) |

**Why `vscode-clangd` and not `ms-vscode.cpptools`**: matches
`neovim.nix`'s own choice of `clangd` over `ccls`/other servers — one C/C++
LSP backend across both editors, not two to keep in sync.

**Why `cutetee.qml` isn't in the table above via `pkgs.vscode-extensions`**:
it isn't in nixpkgs's curated extension set. Built instead with
`pkgs.vscode-utils.buildVscodeMarketplaceExtension`:

```nix
(pkgs.vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "qml";
    publisher = "cutetee";
    version = "1.1.0";
    hash = "sha256-qxnrFPZTFq4b0r2uYkJvy0L1mJ4gPcLc0VQBiIF7JW0=";
  };
})
```

Same "everything pinned, nothing fetched at unpinned versions" ethos as the
rest of the repo — just pinned by an explicit hash instead of a nixpkgs
version bump. This extension is plain syntax highlighting/snippets, **not**
a language server — `qmlls`/`qmlformat` (via `qt6.qtdeclarative`) already
live in `neovim.nix` for actual QML language intelligence; this is just
parity so a `.qml` file doesn't look like plain text if you happen to open
it in VS Code instead. See `docs/quickshell/README.md`'s "learning, not
delivery" note — this repo doesn't try to build a full QML IDE in either
editor.

To bump the QML extension version later: check
`https://marketplace.visualstudio.com/items?itemName=cutetee.qml` for the
current version, then re-derive the hash with:

```bash
nix-prefetch-url --type sha256 \
  "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/cutetee/vsextensions/qml/<version>/vspackage"
nix hash convert --to sri --hash-algo sha256 <output-above>
```

## Packages on `PATH`

```nix
home.packages = [ clang-tools cargo rustc lua-language-server ];
```

Unlike Neovim's `extraPackages` (which only prepends to the wrapped `nvim`
binary's own `PATH`), a GUI app like VS Code needs these on the general user
session `PATH` to find them. `rust-analyzer`'s VS Code extension bundles its
own prebuilt server binary, but — same gotcha documented in `neovim.md` —
still shells out to `cargo`/`rustc` for sysroot/workspace resolution, so
they're here too, not just Neovim's.

## Settings

```nix
userSettings = {
  "workbench.colorTheme" = "Wallust";
  "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
  "editor.formatOnSave" = false;
  "rust-analyzer.check.command" = "clippy";
  "[nix]"."editor.tabSize" = 2;
};
```

**No `formatOnSave`** — same reasoning as `conform.nvim`'s setup in
`neovim.nix`: an unfamiliar formatter silently rewriting a buffer on every
save is more surprising than helpful. Format on-demand (`Shift+Alt+F`) still
works via whichever extension owns that language.

## Palette-driven theming

Same wallust split as every other themed program (`theming.md`), but VS
Code has neither an `include`-style mechanism nor any live theme reload, so
the split takes a different shape here: an **unpackaged "wallust-theme"
extension**.

- **Structural half (Nix-managed, read-only)**: `vscode.nix`'s
  `home.file.".vscode/extensions/wallust-theme/package.json"` — a static
  extension manifest declaring one contributed theme, `"Wallust"`, pointing
  at `./themes/wallust-color-theme.json`. This never changes, so a
  home-manager-managed store symlink is fine for it.
- **Color half (wallust-owned, mutable)**: `wallust.nix`'s
  `[templates.vscode]` renders straight into
  `~/.vscode/extensions/wallust-theme/themes/wallust-color-theme.json` on
  every `wallust run` — outside home-manager's management, same as
  `mako`/`btop`'s config files (see `theming.md`).

The color-theme JSON maps wallust's 16-color palette to VS Code's schema —
`colors` for editor/UI chrome (background, status bar, tabs, terminal ANSI
colors 0–15, ...) and `tokenColors` for TextMate syntax scopes (comment,
string, keyword, function, type, ...) — using the same color-slot-to-role
mapping as `neovim.nix`'s `theme.lua` (color1=red, 2=green, 3=yellow,
4=blue, 5=magenta, 6=cyan, 7=foreground/white, 0/8=background/bright-black
tones).

`userSettings."workbench.colorTheme" = "Wallust"` selects it.

### First-time setup on an existing machine

`wallustSeed`'s first-boot activation (`wallust.nix`) only fires `wallust
run` automatically when `~/.cache/wallust/` is *empty* — i.e. on a genuinely
fresh install. On a machine that already has wallust set up (this one), the
new `[templates.vscode]` target won't exist until you re-run wallust once
after pulling this change:

```bash
nrs                      # picks up vscode.nix + the new template
wallust run <wallpaper>   # any wallpaper already in ~/Pictures/wallpapers/ works
```

### Reload behavior — manual, not automatic

**Not in wallust's `[hooks]` reload list, and there's no CLI reload trick to
add one for** — unlike kitty/mako/hyprland (an actual remote-control reload
command) or Neovim (at least picks up the new palette on next startup), a
running VS Code window keeps the old theme in memory until you manually run
**`Developer: Reload Window`** from the command palette (or just restart VS
Code). This is a harder limit than Neovim's "reopen the file" — genuinely no
way to make an already-running window notice, so it's not attempted. Same
honest-scope-boundary spirit as `gtk-qt.md`'s GTK/Qt section.
