{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  wheel,

  pytest,
  mock,
}:

let
  pname = "lunr";
  version = "0.6.2";
  sha256 = "sha256-eYPZZb17qnjL1PW5NPw+8xQsG2CJ32xv7NZt9b/yCSE=";

in
buildPythonPackage {
  pname = pname;
  version = version;

  src = fetchPypi {
    pname = pname;
    version = version;
    sha256 = sha256;
  };

  propagatedBuildInputs = [
    pytest
    mock
  ];

  pyproject = true;
  build-system = [
    setuptools
    wheel
  ];
}
