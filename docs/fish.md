# fish + starship

Source: `home/programs/fish.nix`.

## fish

```nix
programs.fish = {
  enable = true;
  interactiveShellInit = ''
    set fish_greeting
  '';
  shellAliases = {
    ll = "ls -la";
    gs = "git status";
    nrs = "sudo nixos-rebuild switch --flake ~/nixos-qshell#nixos";
    hms = "home-manager switch --flake ~/nixos-qshell#nixos";
  };
};
```

- `set fish_greeting` (no value) disables fish's default startup greeting.
- **`nrs`** is the actual day-to-day rebuild command for this setup — see
  [flake.md](flake.md) for why (home-manager is wired in as a NixOS module,
  not run standalone, so there's no separate home-manager activation step).
- **`hms`** is present as a convenience alias but only works if a standalone
  `home-manager` CLI binary is separately installed on the system — it
  is *not*, by default, here. If `hms` fails with "command not found," that's
  expected; use `nrs` instead.

fish must also be enabled at the *system* level
(`programs.fish.enable = true` in `hosts/nixos/configuration.nix` — see
[system.md](system.md)) for it to be usable as the user's login shell
(`users.users.harshvse.shell = pkgs.fish`); enabling it only here in
home-manager would not be sufficient on its own.

## starship prompt

```nix
programs.starship = {
  enable = true;
  enableFishIntegration = true;
};
```

No custom `settings` — runs starship's own defaults. Deliberately **not**
wired into the wallust theming system (see [theming.md](theming.md)):
starship's default modules already reference terminal ANSI color names
rather than fixed hex values, so it automatically re-themes for free
whenever kitty's ANSI palette changes (see [kitty.md](kitty.md)) — no
wallust template needed for it, and none was built.
