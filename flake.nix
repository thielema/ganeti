{
  description = "Ganeti - A VM Cluster Software on top of Xen and KVM";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      config = { };

      # offer flake contents to all Systems that are theoretically supported by nix
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system:
          # pass system string, because pkgs.stdenv.hostPlatform.system is awkward to use
          f system (
            import nixpkgs {
              inherit system;
              inherit config;
            }
          )
        );
    in
    {
      packages = forAllSystems (
        system: pkgs: rec {
          default = ganeti;
          ganeti = pkgs.callPackage (import ./nix/package.nix) { test = false; };
        }
      );

      # allows one to run "nix run ganeti"
      apps = forAllSystems (
        system: pkgs: {
          ganeti = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/ganeti";
          };
        }
      );

      # expose all deps of the final build in the devShell
      devShells = forAllSystems (
        system: pkgs: {
          default = pkgs.mkShell {
            buildInputs = self.packages.${system}.ganeti.nativeBuildInputs;
          };
        }
      );

      # formatter for nix code
      formatter = forAllSystems (_: pkgs: pkgs.nixfmt-rfc-style);
    };
}
