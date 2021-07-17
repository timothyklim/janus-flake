{ pkgs, src }:

with pkgs; gcc11Stdenv.mkDerivation {
  inherit src;

  name = "janus";

  CFLAGS = "-O3 -march=native -mtune=native -funroll-loops -fomit-frame-pointer -flto";

  preferLocalBuild = true;

  nativeBuildInputs = [ cmake automake autoreconfHook pkg-config libtool ];
  buildInputs = [
    curl
    ffmpeg
    gengetopt
    glib
    jansson
    libconfig
    libnice
    libogg
    libopus
    libuv
    libwebsockets
    openssl
    srtp
    zlib
  ];

  configurePhase = ''
    sh autogen.sh

    ./configure --prefix=$out \
      --disable-all-transports \
      --disable-all-plugins \
      --disable-all-handlers \
      --disable-all-loggers \
      --enable-fast-install \
      --enable-static \
      --enable-libsrtp2 \
      --enable-post-processing \
      --enable-websockets \
      --enable-plugin-videocall
  '';
}
