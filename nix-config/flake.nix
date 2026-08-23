{
  description = "my personal nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hy3.url = "github:outfoxxed/hy3?ref=hl0.47.0";

    omp.url = "github:can1357/oh-my-pi";
  };

  outputs =
    { nixpkgs, nixpkgs-unstable, home-manager, impermanence, stylix
    , anyrun, nixcord, hy3, omp, ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "gio";
      terminal = "kitty";

      pkgs = import nixpkgs { inherit system; };

      extraSpecialArgs = {
        inherit username terminal;

        assets = import ./assets;

        inputs = {
          inherit anyrun hy3 impermanence nixcord omp stylix;
        };

        helium = pkgs.callPackage ./pkgs/helium.nix { };

        serenity-emoji = pkgs.callPackage ./pkgs/serenity-emoji { };

        pi = pkgs.callPackage ./pkgs/pi.nix { };
      };

      overlays = [
        (final: _: {
          inputs = builtins.mapAttrs (_: flake: let
            legacyPackages = (flake.legacyPackages or { }).${final.system} or { };
            packages = (flake.packages or { }).${final.system} or { };
          in
            if legacyPackages != { }
            then legacyPackages
            else packages
          ) inputs;
        })

        (final: prev: {
          hy3 = final.callPackage "${inputs.hy3}/default.nix" {
            hyprland = final.hyprland;
            hlversion = final.hyprland.version;
            keepDebugInfo = final.stdenvAdapters.keepDebugInfo;
          };

          Hyprspace = final.callPackage ./pkgs/hyprspace.nix {
            hyprland = final.hyprland;
          };

          swaylock = prev.swaylock.overrideAttrs (old: {
            version = "1.8.6";

            src = final.fetchFromGitHub {
              owner = "swaywm";
              repo = "swaylock";
              rev = "v1.8.6";
              hash = "sha256-AkH3i9egklFm8z+0M46jFx9VubGWsRGwN1eLkrwkgfs=";
            };
          });

          neovim-unwrapped =
            nixpkgs-unstable.legacyPackages.${final.system}.neovim-unwrapped;

          zed-editor =
            nixpkgs-unstable.legacyPackages.${final.system}.zed-editor;

          opencode =
            nixpkgs-unstable.legacyPackages.${final.system}.opencode;

          omp = (inputs.omp.packages.${final.system}.omp).overrideAttrs (old: {
            # installCheck fails: bun "CurrentWorkingDirectoryUnlinked" when
            # creating a Transpiler with an unlinked CWD in the nix sandbox.
            doInstallCheck = false;
          });

          fastfetch =
            nixpkgs-unstable.legacyPackages.${final.system}.fastfetch;
        })
      ];
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = extraSpecialArgs;

        modules = [
          ./hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          stylix.nixosModules.stylix
          {
            nixpkgs.overlays = overlays;

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";

              extraSpecialArgs = extraSpecialArgs;

              users.gio = import ./home/gio.nix;
            };
          }
        ];
      };
    };
}
