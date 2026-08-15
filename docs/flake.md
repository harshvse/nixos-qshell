# Flake structure

Source: `flake.nix`.

## Inputs

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  nixos-hardware.url = "github:NixOS/nixos-hardware/master";
};
```

- **nixpkgs**: tracks `nixos-unstable` deliberately, not a stable release
  branch — chosen to get recent Hyprland releases quickly. The tradeoff is
  more frequent breakage/renames (see [theming.md](theming.md)'s note on the
  `swww` → `awww` package rename, discovered while building this config).
- **home-manager**: `inputs.nixpkgs.follows = "nixpkgs"` pins it to the same
  nixpkgs revision as the system, avoiding a second copy of nixpkgs being
  fetched/evaluated and avoiding version-skew bugs between the two.
- **nixos-hardware**: community hardware quirk-fix modules, referenced but
  not currently used (see `hosts/nixos/configuration.nix`'s commented-out
  import).

## Outputs

```nix
outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }@inputs:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nixos/configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.harshvse = import ./home/home.nix;
        }
      ];
    };
  };
```

Key structural decisions:

- **Single host today, multi-host-ready layout**: `hosts/<name>/` is the
  pattern — a second machine is a new folder under `hosts/` plus one more
  `nixosConfigurations.<name>` entry here, no restructuring needed.
- **home-manager wired as a NixOS module**, not run standalone. This means:
  - There is no separate `home-manager switch` step — `sudo nixos-rebuild
    switch --flake .#nixos` rebuilds the system *and* the user environment
    in one shot.
  - The `hms` alias in `home/programs/fish.nix` (`home-manager switch
    --flake ~/nixos-qshell#nixos`) only works if a standalone `home-manager`
    CLI is separately installed — it is not, by default, in this setup. The
    working command is the `nrs` alias (`sudo nixos-rebuild switch --flake
    ~/nixos-qshell#nixos`).
- **`useGlobalPkgs = true` / `useUserPackages = true`**: home-manager reuses
  the system's already-evaluated `pkgs` instead of instantiating its own,
  and packages home-manager installs go through the Nix store the normal
  way (not a separate home-manager-only package set).
- **`extraSpecialArgs = { inherit inputs; }`**: makes the `inputs` flake
  input set available as a module argument inside `home/home.nix` and
  everything it imports, e.g. for referencing `inputs.nixos-hardware` from
  home-manager modules if ever needed.

## Building without switching

`nixos-rebuild build --flake .#nixos` builds the full system closure without
activating it — useful for catching Nix evaluation errors (missing options,
typos, bad module references) before committing to `nixos-rebuild switch`.
This was used repeatedly while building the theming system in
[theming.md](theming.md) to verify each phase before moving to the next.

One gotcha: flakes only see **git-tracked** files. A new file created on
disk but not yet `git add`ed is invisible to `nix build`/`nixos-rebuild` and
produces a "Path ... is not tracked by Git" error — stage it (`git add`,
no commit needed) before building.
