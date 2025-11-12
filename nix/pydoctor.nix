{
  pypkgs,
  ...
}:

let
  pname = "pydoctor";
  version = "25.4.0";
  sha256 = "sha256-xGBBOjHYMQNIH+YUec9tqJZpTJtiWCQxVKvQHk7uFL8=";

in
pypkgs.buildPythonPackage {
  pname = pname;
  version = version;

  src = pypkgs.fetchPypi {
    pname = pname;
    version = version;
    sha256 = sha256;
  };

  propagatedBuildInputs = with pypkgs; [
    toml
    configargparse
    docutils
    attrs
    requests
    twisted
    cachecontrol
    appdirs
    filelock
    pytest
    distutils
    (pkgs.callPackage (import ./lunr.nix) { pypkgs = pypkgs; })
    platformdirs
  ];

  # buildInputs = with pypkgs; [
  #   pip
  # ];

  doCheck = false;

  # https://wiki.nixos.org/wiki/Python
  pyproject = true;
  build-system = [
    pypkgs.setuptools
    pypkgs.wheel
  ];
}
