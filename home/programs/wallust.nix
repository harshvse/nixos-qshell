# Single source of truth for the live color palette.
#
# `wallust run <image>` reads a wallpaper and renders the [templates] below
# into files under ~/.cache/wallust/ (or, for apps with no include mechanism,
# straight into that app's real config path). Every themed program elsewhere
# in this repo either `include`s/`@import`s one of those generated files at
# its *runtime* path, or reads its config from a path wallust owns outright —
# none of them see color values at Nix build time. That split is what lets a
# wallpaper change re-theme everything instantly with no `nixos-rebuild`.
#
# IMPORTANT: nothing in this module manages the *target* paths below with
# home-manager (no xdg.configFile pointing at them). Home-manager-managed
# files are read-only symlinks into the Nix store; wallust needs to overwrite
# these as plain mutable files on every run, so only their parent directories
# are created here.
{ pkgs, lib, ... }:
let
  cacheDir = "$HOME/.cache/wallust";
  wallpaperDir = "$HOME/Pictures/wallpapers";
  defaultWallpaper = "${wallpaperDir}/default.png";
in
{
  home.packages = [ pkgs.wallust ];

  xdg.configFile = {
    "wallust/wallust.toml".text = ''
      # "dark16" generates 16 genuinely distinct colors (plain `dark` only
      # picks 8 and duplicates them into the bright range); check_contrast
      # rejects any color too close in luminance to the background, which is
      # what was making some ANSI colors unreadable against dark wallpapers.
      palette = "dark16"
      check_contrast = true

      [templates.kitty]
      template = "kitty.conf"
      target = "~/.cache/wallust/kitty-colors.conf"

      [templates.waybar]
      template = "waybar.css"
      target = "~/.cache/wallust/waybar-colors.css"

      [templates.wofi]
      template = "wofi.css"
      target = "~/.cache/wallust/wofi-colors.css"

      [templates.hyprland]
      template = "hyprland-colors.lua"
      target = "~/.cache/wallust/hyprland-colors.lua"

      [templates.nvim]
      template = "nvim-colors.lua"
      target = "~/.cache/wallust/nvim-colors.lua"

      [templates.gtk-accent]
      template = "gtk-accent.css"
      target = "~/.cache/wallust/gtk-accent.css"

      [templates.mako]
      template = "mako-config"
      target = "~/.config/mako/config"

      [templates.btop]
      template = "btop.theme"
      target = "~/.config/btop/themes/wallust.theme"

      [templates.fastfetch]
      template = "fastfetch.jsonc"
      target = "~/.config/fastfetch/config.jsonc"

      # Reload already-running apps after templates render. kitty needs a
      # fixed control socket (set in kitty.nix) since these hooks don't run
      # inside a kitty session, so $KITTY_LISTEN_ON isn't set.
      [hooks]
      kitty = "kitty @ --to unix:/tmp/kitty-wallust-socket load-config >/dev/null 2>&1 || true"
      waybar = "pkill -SIGUSR2 waybar >/dev/null 2>&1 || true"
      mako = "makoctl reload >/dev/null 2>&1 || true"
      hyprland = "hyprctl reload >/dev/null 2>&1 || true"
    '';

    "wallust/templates/kitty.conf".text = ''
      background {{background}}
      foreground {{foreground}}
      cursor     {{cursor}}
      color0  {{color0}}
      color1  {{color1}}
      color2  {{color2}}
      color3  {{color3}}
      color4  {{color4}}
      color5  {{color5}}
      color6  {{color6}}
      color7  {{color7}}
      color8  {{color8}}
      color9  {{color9}}
      color10 {{color10}}
      color11 {{color11}}
      color12 {{color12}}
      color13 {{color13}}
      color14 {{color14}}
      color15 {{color15}}
    '';

    "wallust/templates/waybar.css".text = ''
      @define-color background {{background}};
      @define-color foreground {{foreground}};
      @define-color color0  {{color0}};
      @define-color color1  {{color1}};
      @define-color color2  {{color2}};
      @define-color color3  {{color3}};
      @define-color color4  {{color4}};
      @define-color color5  {{color5}};
      @define-color color6  {{color6}};
      @define-color color7  {{color7}};
      @define-color color8  {{color8}};
      @define-color color9  {{color9}};
      @define-color color10 {{color10}};
      @define-color color11 {{color11}};
      @define-color color12 {{color12}};
      @define-color color13 {{color13}};
      @define-color color14 {{color14}};
      @define-color color15 {{color15}};
    '';

    "wallust/templates/wofi.css".text = ''
      @define-color background {{background}};
      @define-color foreground {{foreground}};
      @define-color color0  {{color0}};
      @define-color color1  {{color1}};
      @define-color color2  {{color2}};
      @define-color color3  {{color3}};
      @define-color color4  {{color4}};
      @define-color color5  {{color5}};
      @define-color color6  {{color6}};
      @define-color color7  {{color7}};
    '';

    "wallust/templates/gtk-accent.css".text = ''
      @define-color accent {{color4}};
    '';

    "wallust/templates/hyprland-colors.lua".text = ''
      return {
          active_border   = "{{color4}}",
          inactive_border = "{{color0}}",
      }
    '';

    "wallust/templates/nvim-colors.lua".text = ''
      return {
          bg = "{{background}}",
          fg = "{{foreground}}",
          black   = "{{color0}}",
          red     = "{{color1}}",
          green   = "{{color2}}",
          yellow  = "{{color3}}",
          blue    = "{{color4}}",
          magenta = "{{color5}}",
          cyan    = "{{color6}}",
          white   = "{{color7}}",
          bright_black   = "{{color8}}",
          bright_red     = "{{color9}}",
          bright_green   = "{{color10}}",
          bright_yellow  = "{{color11}}",
          bright_blue    = "{{color12}}",
          bright_magenta = "{{color13}}",
          bright_cyan    = "{{color14}}",
          bright_white   = "{{color15}}",
      }
    '';

    "wallust/templates/fastfetch.jsonc".text = ''
      {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "display": {
          "separator": "  "
        },
        "modules": [
          { "type": "title", "keyColor": "{{color4}}" },
          "separator",
          { "type": "os", "key": "OS", "keyColor": "{{color4}}" },
          { "type": "kernel", "key": "Kernel", "keyColor": "{{color4}}" },
          { "type": "de", "key": "DE", "keyColor": "{{color4}}" },
          { "type": "shell", "key": "Shell", "keyColor": "{{color4}}" },
          { "type": "terminal", "key": "Terminal", "keyColor": "{{color4}}" },
          { "type": "cpu", "key": "CPU", "keyColor": "{{color2}}" },
          { "type": "gpu", "key": "GPU", "keyColor": "{{color2}}" },
          { "type": "memory", "key": "Memory", "keyColor": "{{color2}}" },
          "break",
          { "type": "colors", "paddingLeft": 2 }
        ]
      }
    '';

    "wallust/templates/mako-config".text = ''
      font=JetBrainsMono Nerd Font 10
      width=350
      height=150
      padding=10
      border-size=2
      border-radius=8
      margin=10
      default-timeout=5000
      anchor=top-right

      background-color={{background}}
      text-color={{foreground}}
      border-color={{color4}}

      [urgency=low]
      border-color={{color0}}

      [urgency=high]
      border-color={{color1}}
      default-timeout=0
    '';

    "wallust/templates/btop.theme".text = ''
      theme[main_bg]="{{background}}"
      theme[main_fg]="{{foreground}}"
      theme[title]="{{foreground}}"
      theme[hi_fg]="{{color4}}"
      theme[selected_bg]="{{color4}}"
      theme[selected_fg]="{{background}}"
      theme[inactive_fg]="{{color0}}"
      theme[graph_text]="{{foreground}}"
      theme[proc_misc]="{{color6}}"
      theme[cpu_box]="{{color4}}"
      theme[mem_box]="{{color2}}"
      theme[net_box]="{{color5}}"
      theme[proc_box]="{{color6}}"
      theme[div_line]="{{color0}}"
      theme[temp_start]="{{color2}}"
      theme[temp_mid]="{{color3}}"
      theme[temp_end]="{{color1}}"
      theme[cpu_start]="{{color4}}"
      theme[cpu_mid]="{{color5}}"
      theme[cpu_end]="{{color1}}"
      theme[free_start]="{{color2}}"
      theme[free_mid]="{{color6}}"
      theme[free_end]="{{color4}}"
      theme[cached_start]="{{color4}}"
      theme[cached_mid]="{{color5}}"
      theme[cached_end]="{{color1}}"
      theme[available_start]="{{color2}}"
      theme[available_mid]="{{color3}}"
      theme[available_end]="{{color1}}"
      theme[used_start]="{{color4}}"
      theme[used_mid]="{{color5}}"
      theme[used_end]="{{color1}}"
      theme[download_start]="{{color2}}"
      theme[download_mid]="{{color6}}"
      theme[download_end]="{{color4}}"
      theme[upload_start]="{{color5}}"
      theme[upload_mid]="{{color1}}"
      theme[upload_end]="{{color3}}"
      theme[process_start]="{{color4}}"
      theme[process_mid]="{{color5}}"
      theme[process_end]="{{color1}}"
    '';
  };

  # Seed a default palette on first activation so nothing is left unthemed
  # before the user ever runs the wallpaper picker. Idempotent: only acts
  # when the cache directory doesn't exist yet.
  home.activation.wallustSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${wallpaperDir} ${cacheDir} \
      "$HOME/.config/mako" "$HOME/.config/btop/themes" "$HOME/.config/fastfetch"

    if [ -z "$(ls -A ${cacheDir} 2>/dev/null)" ]; then
      if [ ! -e ${defaultWallpaper} ]; then
        # A plain 2-stop gradient doesn't have enough distinct colors for
        # wallust to build a 16-color palette from (it errors out with
        # "Not enough colors!"); a plasma fractal has plenty of variation.
        run ${pkgs.imagemagick}/bin/convert -size 1920x1080 \
          plasma:fractal ${defaultWallpaper}
      fi
      run ${pkgs.wallust}/bin/wallust run ${defaultWallpaper} || true
    fi
  '';
}
