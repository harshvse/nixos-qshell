# Neovim

Source: `home/programs/neovim.nix`. A full setup — treesitter, LSP,
completion, formatting, wallust-driven theming — for Rust, C/C++, Python,
JavaScript/TypeScript, Quickshell's QML, Lua, Bash, and Fish.

## Module setup

```nix
programs.neovim = {
  enable = true;
  viAlias = true;
  vimAlias = true;
  defaultEditor = true;
  withPython3 = true;
  withRuby = true;
  plugins = [ ... ];
  extraPackages = [ ... ];
  extraConfig = '' ... '';   # vimscript options
  initLua = '' ... '';       # wires up the require()s below
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

## No plugin manager

Plugins come from nixpkgs (`vimPlugins`), passed to `programs.neovim.plugins`
— not lazy.nvim/packer. Same "nothing fetched at runtime" ethos as the rest
of this repo (see `wallust.nix`): `nix flake update` is the only way plugin
versions change, and a fresh machine gets a fully working setup on first
`nrs` with no `:Lazy sync`/`:PackerSync` step, no network access needed at
Neovim startup.

The trade-off: adding a plugin means editing `neovim.nix` and rebuilding,
not `:Lazy install` from inside Neovim. Consistent with how every other
program in this repo is managed.

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

`vim.g.mapleader = " "` is set at the top of `initLua` — every `<leader>...`
mapping below is Space-prefixed.

## Where the config actually lives

`initLua` itself is just four `require()` calls:

```lua
require("treesitter")
require("lsp")
require("cmp")
require("conform")
require("theme").apply()
```

The real content is in `xdg.configFile."nvim/lua/*.lua"` — real files under
`~/.config/nvim/lua/`, same split-into-named-files approach `wallust.nix`
uses for its templates, because one giant `initLua` string would be
unreadable at this size. Like every other `xdg.configFile` entry in this
repo, these are home-manager-managed symlinks into the Nix store — **read-
only at runtime**. Edit them in `neovim.nix` and `nrs`; there's no in-place
Neovim-config iteration loop like Quickshell's shell.qml has (see
`docs/quickshell/README.md`), because none of this is expected to need
fast iteration the way QML-under-active-development does.

| File | Covers |
|---|---|
| `lua/treesitter.lua` | Turns on highlighting + treesitter-based indent per buffer |
| `lua/lsp.lua` | Server configs, `vim.lsp.enable()`, diagnostics, LSP keymaps |
| `lua/cmp.lua` | nvim-cmp completion menu + keymaps |
| `lua/conform.lua` | Formatter-by-filetype table, no format-on-save |
| `lua/theme.lua` | Wallust palette → highlight groups (treesitter, LSP, cmp, diffs) |

## Treesitter

Grammars are installed via Nix, not at runtime:

```nix
(nvim-treesitter.withPlugins (p: [
  p.rust p.c p.cpp p.python p.javascript p.typescript p.tsx
  p.qmljs p.qmldir p.lua p.bash p.fish
  p.json p.jsdoc p.regex p.markdown p.markdown_inline p.vimdoc
]))
```

One grammar per requested language, plus a handful of silent injection
dependencies so highlight queries don't error looking for an embedded
language: `json`/`jsdoc`/`regex` are things JS/TS's own queries inject into
comments and template literals; `markdown`/`markdown_inline`/`vimdoc` make
`:help` pages and LSP hover popups (which render as markdown) highlight
correctly.

nixpkgs' `nvim-treesitter` is currently on its post-rewrite "main" branch —
there's no `nvim-treesitter.configs` module anymore, and no
`:TSInstall`/`nvim-treesitter.install()` call in this config at all (the
grammars are already on the runtimepath via Nix). `lua/treesitter.lua` is
just:

```lua
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
    end
  end,
})
```

`vim.treesitter.start()` is core Neovim (0.10+), not plugin-specific — it
just needs a matching parser to be findable on the runtimepath, which the
Nix-installed grammars provide.

## LSP

Neovim 0.11+'s native `vim.lsp.config()` / `vim.lsp.enable()` API — **not**
the older `require('lspconfig').<name>.setup{}` style. `nvim-lspconfig`
still ships the per-server defaults (`cmd`, `filetypes`, `root_markers`),
now as `lsp/<name>.lua` files that `vim.lsp.enable()` picks up automatically
once the plugin is on the runtimepath; `lua/lsp.lua` only overrides what
actually needs it.

| Language | Server | Package |
|---|---|---|
| Rust | `rust_analyzer` | `rust-analyzer`, `cargo`, `rustc` |
| C/C++ | `clangd` | `clang-tools` |
| Python | `pyright` (types) + `ruff` (lint) | `pyright`, `ruff` |
| JS/TS | `ts_ls` | `typescript-language-server` + `typescript` |
| Lua | `lua_ls` | `lua-language-server` |
| Bash | `bashls` | `bash-language-server` (+ `shellcheck` on PATH for its diagnostics) |
| Fish | `fish_lsp` | `fish-lsp` |
| QML (Quickshell) | `qmlls` | `qt6.qtdeclarative` |

All of these are installed via `programs.neovim.extraPackages`, not
`home.nix`'s `home.packages` — same "the package lives with the module that
needs it" pattern as `wallust.nix` pulling in `pkgs.wallust` itself.
home-manager wraps the `nvim` binary with these prepended to its `PATH`, so
they don't need to be on your general shell `PATH` to work inside Neovim.

**`cargo`/`rustc` are there for more than "run your project"**:
nvim-lspconfig's own `lsp/rust_analyzer.lua` shells out to `rustc --print
sysroot` and `cargo metadata` unconditionally while resolving a Rust
buffer's root directory — with neither binary on `PATH` this throws a hard
`ENOENT` Lua error on every single Rust buffer you open, not just a
degraded experience. Found by headlessly opening a `.rs` file against a
built copy of this config before writing it up here — `rust-analyzer` alone
wasn't sufficient.

Per-server overrides in `lua/lsp.lua`:

```lua
local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

