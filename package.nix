{ lib
, pkgs
, stdenv
, fetchFromGitHub
, fetchpatch
, git
, bash
, coreutils-prefixed
, autoconf
, automake
, m4
, iproute2
, socat
, ghc
, cabal-install
, pkg-config
, curl
, haskellPackages
, python311	# Python 3.12 removed package asyncore
, pcre
, zlib
, pandoc
, graphviz
, qemu
, test ? true
}:

let
# ghc = haskell.compiler.ghc902;
# myGhc = ghc.ghcWithPackages (hspkgs: with hspkgs; [
# myGhc = haskellPackages.ghcWithPackages (hpkgs: with hpkgs; [
# myGhc = haskell.compiler.ghc948.ghcWithPackages (hpkgs: with hpkgs; [
myGhc = ghc.withPackages (hspkgs: with hspkgs; [
  hspkgs.curl hspkgs.zlib
  json network base64-bytestring utf8-string hslogger
  attoparsec vector hinotify cryptonite
  lifted-base lens regex-pcre old-time temporary
  case-insensitive
#  snap-server PSQueue
#  hspkgs.Cabal
#  cabal-install # you must not use global cabal-install, since it will not match Cabal the library
]
++
lib.optionals test [
  HUnit
  test-framework
  test-framework-hunit
  test-framework-quickcheck2
]
); # .override {ghc = haskell.compiler.ghc902;};

myPython = python311.withPackages (pypkgs: with pypkgs; [
  pyopenssl
  simplejson
  pyparsing
  pyinotify
  pycurl
  bitarray
  psutil
  paramiko
  # for documentation
  pypkgs.docutils
  sphinx
#  (builtins.trace 
#     (builtins.attrNames pypkgs) sphinx)
#  (pypkgs.callPackage (import ./empty.nix pypkgs) {})
#  (pypkgs.callPackage (import nix/empty.nix pypkgs) {})
#  (pypkgs.callPackage nix/empty.nix {})
#  pydoctor
#  (pypkgs.callPackage (import ./nix/pydoctor.nix pypkgs) {})
#  (pypkgs.callPackage ./pydoctor.nix {})
#  (pkgs.callPackage ./nix/pydoctor.nix {})
#  (pkgs.python311Packages.callPackage ./pydoctor.nix { inherit pypkgs; })
#  (pypkgs.callPackage (import nix/pydoctor.nix) {})
  (import ./nix/pydoctor.nix pypkgs)
#  (import ./pydoctor.nix pypkgs)
#  (import ./pydoctor.nix pkgs.python311Packages)
#  (pypkgs.callPackage ./pydoctor.nix {})
  # for tests
  pytest
  pyyaml
]);

/*
newHaskellPackages = pkgs.haskellPackages.override {
  overrides = self: super: {
    pandoc = self.callHackage "pandoc" "3.7" {};
    pandoc-cli = self.callHackage "pandoc-cli" "3.7" {};
  };
};
*/

pandocSrc = pkgs.fetchurl {
  url = "https://hackage.haskell.org/package/pandoc-3.8.2.1/pandoc-3.8.2.1.tar.gz";
  sha256 = "sha256-zsKGUy0i2Ft2y+i0SLUfn+LYFb3C8R/fjXmN0tLTje0=";
};

newHaskellPkgs = pkgs.haskellPackages.override {
  overrides = self: super: {
    pandoc = self.callCabal2nix "pandoc" pandocSrc {};
  };
};

in
stdenv.mkDerivation rec {
  pname = "ganeti";
  version = "3.0";

  src = ./.;

#  buildInputs = [ autoconf automake m4 python311 ];
  buildInputs = [
    autoconf automake cabal-install pkg-config m4 python311
    pandoc graphviz
    # newHaskellPackages.pandoc-cli
    # (self.callHackage "pandoc-cli" "3.7" {})
    # (haskellPackages.callHackage "pandoc-cli" "3.7.0.2" {})
    # (pkgs.haskellPackages.hackage2nix "pandoc" "3.8.2.1") # proposed by Claude Haiku
    # (pkgs.haskellPackages.callCabal2nix "pandoc" pandocSrc {})
    # pkgs.nix-prefetch-scripts
    # newHaskellPkgs.pandoc
    git
    # for the tests in checkPhase
    haskellPackages.shelltestrunner
    qemu
  ];
  nativeBuildInputs =
    [ iproute2 socat (lib.getDev curl) myGhc myPython ]
    ++  [ pcre zlib ];
#  buildInputs = [ autoconf automake m4 haskellPackages.cabal-install python311 ];
#  nativeBuildInputs = [ iproute2 socat myGhc myPython pcre zlib ];

#  CFLAGS = "-I${lib.getDev curl}/include";
  LD_LIBRARY_PATH="${pcre}/lib:${zlib}/lib";

#  DESTDIR = out;
#  DESTDIR = "${out}";

/*
  checkInputs =
    [yaml pytest];
*/

/*
If you run the build full automatically,
it will fail because of missing curl.h.

Or it will fail this way:

       > /build/source/cabal/CabalDependenciesMacros.hs:35:1: error:
       >     Ambiguous module name `Distribution.Verbosity':
       >       it was found in multiple packages: Cabal-3.10.3.0 Cabal-3.10.3.0


If you enter the build environment and do manually:

~~~~
unpackPhase
cd source
./autogen.sh
./configure
make
~~~~

then it will build.
Reason?
*/

  patches = [
/*
    ./nix-weinelt/disable-test-resetenv.patch
*/
    (fetchpatch {
      url = "https://git.savannah.gnu.org/cgit/guix.git/plain/gnu/packages/patches/ganeti-disable-version-symlinks.patch";
      sha256 = "0gs8s01wz8zl26gpgachr9plrxlfhc0rr6yli0cgqqkqv9cad7d4";
    })
#    ./nix-weinelt/disable-tests.patch
  ];

/*
  postPatch = ''
    patchShebangs autotools/ daemons/ lib/ tools/ qa/ test/py
  '';
*/
  postPatch = ''
    find . -type f | xargs sed -i 's,/bin/bash,${bash}/bin/bash,g'
    find . -type f | xargs sed -i 's,/usr/bin/env,${coreutils-prefixed}/bin/env,g'
    find . -type f | xargs sed -i 's,/bin/true,${coreutils-prefixed}/bin/true,g'
    find . -type f | xargs sed -i 's,/bin/ls,${coreutils-prefixed}/bin/ls,g'
    patchShebangs .
    substituteInPlace Makefile.am \
      --replace "\$(DESTDIR)\''${localstatedir}" "\$(DESTDIR)\''${prefix}\''${localstatedir}"
    echo "${version}" > ./vcs-version
  '';


  preConfigure = "./autogen.sh";


/*
  patchPhase = ''
    aclocal
    automake --add-missing
    autoreconf
  '';
*/

/*
If 'make' yells because of missing vcs.version -
I think the script must retrieve the version from somewhere
and Nix strips the .git directory.
And you don't have version information elsewhere
because you are not in a release tarball.
So, when running manually,
copy a genati/.git directory over to the source directory.
*/

  meta = with lib; {
    description = "Ganeti";
    homepage = "https://ganeti.org/";
    license = licenses.bsd2;
    maintainers = with maintainers; [ thielema ];
    mainProgram = "ganeti";
    platforms = platforms.unix;
  };
}
