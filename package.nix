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
  haskellEnv = ghc.withPackages
    (hspkgs: with hspkgs; [
        hspkgs.curl hspkgs.zlib
        json network base64-bytestring utf8-string hslogger
        attoparsec vector hinotify cryptonite
        lifted-base lens regex-pcre old-time temporary
        case-insensitive
      ]
      ++
      lib.optionals test [
        HUnit
        test-framework
        test-framework-hunit
        test-framework-quickcheck2
      ]
    );

  pythonEnv = python311.withPackages
    (pypkgs: with pypkgs; [
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
        (pypkgs.callPackage nix/pydoctor.nix {})
      ]
      ++
      lib.optionals test [
        pytest
        pyyaml
      ]
    );

in
stdenv.mkDerivation rec {
  pname = "ganeti";
  version = "3.1";

  src = ./.;

  buildInputs = [
    autoconf automake cabal-install pkg-config m4 python311
    pandoc graphviz
    git
  ]
  ++
  lib.optionals test [
    haskellPackages.shelltestrunner
    qemu
  ];

  nativeBuildInputs =
    [ iproute2 socat (lib.getDev curl) haskellEnv pythonEnv ]
    ++  [ pcre zlib ];

  LD_LIBRARY_PATH="${pcre}/lib:${zlib}/lib";

  patches = [
    (fetchpatch {
      url = "https://git.savannah.gnu.org/cgit/guix.git/plain/gnu/packages/patches/ganeti-disable-version-symlinks.patch";
      sha256 = "0gs8s01wz8zl26gpgachr9plrxlfhc0rr6yli0cgqqkqv9cad7d4";
    })
  ];

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

  meta = with lib; {
    description = "Ganeti";
    homepage = "https://ganeti.org/";
    license = licenses.bsd2;
    maintainers = with maintainers; [ thielema ];
    mainProgram = "ganeti";
    platforms = platforms.unix;
  };
}
