{ pkgs, src }:

with pkgs;
let
  libwebsockets_janus = libwebsockets.overrideAttrs (_: {
    configureFlags = [
      "-DLWS_MAX_SMP=1"
      "-DLWS_WITHOUT_EXTENSIONS=0"
    ];
  });
in gcc11Stdenv.mkDerivation {
  inherit src;

  name = "janus";

  CFLAGS = "-O3 -march=westmere -mtune=haswell -funroll-loops -fomit-frame-pointer -flto";

  preferLocalBuild = true;

  nativeBuildInputs = [ autoreconfHook pkg-config gengetopt ];
  buildInputs = [
    boringssl
    curl
    ffmpeg
    glib
    jansson
    libconfig
    libmicrohttpd
    libnice
    libogg
    libopus
    libuv
    libwebsockets_janus
    sofia_sip
    srtp
    usrsctp
    zlib
  ];

  enableParallelBuilding = true;

  patches = [
    ./patches/janus_wsevh.patch
  ];

  configureFlags = [
      "--disable-all-handlers"
      "--disable-all-loggers"
      "--disable-all-plugins"
      "--disable-all-transports"
      "--enable-boringssl=${boringssl}"
      "--enable-fast-install"
      "--enable-libsrtp2"
      "--enable-plugin-videocall"
      "--enable-plugin-videoroom"
      "--enable-post-processing"
      "--enable-rest"
      "--enable-static"
      "--enable-websockets-event-handler"
      "--enable-websockets"
  ];
}