vim.lsp.config("rust_analyzer", {
  settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
})

vim.lsp.config("lua_ls", {
  settings = { Lua = { workspace = { checkThirdParty = false }, telemetry = { enable = false } } },
})

vim.lsp.enable({ "rust_analyzer", "clangd", "pyright", "ruff", "ts_ls", "lua_ls", "bashls", "fish_lsp", "qmlls" })
```

`vim.lsp.config("*", ...)` sets defaults merged into every server's config
— this is how `cmp-nvim-lsp`'s completion capabilities reach every language
server without repeating it eight times.

### Diagnostics

```lua
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded" },
  signs = { text = { ... } },  -- Nerd Font glyphs (JetBrainsMono Nerd Font, already installed system-wide)
})
```

Colors for `DiagnosticError`/`Warn`/`Info`/`Hint` come from `theme.lua`
(below) — pulled from the same wallust palette as everything else, which is
generated with `check_contrast = true` (see `wallust.nix`), so they stay
legible against whatever the current wallpaper's background happens to be.

### Keymaps

Set on `LspAttach` (not per-server `on_attach`) so they apply uniformly
regardless of which servers ship their own `on_attach` (rust_analyzer,
clangd, and pyright's `lsp/*.lua` configs each define one for their own
extra commands — `LspAttach` fires independently of that, so nothing here
gets shadowed):

| Keymap | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | References |
| `gI` | Go to implementation |
| `K` | Hover |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action (normal + visual) |
| `<leader>e` | Line diagnostics (float) |
| `[d` / `]d` | Prev/next diagnostic |
| `<leader>f` | Format buffer (via conform, see below) |

## Completion — nvim-cmp

`lua/cmp.lua`. Sources, in priority order: `nvim_lsp`, `luasnip`, then
`buffer`/`path` as a lower-priority group. `<Tab>`/`<S-Tab>` cycle the menu
or jump snippet placeholders (falls through to a literal tab otherwise);
`<CR>` confirms; `<C-Space>` forces the menu open; `<C-e>` aborts.
`lspkind.nvim` adds icons + kind text to menu entries — colored via
`CmpItemKind*`/`CmpItemAbbrMatch*` groups in `theme.lua`.

## Formatting — conform.nvim

`lua/conform.lua`:

```lua
formatters_by_ft = {
  rust = { "rustfmt" },
  c = { "clang_format" }, cpp = { "clang_format" },
  python = { "ruff_format" },
  javascript = { "prettier" }, javascriptreact = { "prettier" },
  typescript = { "prettier" }, typescriptreact = { "prettier" },
  json = { "prettier" },
  lua = { "stylua" },
  sh = { "shfmt" }, bash = { "shfmt" },
  fish = { "fish_indent" },       -- ships with the `fish` package itself
  qml = { "qmlformat" }, qmljs = { "qmlformat" },  -- from qt6.qtdeclarative
}
```

**Deliberately no `format_on_save`.** Formatting is opt-in via `<leader>f`
(the LSP keymap above), which calls `conform.format({ lsp_fallback = true
})` — so a filetype with no entry above still gets *something* via
whichever LSP server supports `textDocument/formatting`. An unfamiliar
formatter silently rewriting a buffer on every `:w` was judged more
surprising than helpful; revisit this if it turns out to be annoying in
practice.

## Palette-driven theming

`lua/theme.lua`. Same underlying mechanism as the previous minimal setup —
`dofile()`s the wallust-generated `~/.cache/wallust/nvim-colors.lua` (a
plain Lua table — see `theming.md` for its exact shape) and calls
`vim.api.nvim_set_hl` directly, no colorscheme plugin — just extended to
cover far more than the original ~15 groups, now that there's treesitter/
LSP/cmp UI to theme:

- **Core editor UI**: `Normal`, floats, cursorline, statusline, `Pmenu`/
  `PmenuSel` (completion menu — high-contrast selection: dark text on the
  palette's blue), search, match highlighting.
- **Base syntax** groups (`Comment`, `String`, `Function`, ...) as a
  fallback for anything without a treesitter grammar.
- **Treesitter capture groups** (`@variable`, `@function`, `@keyword`,
  `@string`, `@type`, `@tag` for QML, `@punctuation.*`, `@markup.*`, ...) —
  the actual highlighting path for every language in the table above.
  Neovim's own semantic-token default links (`@lsp.type.*` → `@variable`/
  `@function`/etc.) mean LSP semantic highlighting (e.g. rust-analyzer's)
  lands on these same groups automatically, no extra work needed here.
- **LSP/diagnostic groups**: `DiagnosticError/Warn/Info/Hint` +
  `DiagnosticUnderline*`, `LspReference*` (cursor-word highlight),
  `LspInlayHint`.
- **nvim-cmp groups**: `CmpItemKind*`, `CmpItemAbbrMatch*`.
- **Diff groups**: `DiffAdd/Change/Delete/Text`.

`M.colors()` is `pcall`-wrapped so a Neovim launch before the very first
`wallust run` (no generated file yet) doesn't error — `M.apply()` just
returns early and Neovim's built-in default highlighting stays in place.

### Reload behavior — startup only

**Already-open Neovim buffers do not pick up a wallpaper change
automatically.** The loader only runs once, at startup (`initLua` calls
`require("theme").apply()` directly, not on any autocmd). To see a new
palette in a session that's already running, either:

- open a new Neovim instance, or
- re-source: `:lua require("theme").apply()`.

This is a deliberate scope decision (see `theming.md`'s "Reload
orchestration" section) — Neovim was left out of wallust's `[hooks]` reload
list rather than trying to wire up a live-reload command channel into every
running instance.
