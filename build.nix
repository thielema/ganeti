let
#  pkgs = import <nixpkgs> {};
  pkgs = import <unstable> {};
  ganeti = pkgs.callPackage (import ./package.nix) {};
in
pkgs.mkShell {
  buildInputs = (with pkgs; [
    ganeti
  ]);
}
