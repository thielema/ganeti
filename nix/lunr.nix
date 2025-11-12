{ pypkgs, ... }:

let
  pname = "lunr";
  version = "0.6.2";
  sha256 = "sha256-eYPZZb17qnjL1PW5NPw+8xQsG2CJ32xv7NZt9b/yCSE=";

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
    pytest
    mock
  ];

  # https://wiki.nixos.org/wiki/Python
  pyproject = true;
  build-system = [
    pypkgs.setuptools
    pypkgs.wheel
  ];
}
