{ pkgs, src }:

with pkgs;
let
  libwebsockets_janus = libwebsockets.overrideAttrs (_: {
    configureFlags = [
      "-DLWS_MAX_SMP=1"
      "-DLWS_WITHOUT_EXTENSIONS=0"
    ];
  });
in
stdenv.mkDerivation {
  inherit src;

  name = "janus";

  preferLocalBuild = true;

  nativeBuildInputs = [ autoreconfHook pkg-config gengetopt ];
  buildInputs = [
    openssl
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
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ Security ]);

  enableParallelBuilding = true;

  configureFlags = [
    "--disable-all-handlers"
    "--disable-all-loggers"
    "--disable-all-plugins"
    "--disable-all-transports"
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
