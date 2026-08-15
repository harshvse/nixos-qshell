# Neovim

Source: `home/programs/neovim.nix`.

## Module setup

```nix
programs.neovim = {
  enable = true;
  viAlias = true;
  vimAlias = true;
  defaultEditor = true;
  withPython3 = true;
  withRuby = true;
  extraConfig = '' ... '';
};
```

- `viAlias`/`vimAlias`: `vi`/`vim` on the command line both resolve to this
  Neovim.
- `defaultEditor = true`: sets `$EDITOR`.
- `withPython3`/`withRuby` are pinned explicitly to `true` rather than left
  at home-manager's default. As of nixpkgs#492131, Neovim's own upstream
  defaults for these providers changed to `false`; home-manager currently
  only keeps defaulting them to `true` while `home.stateVersion` stays below
  `"26.05"` (see `home/home.nix` — currently `"25.05"`). This is a gate that
  will need revisiting when `stateVersion` eventually crosses that
  threshold — don't bump `stateVersion` without checking whether these
  still need to be explicit afterward.

## Editor settings

```vim
set number
set relativenumber
set expandtab
set shiftwidth=2
set tabstop=2
set termguicolors
```

Standard hybrid line numbers, 2-space soft tabs, truecolor support enabled
(`termguicolors`) — required for the palette-driven highlight groups below
to render actual hex colors rather than being downsampled to a 256-color
approximation.

## Palette-driven highlighting

```lua
lua << EOF
local ok, colors = pcall(dofile, "<home>/.cache/wallust/nvim-colors.lua")
if ok and colors then
    local hl = vim.api.nvim_set_hl
    hl(0, "Normal",       { fg = colors.fg, bg = colors.bg })
    hl(0, "Comment",      { fg = colors.bright_black, italic = true })
    hl(0, "String",       { fg = colors.green })
    hl(0, "Function",     { fg = colors.blue })
    -- ... Keyword, Identifier, Constant, Type, CursorLine, LineNr,
    --     CursorLineNr, Visual, Pmenu, PmenuSel, StatusLine,
    --     DiffAdd/Change/Delete
end
EOF
```

Rather than a full colorscheme plugin, this is a small inline loader:
`dofile()`s the wallust-generated `~/.cache/wallust/nvim-colors.lua` (a
plain Lua table — see [theming.md](theming.md) for its exact shape) and
calls `vim.api.nvim_set_hl` directly for a curated set of highlight groups.
Wrapped in `pcall` so a Neovim launch before the very first `wallust run`
(no generated file yet) doesn't error — it just falls through with no
custom highlights, leaving Neovim's built-in default colors in place.

This runs at the end of `extraConfig`, after Neovim's own built-in default
highlighting has already loaded, so nothing overrides it afterward.

## Reload behavior — startup only

**Already-open Neovim buffers do not pick up a wallpaper change
automatically.** The loader only runs once, at startup. To see a new
palette in a session that's already running, either:
- open a new Neovim instance, or
- re-source this config manually (`:source $MYVIMRC` or equivalent).

This is a deliberate scope decision (see [theming.md](theming.md)'s
"Reload orchestration" section) — Neovim was left out of wallust's
`[hooks]` reload list rather than trying to wire up a live-reload command
channel into every running instance.
