# Single source of truth for colors.
#
# Right now these are just fixed placeholder values. The plan for phase 2:
# a wallpaper-change hook runs `wallust` (a maintained Rust rewrite of pywal),
# which regenerates a file like this one from the wallpaper's palette. Every
# themed program below already reads its colors from here, so once that hook
# exists, changing your wallpaper re-themes everything with one
# `home-manager switch` — no per-app edits needed.
{
  background = "#1e1e2e";
  foreground = "#cdd6f4";
  black   = "#45475a";
  red     = "#f38ba8";
  green   = "#a6e3a1";
  yellow  = "#f9e2af";
  blue    = "#89b4fa";
  magenta = "#f5c2e7";
  cyan    = "#94e2d5";
  white   = "#bac2de";
}
