# Structural layout/modules are Nix-managed; colors are not. `style` below
# @imports a generated stylesheet from outside the Nix store (see
# wallust.nix), so a wallpaper change re-colors the bar without a rebuild.
# Launched via the hyprland.start autostart block in hyprland.nix, not
# home-manager's own systemd service, to keep startup in one place.
{ config, ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      spacing = 4;

      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        on-click = "activate";
      };

      "clock" = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      "cpu" = {
        format = "  {usage}%";
        interval = 5;
      };

      "memory" = {
        format = "  {}%";
        interval = 5;
      };

      "network" = {
        format-wifi = "  {essid}";
        format-ethernet = "󰈀  Connected";
        format-disconnected = "󰖪  Offline";
      };

      "pulseaudio" = {
        format = "{icon}  {volume}%";
        format-muted = "󰝟  Muted";
        format-icons = {
          default = [ "" "" "" ];
        };
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      "tray" = {
        spacing = 8;
      };
    };

    style = ''
      @import url("file://${config.home.homeDirectory}/.cache/wallust/waybar-colors.css");

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 12px;
      }

      window#waybar {
        background-color: @background;
        color: @foreground;
      }

      #workspaces button {
        padding: 0 6px;
        color: @foreground;
        background: transparent;
      }

      #workspaces button.active {
        color: @background;
        background: @color4;
        border-radius: 6px;
      }

      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 8px;
        color: @foreground;
      }

      #window {
        color: @color4;
      }
    '';
  };
}
