{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.janus;

  janusConf = pkgs.writeText "janus.jcfg" ''
    general: {
      log_to_stdout = true
      debug_level = ${toString cfg.debug_level}
      debug_colors = true
      token_auth = false
      interface = "${cfg.interface}"
      session_timeout = 600
      candidates_timeout = 450
      protected_folders = []
    }
    certificates: {
      dtls_accept_selfsigned = true
    }
    media: {
      rtp_port_range = "${toString cfg.media.rtp_min_port}-${toString cfg.media.rtp_max_port}"
      nack_optimizations = true
    }
    nat: {
      ${(stun: optionalString (stun != null) ''
        stun_server = "${stun.server}"
        stun_port = ${toString stun.port}
      '') cfg.stun}
      ${(turn: optionalString (turn != null) ''
        turn_server = "${turn.server}"
        turn_port = ${toString turn.port}
        turn_type = "${turn.type}"
        turn_user = "${turn.user}"
        turn_pwd = "${turn.password}"
      '') cfg.turn}
      ${optionalString (cfg.ice_enforce_list != []) ''ice_enforce_list = "${concatStringsSep "," cfg.ice_enforce_list}"''}
    }
    events: {
      broadcast = ${boolToString cfg.events.broadcast}
    }
  '';
  videocallConf = pkgs.writeText "janus.plugin.videocall.jcfg" ''
    general: {
      events = ${boolToString cfg.videocall.events}
    }
  '';
  websocketsConf = pkgs.writeText "janus.transport.websockets.jcfg" ''
    general: {
      events = ${boolToString cfg.transport.ws.events}
      json = "compact"
      ws = true
      ws_port = ${toString cfg.transport.ws.port}
      ws_ip = "${cfg.transport.ws.interface}"
      ws_logging = "err,warn"
      wss = false
    }
    admin: {
      admin_ws = false
    }
  '';
  wsevhConf = pkgs.writeText "janus.eventhandler.wsevh.jcfg" ''
    general: {
      enabled = ${boolToString cfg.events-handler.ws.enabled}
      events = "${concatStringsSep "," cfg.events-handler.ws.events}"
      grouping = ${boolToString cfg.events-handler.ws.grouping}
      json = "compact"
      backend = "${cfg.events-handler.ws.backend}"
      ws_logging = "err,warn"
    }
  '';
  janusDir = pkgs.runCommand "janus-conf"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
    mkdir -p $out
    cp ${janusConf} $out/janus.jcfg
    cp ${videocallConf} $out/janus.plugin.videocall.jcfg
    cp ${websocketsConf} $out/janus.transport.websockets.jcfg
    cp ${wsevhConf} $out/janus.eventhandler.wsevh.jcfg
  '';

  stunOptions = {
    server = mkOption {
      type = types.str;
      description = ''
        STUN server
      '';
    };
    port = mkOption {
      type = types.port;
      description = ''
        STUN port
      '';
    };
  };

  turnOptions = {
    server = mkOption {
      type = types.str;
      description = ''
        TURN server
      '';
    };
    port = mkOption {
      type = types.port;
      description = ''
        TURN port
      '';
    };
    user = mkOption {
      type = types.str;
      description = ''
        TURN server user
      '';
    };
    password = mkOption {
      type = types.str;
      description = ''
        TURN server password
      '';
    };
    type = mkOption {
      type = types.enum [ "udp" " tcp" "tls" ];
      description = ''
        TURN server type
      '';
    };
  };
in
{
  options = {
    services.janus = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      package = mkOption {
        type = types.package;
        description = ''
          Janus package.
        '';
      };

      interface = mkOption {
        example = "127.0.0.1";
        type = types.str;
      };

      persistedDir = mkOption {
        type = types.str;
        default = "/tmp/janus";
      };

      debug_level = mkOption {
        type = types.ints.between 0 7;
        default = 0;
      };

      events.broadcast = mkOption {
        type = types.bool;
        default = true;
      };

      videocall.events = mkOption {
        type = types.bool;
        default = true;
      };

      transport.ws = {
        events = mkOption {
          type = types.bool;
          default = true;
        };
        interface = mkOption {
          default = "127.0.0.1";
          type = types.str;
        };
        port = mkOption {
          type = types.port;
          default = 8188;
          description = ''
            WebSocket transport port
          '';
        };
      };

      events-handler.ws = {
        enabled = mkOption {
          type = types.bool;
          default = true;
        };
        events = mkOption {
          type = types.listOf (types.enum [ "none" "sessions" "handles" "jsep" "webrtc" "media" "plugins" "transports" "core" "external" "all" ]);
          default = [ "all" ];
          description = ''
            List of the events mask you're interested in.
          '';
        };
        grouping = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether events should be sent individually (one per
            HTTP POST, JSON object), or if it's ok to group them
            (one or more per HTTP POST, JSON array with objects)
            The default is 'yes' to limit the number of connections.
          '';
        };
        backend = mkOption {
          type = types.str;
          example = "ws://127.0.0.1:8189";
        };
      };

      ice_enforce_list = mkOption {
        default = [ ];
        type = types.listOf types.str;
        description = ''
          Which interfaces should be explicitly used by the
          gateway for the purpose of ICE candidates gathering, thus excluding
          others that may be available
        '';
      };

      stun = mkOption {
        type = types.nullOr (types.submodule ({ ... }: { options = stunOptions; }));
        default = null;
      };

      turn = mkOption {
        type = types.nullOr (types.submodule ({ ... }: { options = turnOptions; }));
        default = null;
      };

      media = {
        rtp_min_port = mkOption {
          type = types.port;
          default = 20000;
          description = ''
            Lower bound of UDP relay endpoints
          '';
        };
        rtp_max_port = mkOption {
          type = types.port;
          default = 65535;
          description = ''
            Upper bound of UDP relay endpoints
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    users.users.janus = {
      isSystemUser = true;
      createHome = false;
      group = "janus";
      uid = 8771;
    };

    users.groups.janus.gid = 8771;

    systemd = {
      tmpfiles.rules = [
        "d '${cfg.persistedDir}' 0775 janus janus - -"
      ];
      services.janus = {
        description = "Janus gateway";

        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        wants = [ "network.target" ];

        path = [ cfg.package ];

        serviceConfig = {
          ExecStart = "${cfg.package}/bin/janus -F ${janusDir}";
          User = "janus";
          Group = "janus";
          WorkingDirectory = cfg.package;
          Type = "simple";
          NotifyAccess = "all";
          StandardOutput = "journal";
          StandardError = "journal";
          Restart = "always";
          RestartSec = 1;

          LimitNOFILE = mkDefault 1048576;

          ReadWriteDirectories = [ cfg.persistedDir ];

          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

          NoNewPrivileges = true;
          ProtectHome = "yes";
          ProtectSystem = "strict";
          ProtectProc = "invisible";
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          ProtectKernelModules = true;
          PrivateDevices = true;
          SystemCallArchitectures = "native";
        };
        unitConfig = {
          StartLimitIntervalSec = 3;
          StartLimitBurst = 0;
        };
      };
    };
  };
}
