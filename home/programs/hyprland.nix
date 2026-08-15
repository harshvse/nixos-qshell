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
      local monLeft  = "eDP-1"
      local monRight = "HDMI-A-1"

      hl.monitor({
          output   = monLeft,
          mode     = "1920x1080@144",
          position = "0x0",
          scale    = 1.25,
      })
      -- position is in logical (post-scale) space, not physical pixels:
      -- monLeft is 1920 physical / 1.25 scale = 1536 logical wide, so
      -- monRight must start at x=1536, not x=1920, or there's a gap the
      -- cursor can't cross.
      hl.monitor({
          output   = monRight,
          mode     = "1920x1080@100",
          position = "1536x0",
          scale    = 1.25,
      })

      -- Border colors come from the wallust-generated palette (see
      -- wallust.nix) so they follow the wallpaper too; the hardcoded values
      -- are only a fallback for before the very first wallust run. NOTE:
      -- `general.col.*` naming is a best-effort guess (mirrors hyprlang's
      -- dotted `general:col.active_border` key) — not confirmed against the
      -- Lua API docs, so double check this against `hyprctl reload` output
      -- if borders don't pick up colors.
      local ok, hyprColors = pcall(dofile, os.getenv("HOME") .. "/.cache/wallust/hyprland-colors.lua")
      if not ok or not hyprColors then
          hyprColors = { active_border = "#89b4fa", inactive_border = "#45475a" }
      end

      hl.config({
          input = {
              kb_layout = "us",
              follow_mouse = 1,
              -- libinput's default "adaptive" accel profile scales the
              -- speed curve nonlinearly with how fast you move the mouse —
              -- feels fine for slow movements but fast flicks jump
              -- disproportionately. "flat" removes that curve entirely:
              -- output speed is a straight 1:1 multiple of `sensitivity`,
              -- consistent regardless of movement speed.
              accel_profile = "flat",
              sensitivity = -0.3,
          },

          general = {
              gaps_in = 4,
              gaps_out = 8,
              border_size = 2,
              layout = "dwindle",
              col = {
                  active_border   = "rgb(" .. hyprColors.active_border:gsub("#", "") .. ")",
                  inactive_border = "rgb(" .. hyprColors.inactive_border:gsub("#", "") .. ")",
              },
          },
      })

      -- Launch the wallpaper daemon, bar, and notification daemon once at
      -- compositor start (not on every config reload). `awww restore`
      -- reapplies whatever wallpaper was last set, so a config reload/logout
      -- doesn't reset it to nothing. (nixpkgs renamed the `swww` package to
      -- `awww` upstream — same CLI subcommands, just the `awww`/
      -- `awww-daemon` binary names.)
      hl.on("hyprland.start", function ()
          hl.exec_cmd("awww-daemon")
          hl.exec_cmd("sleep 0.5 && awww restore")
          hl.exec_cmd("waybar")
          hl.exec_cmd("mako")
          -- Belt-and-suspenders alongside home.pointerCursor in gtk-qt.nix:
          -- `hyprctl setcursor` tells the compositor itself directly,
          -- independent of whether XCURSOR_THEME/XCURSOR_SIZE made it into
          -- this session's environment in time.
          hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 24")
      end)

      -- Named curves must be declared before hl.animation() can reference them.
      hl.curve("linear",       { type = "bezier", points = { {0, 0}, {1, 1} } })
      hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
      hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

      -- Speed up window open/close and workspace-switch animations (speed is
      -- in ds, 1ds = 100ms); values below are roughly half Hyprland's defaults.
      hl.animation({ leaf = "windows",      enabled = true, speed = 2.5, spring = "easy" })
      hl.animation({ leaf = "windowsIn",    enabled = true, speed = 2,   spring = "easy", style = "popin 87%" })
      hl.animation({ leaf = "windowsOut",   enabled = true, speed = 1,   bezier = "linear", style = "popin 87%" })
      hl.animation({ leaf = "fadeIn",       enabled = true, speed = 1,   bezier = "almostLinear" })
      hl.animation({ leaf = "fadeOut",      enabled = true, speed = 1,   bezier = "almostLinear" })
      hl.animation({ leaf = "workspaces",   enabled = true, speed = 1,   bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesIn", enabled = true, speed = 0.6, bezier = "almostLinear", style = "fade" })
      hl.animation({ leaf = "workspacesOut",enabled = true, speed = 1,   bezier = "almostLinear", style = "fade" })

      local mainMod = "SUPER"

      hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
      hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
      hl.bind(mainMod .. " + M",      hl.dsp.exit())
      hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd("wofi --show drun"))
      hl.bind(mainMod .. " + W",      hl.dsp.exec_cmd("wallpaper-select"))
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
