# btop

Source: `home/programs/btop.nix`.

```nix
{ ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "wallust";
      theme_background = false;
      vim_keys = true;
    };
  };
}
```

## Split: structural config is Nix-managed, the theme file isn't

- `programs.btop.settings` (this file) manages btop's *main* config —
  which theme to use by name, whether to draw its own background, vim-style
  navigation keys. This part is ordinary home-manager management, no
  special handling needed, because it doesn't contain any color values
  itself.
- `color_theme = "wallust"` tells btop to load a theme *file* named
  `wallust.theme` from its themes directory
  (`~/.config/btop/themes/wallust.theme`). That file is generated entirely
  by wallust at runtime (`[templates.btop]` in `wallust.toml`, see
  [theming.md](theming.md)) and is **not** touched by this module or any
  `xdg.configFile` entry — same reasoning as [mako.md](mako.md): a
  Nix-managed symlink at that path would block wallust from overwriting it.
- `theme_background = false`: btop doesn't paint its own background color,
  letting the terminal's own background (themed by kitty, see
  [kitty.md](kitty.md)) show through instead.

## What the generated theme covers

The `btop.theme` template (see [theming.md](theming.md)'s template table)
maps the full btop theme key set — `main_bg`/`main_fg`, per-box colors
(`cpu_box`, `mem_box`, `net_box`, `proc_box`), and gradient stops for every
graph (`cpu_start`/`cpu_mid`/`cpu_end`, `download_*`, `upload_*`,
`temp_*`, etc.) — to the current 16-color palette, mostly using `color4`
(the palette's blue-ish accent) and `color2` (green) as the primary
gradient anchors.

Relaunch btop after a wallpaper change to see the new theme — it's not
signaled to reload live.
