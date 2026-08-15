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
      -- REQUIRED: these are placeholders. After first boot with both monitors
      -- plugged in, run `hyprctl monitors` and replace monLeft/monRight below
      -- with the real connector names it reports (e.g. "DP-1", "HDMI-A-1").
      local monLeft  = "MONITOR-LEFT"
      local monRight = "MONITOR-RIGHT"

      hl.monitor({
          output   = monLeft,
          mode     = "1920x1080@60",
          position = "0x0",
          scale    = 1,
      })
      hl.monitor({
          output   = monRight,
          mode     = "1920x1080@60",
          position = "1920x0",
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

      -- Move focus between windows with mainMod + arrow keys
      hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

      -----------------------------
      ---- WORKSPACE MANAGEMENT ----
      -----------------------------

      -- Switch to workspace [1-10] with mainMod + [0-9]
      -- Move active window to workspace [1-10] with mainMod + SHIFT + [0-9]
      for i = 1, 10 do
          local key = i % 10 -- 10 maps to key 0
          hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      -- Scroll through existing workspaces with mainMod + scroll wheel
      hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

      -- Jump focus straight to the left/right monitor
      hl.bind(mainMod .. " + comma",  hl.dsp.focus({ monitor = monLeft }))
      hl.bind(mainMod .. " + period", hl.dsp.focus({ monitor = monRight }))

      -- Send the active workspace to the left/right monitor
      hl.bind(mainMod .. " + SHIFT + comma",  hl.dsp.workspace.move({ monitor = monLeft }))
      hl.bind(mainMod .. " + SHIFT + period", hl.dsp.workspace.move({ monitor = monRight }))
    '';
  };
}
