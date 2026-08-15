{ ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    # Hyprland's native config language is now Lua (hyprland.lua) rather than
    # hyprlang (hyprland.conf). Written as raw extraConfig instead of the
    # `settings` attrset — home-manager's Nix->Lua generator currently mangles
    # the "$mod"-style variable trick (see nix-community/home-manager#9468),
    # so a `local mainMod = "SUPER"` in real Lua sidesteps that bug entirely.
    configType = "lua";
    extraConfig = ''
      hl.monitor({
          output   = "",
          mode     = "preferred",
          position = "auto",
          scale    = 1,
      })

      hl.config({
          input = {
              kb_layout = "us",
              follow_mouse = 1,
          },

          general = {
              gaps_in = 4,
              gaps_out = 8,
              border_size = 2,
              layout = "dwindle",
          },
      })

      local mainMod = "SUPER"

      hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
      hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
      hl.bind(mainMod .. " + M",      hl.dsp.exit())
      hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd("wofi --show drun"))
      hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
    '';
  };
}
