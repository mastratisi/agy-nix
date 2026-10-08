{
  description = "Nix package for Google's Antigravity CLI (agy), tracking upstream releases";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) f;
      overlay = final: prev: {
        antigravity-cli = final.callPackage ./package.nix { };
      };
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: (nixpkgs.lib.getName pkg) == "antigravity-cli";
        overlays = [ overlay ];
      };
    in
    {
      overlays.default = overlay;

      packages = eachSystem (system: rec {
        antigravity-cli = (pkgsFor system).antigravity-cli;
        default = antigravity-cli;
      });

      apps = eachSystem (system: rec {
        agy = {
          type = "app";
          program = "${(pkgsFor system).antigravity-cli}/bin/agy";
        };
        default = agy;
      });

      devShells = eachSystem (system: {
        default = (pkgsFor system).mkShell {
          packages = with (pkgsFor system); [ nixpkgs-fmt jq curl ];
        };
      });
    };
}
