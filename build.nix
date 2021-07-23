{ pkgs, src }:

with pkgs; gcc11Stdenv.mkDerivation {
  inherit src;

  name = "janus";

  CFLAGS = "-O3 -march=westmere -mtune=haswell -funroll-loops -fomit-frame-pointer -flto";

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

  patches = [
    ./patches/janus_wsevh.patch
  ];

  configurePhase = ''
    sh autogen.sh

    ./configure --prefix=$out \
      --disable-all-transports \
      --disable-all-plugins \
      --disable-all-handlers \
      --disable-all-loggers \
      --enable-fast-install \
      --enable-libsrtp2 \
      --enable-plugin-videocall \
      --enable-post-processing \
      --enable-static \
      --enable-websockets \
      --enable-websockets-event-handler
  '';
}
