{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.janus;

  stunConf = stun: optionalString (stun != null) ''
    stun_server = "${stun.server}"
    stun_port = ${toString stun.port}
  '';

  turnConf = turn: optionalString (turn != null) ''
    turn_server = "${turn.server}"
    turn_port = ${toString turn.port}
    turn_type = "${turn.type}"
    turn_user = "${turn.user}"
    turn_pwd = "${turn.password}"
  '';

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
      ${stunConf cfg.stun}
      ${turnConf cfg.turn}
    }
    events: {
      broadcast = true
    }
  '';
  videocallConf = pkgs.writeText "janus.plugin.videocall.jcfg" ''
    general: {
      events = true
    }
  '';
  websocketsConf = pkgs.writeText "janus.transport.websockets.jcfg" ''
    general: {
      events = true
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
  janusDir = pkgs.runCommand "janus-conf"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
    mkdir -p $out
    cp ${janusConf} $out/janus.jcfg
    cp ${videocallConf} $out/janus.plugin.videocall.jcfg
    cp ${websocketsConf} $out/janus.transport.websockets.jcfg
  '';
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

      transport.ws = {
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

      stun = {
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

      turn = {
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
        "d '${cfg.persistedDir}' 0755 janus janus - -"
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
