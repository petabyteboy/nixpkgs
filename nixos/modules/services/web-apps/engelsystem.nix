{ config, lib, pkgs, utils, ... }:

let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types literalExample;

  cfg = config.services.engelsystem;
  fpm = config.services.phpfpm.pools.engelsystem;

  genConfigScript = pkgs.writeScript "engelsystem-gen-config.sh" (utils.genJqSecretsReplacementSnippet cfg.config "config.json");
in {
  options = {
    services.engelsystem = {
      enable = mkEnableOption "Online tool for coordinating helpers and shifts on large events";

      domain = mkOption {
        type = types.str;
        example = "engelsystem.example.com";
        description = "domain to serve on";
      };

      package = mkOption {
        type = types.package;
        example = literalExample "pkgs.engelsystem";
        description = "Engelsystem package used for the service";
        default = pkgs.engelsystem;
      };
    };

    services.engelsystem.config = mkOption {
      type = types.attrs;
      default = {};
      description = "sendmail command to use";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."engelsystem/config.php".source = pkgs.writeText "config.php" ''
      <?php
      return json_decode(file_get_contents("/var/lib/engelsystem/config.json"), true);
    '';

    services.phpfpm.pools.engelsystem = {
      user = "engelsystem";
      settings = {
        "listen.owner" = config.services.nginx.user;
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.max_requests" = 500;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 5;
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "catch_workers_output" = true;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}".locations = {
        "/" = {
          root = "${cfg.package}/share/engelsystem/public";
          extraConfig = ''
            index index.php;
            try_files $uri $uri/ /index.php?$args;
            autoindex off;
          '';
        };
        "~ \\.php$" = {
          root = "${cfg.package}/share/engelsystem/public";
          extraConfig = ''
  					fastcgi_pass unix:${config.services.phpfpm.pools.engelsystem.socket};
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include ${config.services.nginx.package}/conf/fastcgi_params;
            include ${config.services.nginx.package}/conf/fastcgi.conf;
          '';
        };
      };
    };

    systemd.services."engelsystem-init"= {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        umask 077
        mkdir -p /var/lib/engelsystem/storage/app
        mkdir -p /var/lib/engelsystem/storage/cache/views
        cd /var/lib/engelsystem
        ${genConfigScript}
        chmod 400 config.json
        chown -R engelsystem .
      '';
    };
    systemd.services."engelsystem-migrate"= {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "engelsystem";
        Group = "mysql";
      };
      script = ''
        ${cfg.package}/bin/migrate
      '';
      after = [ "engelsystem-init.service" "mysql.service" ];
    };
    systemd.services."phpfpm-engelsystem".after = [ "engelsystem-migrate" ];

    users.users.engelsystem = {
      isSystemUser = true;
      createHome = true;
      home = "/var/lib/engelsystem/storage";
      group = "engelsystem";
      extraGroups = [ "mysql" ];
    };
    users.groups.engelsystem = {};
  };
}
