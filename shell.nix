{ pkgs, janus }:

with pkgs;

let
  py = python38Packages;
  pylibsrtp = with py; buildPythonPackage rec {
    pname = "pylibsrtp";
    version = "0.6.8";

    src = fetchPypi {
      inherit pname version;
      sha256 = "F1FseG1I7lCqFsr33cOuIO8quS2eqyGOF+/smeWj0b0=";
    };

    propagatedBuildInputs = [ cffi srtp ];
    doCheck = false;
  };
  crc32c = with py; buildPythonPackage rec {
    pname = "crc32c";
    version = "2.2";

    src = fetchPypi {
      inherit pname version;
      sha256 = "JkP2Pck1Jg8BeIkBCZjKy306U1tAFk1oikKElDliibg=";
    };
    doCheck = false;
  };
  aioice = with py; buildPythonPackage rec {
    pname = "aioice";
    version = "0.7.5";

    src = fetchPypi {
      inherit pname version;
      sha256 = "BLYiti7sybXBauUEDSNrXzRCJyjqXqb1VQv997D/728=";
    };

    propagatedBuildInputs = [ netifaces dnspython ];
    doCheck = false;
  };
  aiortc = with py; buildPythonPackage rec {
    pname = "aiortc";
    version = "1.2.0";

    src = fetchPypi {
      inherit pname version;
      sha256 = "SCVMKxzxiZSRX2Gnv+n2MZePSp+553D9Rq0YtOVlzCY=";
    };

    propagatedBuildInputs = [ aioice av cffi crc32c libopus libvpx pylibsrtp pyee cryptography ];
    doCheck = false;
  };
in
mkShell {
  name = "janus-env";
  buildInputs = [ janus python3Minimal /*aiortc py.websockets*/ ] ++ [
    ffmpeg
    gengetopt
    glib
    jansson
    libconfig
    libnice
    libogg
    libopus
    openssl
    srtp
    zlib
  ];
  nativeBuildInputs = [ cmake automake autoreconfHook pkg-config libtool ];
}
