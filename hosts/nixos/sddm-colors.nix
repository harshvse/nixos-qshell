# Color overrides for the sddm-astronaut greeter theme, keyed exactly like
# the [General] section of the theme's own Themes/<preset>.conf. Merged into
# `themeConfig` in configuration.nix, which nixpkgs's sddm-astronaut package
# renders into a `.conf.user` file baked into the Nix store at build time —
# SDDM can't read ~/.cache/wallust live the way everything else in this repo
# does, so this file only updates by hand.
#
# This is a placeholder palette (not yet synced from an actual wallpaper).
# After picking a wallpaper you like, run `sddm-theme-sync` (home/programs/
# wallust.nix) to overwrite this file from the current wallust palette, then
# `nrs` to bake it into the greeter. See docs/theming.md.
{
  HeaderTextColor = "#cdd6f4";
  DateTextColor = "#cdd6f4";
  TimeTextColor = "#cdd6f4";

  FormBackgroundColor = "#1e1e2e";
  BackgroundColor = "#1e1e2e";
  DimBackgroundColor = "#1e1e2e";

  LoginFieldBackgroundColor = "#45475a";
  PasswordFieldBackgroundColor = "#45475a";
  LoginFieldTextColor = "#cdd6f4";
  PasswordFieldTextColor = "#cdd6f4";
  UserIconColor = "#cdd6f4";
  PasswordIconColor = "#cdd6f4";

  PlaceholderTextColor = "#585b70";
  WarningColor = "#f38ba8";

  LoginButtonTextColor = "#1e1e2e";
  LoginButtonBackgroundColor = "#89b4fa";
  SystemButtonsIconsColor = "#cdd6f4";
  SessionButtonTextColor = "#cdd6f4";
  VirtualKeyboardButtonTextColor = "#cdd6f4";

  DropdownTextColor = "#1e1e2e";
  DropdownSelectedBackgroundColor = "#89b4fa";
  DropdownBackgroundColor = "#45475a";

  HighlightTextColor = "#1e1e2e";
  HighlightBackgroundColor = "#89b4fa";
  HighlightBorderColor = "transparent";

  HoverUserIconColor = "#89b4fa";
  HoverPasswordIconColor = "#89b4fa";
  HoverSystemButtonsIconsColor = "#89b4fa";
  HoverSessionButtonTextColor = "#89b4fa";
  HoverVirtualKeyboardButtonTextColor = "#89b4fa";
}
