# btop's main config (theme name, layout) is structural and stays
# Nix-managed. The theme *file* it points at (~/.config/btop/themes/
# wallust.theme) is generated at runtime by wallust — see wallust.nix — and
# is deliberately not touched here.
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
