{
  lib,
  buildPythonPackage,
  fetchPypi,
  callPackage,
  setuptools,
  wheel,

  toml,
  configargparse,
  docutils,
  attrs,
  requests,
  twisted,
  cachecontrol,
  appdirs,
  filelock,
  pytest,
  distutils,
  platformdirs,
}:

let
  pname = "pydoctor";
  version = "25.4.0";
  sha256 = "sha256-xGBBOjHYMQNIH+YUec9tqJZpTJtiWCQxVKvQHk7uFL8=";

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
    (callPackage ./lunr.nix {})
    platformdirs
  ];

  doCheck = false;

  pyproject = true;
  build-system = [
    setuptools
    wheel
  ];
}
