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
      # offer flake contents to all Systems that are theoretically supported by nix
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system:
          # pass system string, because pkgs.stdenv.hostPlatform.system is awkward to use
          f system (
            import nixpkgs {
              inherit system;
              # Overlay Pandoc with newer version until its upstreamed in nixpkgs
              overlays = [
                (final: prev: {
                  # HACK: The build needs pandoc-cli, pandoc-cli_3_8 needs the override as well
                  pandoc = prev.haskellPackages.pandoc-cli_3_8.override {
                    pandoc = (
                      prev.haskellPackages.pandoc_3_8.override {
                        citeproc = prev.haskellPackages.citeproc_0_10;
                        texmath = prev.haskellPackages.texmath_0_13;
                      }
                    );
                  };
                })
              ];
            }
          )
        );
    in
    {
      packages = forAllSystems (
        system: pkgs: rec {
          default = ganeti;
          # needed for the build until default pandoc version is 3.8
          ganeti = pkgs.callPackage (import ./nix/package.nix) { test = true; };
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
            buildInputs = (
              self.packages.${system}.ganeti.nativeBuildInputs ++ self.packages.${system}.ganeti.buildInputs
            );
          };
        }
      );

      # formatter for nix code
      formatter = forAllSystems (_: pkgs: pkgs.nixfmt-rfc-style);
    };
}
