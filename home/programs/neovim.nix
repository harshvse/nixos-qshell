{ config, ... }:
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
    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set shiftwidth=2
      set tabstop=2
      set termguicolors

      lua << EOF
      -- Colors come from a wallust-generated file at runtime (see
      -- wallust.nix), not from Nix — so a wallpaper change re-themes Neovim
      -- without a rebuild. Already-open buffers won't pick up a change
      -- automatically; re-source this file (or open a new instance) after
      -- switching wallpapers.
      local ok, colors = pcall(dofile, "${config.home.homeDirectory}/.cache/wallust/nvim-colors.lua")
      if ok and colors then
          local hl = vim.api.nvim_set_hl
          hl(0, "Normal",       { fg = colors.fg, bg = colors.bg })
          hl(0, "NormalFloat",  { fg = colors.fg, bg = colors.bg })
          hl(0, "Comment",      { fg = colors.bright_black, italic = true })
          hl(0, "String",       { fg = colors.green })
          hl(0, "Function",     { fg = colors.blue })
          hl(0, "Keyword",      { fg = colors.magenta })
          hl(0, "Identifier",   { fg = colors.cyan })
          hl(0, "Constant",     { fg = colors.yellow })
          hl(0, "Type",         { fg = colors.yellow })
          hl(0, "CursorLine",   { bg = colors.black })
          hl(0, "LineNr",       { fg = colors.bright_black })
          hl(0, "CursorLineNr", { fg = colors.blue })
          hl(0, "Visual",       { bg = colors.black })
          hl(0, "Pmenu",        { fg = colors.fg, bg = colors.black })
          hl(0, "PmenuSel",     { fg = colors.bg, bg = colors.blue })
          hl(0, "StatusLine",   { fg = colors.fg, bg = colors.black })
          hl(0, "DiffAdd",      { fg = colors.green })
          hl(0, "DiffChange",   { fg = colors.yellow })
          hl(0, "DiffDelete",   { fg = colors.red })
      end
      EOF
    '';
  };
}
