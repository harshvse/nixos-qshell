{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # Pinned explicitly: home-manager's default for these flipped to false
    # (nixpkgs#492131 dropped python3/ruby providers from neovim's own
    # defaults, and home-manager now only defaults to true while
    # home.stateVersion stays below "26.05" — a gate we'll cross one day).
    withPython3 = true;
    withRuby = true;

    # Plugins come from nixpkgs (vimPlugins), not a Lua plugin manager
    # (lazy.nvim/packer). Same "nothing fetched at runtime" ethos as the
    # rest of this repo (see wallust.nix): `nix flake update` is the only
    # way plugin versions change here, and a fresh machine gets a working
    # Neovim on first `nrs` with no `:Lazy sync` step.
    plugins = with pkgs.vimPlugins; [
      # Grammars for every language this config is asked to support, plus a
      # few silent injection dependencies so their highlight queries don't
      # error looking for @regex/@jsdoc/etc: markdown+vimdoc so `:help` and
      # LSP hover popups render properly, json/jsdoc/regex as JS/TS
      # injections, qmldir alongside qmljs for Quickshell's QML.
      (nvim-treesitter.withPlugins (p: [
        p.rust
        p.c
        p.cpp
        p.python
        p.javascript
        p.typescript
        p.tsx
        p.qmljs
        p.qmldir
        p.lua
        p.bash
        p.fish
        p.json
        p.jsdoc
        p.regex
        p.markdown
        p.markdown_inline
        p.vimdoc
      ]))

      nvim-lspconfig

      # Completion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      lspkind-nvim

      # Formatting (manual, via <leader>f — see lua/lsp.lua). Not wired to
      # format-on-save: an unfamiliar formatter silently rewriting a buffer
      # on every write is more surprising than helpful.
      conform-nvim
    ];

    # LSP servers + formatters/linters for every language above. Kept on
    # Neovim's own PATH via extraPackages (home-manager wraps the neovim
    # binary with these prepended) rather than home.nix's home.packages —
    # same "package lives with the program module that needs it" pattern as
    # wallust.nix pulling in pkgs.wallust itself.
    extraPackages = with pkgs; [
      rust-analyzer
      rustfmt
      # nvim-lspconfig's rust_analyzer root_dir/sysroot resolution shells out
      # to `rustc`/`cargo` unconditionally (see lsp/rust_analyzer.lua) — with
      # neither on PATH it throws a hard ENOENT error on every Rust buffer,
      # not just a degraded experience. rust-analyzer alone isn't enough.
      cargo
      rustc

      clang-tools # clangd + clang-format

      pyright
      ruff

      typescript-language-server
      typescript
      prettier

      lua-language-server
      stylua

      bash-language-server
      shellcheck
      shfmt

      fish-lsp # fish_indent for formatting comes from the fish package itself

      qt6.qtdeclarative # qmlls + qmlformat, for Quickshell's QML
    ];

    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set shiftwidth=2
      set tabstop=2
      set termguicolors
    '';

    # The actual setup lives in lua/config/*.lua below (xdg.configFile),
    # loaded via require() the same way any hand-written Neovim config would
    # organize itself — this string just wires the load order together.
    #
    # Namespaced under "config." rather than bare names: nvim-cmp's own
    # top-level module IS `require("cmp")`, and conform.nvim's own is
    # `require("conform")`. A bare lua/cmp.lua of ours would sit earlier on
    # &runtimepath than the plugin's, so its own internal `require("cmp")`
    # would resolve to *itself* instead of the plugin — E5113 "loop or
    # previous error loading module 'cmp'". Namespacing every file we own
    # under lua/config/ avoids that collision entirely, for these two and
    # for anything added later.
    initLua = ''
      vim.g.mapleader = " "

      require("config.treesitter")
      require("config.lsp")
      require("config.cmp")
      require("config.conform")
      require("config.theme").apply()
    '';
  };

  # Real files under ~/.config/nvim/lua/config/, not just an inline string in
  # this .nix file — the config is big enough now (treesitter/LSP/cmp/
  # theming) that one giant extraLuaConfig string would be unreadable. Same
  # split-into-named-files approach wallust.nix uses for its templates.
  #
  # These are home-manager-managed symlinks into the Nix store, so they're
  # read-only at runtime — edit them here and `nrs`, same as every other
  # xdg.configFile in this repo.
  xdg.configFile = {
    "nvim/lua/config/treesitter.lua".text = ''
      -- Grammars are installed via Nix (nvim-treesitter.withPlugins above),
      -- not at runtime, so there's no nvim-treesitter.install() call here —
      -- this just turns on highlighting + treesitter-based indent per buffer.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
          end
        end,
      })
    '';

    "nvim/lua/config/lsp.lua".text = ''
      -- Server configs below are nvim-lspconfig's `lsp/<name>.lua` defaults
      -- (cmd, filetypes, root_markers) — this file only overrides settings
      -- that actually need it, then enables the full set with
      -- vim.lsp.enable(). Neovim 0.11+'s native vim.lsp.config/vim.lsp.enable
      -- API, not the old `require('lspconfig').<name>.setup{}` style.
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            check = { command = "clippy" },
          },
        },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.enable({
        "rust_analyzer",
        "clangd",
        "pyright",
        "ruff",
        "ts_ls",
        "lua_ls",
        "bashls",
        "fish_lsp",
        "qmlls",
      })

      -- Diagnostic display — colors for these groups come from
      -- lua/theme.lua (DiagnosticError/Warn/Info/Hint), generated from the
      -- same wallust palette as everything else, with check_contrast on
      -- (see wallust.nix) so they stay legible against the current
      -- wallpaper's background.
      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●" },
        severity_sort = true,
        float = { border = "rounded" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
          map("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, "Prev diagnostic")
          map("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, "Next diagnostic")
          map("n", "<leader>f", function()
            require("conform").format({ async = true, lsp_fallback = true, bufnr = bufnr })
          end, "Format buffer")
        end,
      })
    '';

    "nvim/lua/config/cmp.lua".text = ''
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          format = require("lspkind").cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })
    '';

    "nvim/lua/config/conform.lua".text = ''
      require("conform").setup({
        formatters_by_ft = {
          rust = { "rustfmt" },
          c = { "clang_format" },
          cpp = { "clang_format" },
          python = { "ruff_format" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          lua = { "stylua" },
          sh = { "shfmt" },
          bash = { "shfmt" },
          fish = { "fish_indent" },
          qml = { "qmlformat" },
          qmljs = { "qmlformat" },
        },
        -- No format_on_save: format is opt-in via <leader>f (lua/lsp.lua's
        -- LspAttach keymap), which also falls back to the buffer's LSP
        -- formatter (lsp_fallback = true) for filetypes with no entry above.
      })
    '';

    "nvim/lua/config/theme.lua".text = ''
      -- Wallust-driven colorscheme. Reads the same generated palette
      -- (~/.cache/wallust/nvim-colors.lua) every other themed program in
      -- this repo re-renders on `wallust run <wallpaper>` — see
      -- wallust.nix and docs/theming.md. No colorscheme plugin: just
      -- vim.api.nvim_set_hl calls built from a plain Lua table, kept
      -- trivial to extend as new plugins/languages get added.
      --
      -- Reload behavior is startup-only — see docs/neovim.md's "Reload
      -- behavior" section for why Neovim is deliberately not in wallust's
      -- [hooks] live-reload list.
      local M = {}

      function M.colors()
        local ok, colors = pcall(dofile, vim.fn.expand("~/.cache/wallust/nvim-colors.lua"))
        if ok and colors then
          return colors
        end
        return nil
      end

      function M.apply()
        local c = M.colors()
        if not c then
          -- No wallust run yet (fresh install, before the first wallpaper
          -- pick) — fall through to Neovim's built-in default highlighting
          -- rather than erroring.
          return
        end

        local groups = {
          -- Core editor UI
          Normal = { fg = c.fg, bg = c.bg },
          NormalFloat = { fg = c.fg, bg = c.black },
          FloatBorder = { fg = c.blue, bg = c.black },
          CursorLine = { bg = c.black },
          CursorLineNr = { fg = c.blue, bold = true },
          LineNr = { fg = c.bright_black },
          Visual = { bg = c.black },
          StatusLine = { fg = c.fg, bg = c.black },
          StatusLineNC = { fg = c.bright_black, bg = c.black },
          WinSeparator = { fg = c.black },
          Pmenu = { fg = c.fg, bg = c.black },
          PmenuSel = { fg = c.bg, bg = c.blue },
          PmenuThumb = { bg = c.bright_black },
          Search = { fg = c.bg, bg = c.yellow },
          IncSearch = { fg = c.bg, bg = c.red },
          MatchParen = { fg = c.yellow, bold = true },

          -- Base syntax (fallback/link target for filetypes with no
          -- treesitter grammar)
          Comment = { fg = c.bright_black, italic = true },
          String = { fg = c.green },
          Number = { fg = c.yellow },
          Boolean = { fg = c.yellow },
          Function = { fg = c.blue },
          Keyword = { fg = c.magenta },
          Identifier = { fg = c.cyan },
          Constant = { fg = c.yellow },
          Type = { fg = c.yellow },
          Operator = { fg = c.fg },
          Delimiter = { fg = c.bright_black },

          -- Treesitter capture groups, covering rust/c/cpp/python/js/ts/tsx/
          -- qml/lua/bash/fish
          ["@variable"] = { fg = c.fg },
          ["@variable.builtin"] = { fg = c.red, italic = true },
          ["@variable.parameter"] = { fg = c.cyan },
          ["@variable.member"] = { fg = c.cyan },
          ["@property"] = { fg = c.cyan },
          ["@constant"] = { fg = c.yellow },
          ["@constant.builtin"] = { fg = c.red },
          ["@string"] = { fg = c.green },
          ["@string.escape"] = { fg = c.magenta },
          ["@string.special"] = { fg = c.magenta },
          ["@character"] = { fg = c.green },
          ["@number"] = { fg = c.yellow },
          ["@boolean"] = { fg = c.yellow },
          ["@function"] = { fg = c.blue },
          ["@function.builtin"] = { fg = c.blue, italic = true },
          ["@function.call"] = { fg = c.blue },
          ["@method"] = { fg = c.blue },
          ["@method.call"] = { fg = c.blue },
          ["@constructor"] = { fg = c.yellow },
          ["@keyword"] = { fg = c.magenta },
          ["@keyword.function"] = { fg = c.magenta },
          ["@keyword.return"] = { fg = c.magenta },
          ["@keyword.operator"] = { fg = c.magenta },
          ["@keyword.import"] = { fg = c.magenta },
          ["@conditional"] = { fg = c.magenta },
          ["@repeat"] = { fg = c.magenta },
          ["@type"] = { fg = c.yellow },
          ["@type.builtin"] = { fg = c.yellow, italic = true },
          ["@attribute"] = { fg = c.cyan },
          ["@namespace"] = { fg = c.cyan },
          ["@module"] = { fg = c.cyan },
          ["@operator"] = { fg = c.fg },
          ["@punctuation.delimiter"] = { fg = c.bright_black },
          ["@punctuation.bracket"] = { fg = c.bright_black },
          ["@punctuation.special"] = { fg = c.magenta },
          ["@comment"] = { fg = c.bright_black, italic = true },
          ["@tag"] = { fg = c.magenta },
          ["@tag.attribute"] = { fg = c.cyan, italic = true },
          ["@tag.delimiter"] = { fg = c.bright_black },
          ["@markup.heading"] = { fg = c.blue, bold = true },
          ["@markup.strong"] = { bold = true },
          ["@markup.italic"] = { italic = true },
          ["@markup.link"] = { fg = c.cyan, underline = true },

          -- LSP diagnostics — the palette is generated with check_contrast
          -- on (wallust.nix), so these stay readable against the current bg
          DiagnosticError = { fg = c.red },
          DiagnosticWarn = { fg = c.yellow },
          DiagnosticInfo = { fg = c.blue },
          DiagnosticHint = { fg = c.cyan },
          DiagnosticUnderlineError = { sp = c.red, undercurl = true },
          DiagnosticUnderlineWarn = { sp = c.yellow, undercurl = true },
          DiagnosticUnderlineInfo = { sp = c.blue, undercurl = true },
          DiagnosticUnderlineHint = { sp = c.cyan, undercurl = true },
          LspReferenceText = { bg = c.black },
          LspReferenceRead = { bg = c.black },
          LspReferenceWrite = { bg = c.black, underline = true },
          LspInlayHint = { fg = c.bright_black, bg = c.black, italic = true },

          -- nvim-cmp completion menu
          CmpItemAbbrMatch = { fg = c.blue, bold = true },
          CmpItemAbbrMatchFuzzy = { fg = c.blue },
          CmpItemKindFunction = { fg = c.blue },
          CmpItemKindMethod = { fg = c.blue },
          CmpItemKindVariable = { fg = c.cyan },
          CmpItemKindKeyword = { fg = c.magenta },
          CmpItemKindText = { fg = c.fg },
          CmpItemKindSnippet = { fg = c.green },
          CmpItemKindModule = { fg = c.yellow },
          CmpItemKindClass = { fg = c.yellow },

          -- Diffs
          DiffAdd = { fg = c.green },
          DiffChange = { fg = c.yellow },
          DiffDelete = { fg = c.red },
          DiffText = { fg = c.blue },
        }

        for group, opts in pairs(groups) do
          vim.api.nvim_set_hl(0, group, opts)
        end
      end

      return M
    '';
  };
}
