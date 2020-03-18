{ config, lib, pkgs, ... }:

let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;

  cfg = config.services.engelsystem;
  fpm = config.services.phpfpm.pools.engelsystem;

  user = "engelsystem";
  package = pkgs.engelsystem;

  engelsystemConfig = pkgs.writeTextFile {
    name = "config.php";
    text = ''
      <?php
      return [
          'database'                => [
              'host'     => '${cfg.database.host}',
              'database' => '${cfg.database.database}',
              'username' => '${cfg.database.username}',
              'password' => ${if cfg.database.passwordFile != null then "file_get_contents('${cfg.database.passwordFile}')" else (if cfg.database.password != null then "'${cfg.database.password}'" else "''")},
          ],
          'api_key'                 => ${if cfg.apiKeyFile != null then "file_get_contents('${cfg.apiKeyFile}')" else (if cfg.apiKey != null then "'${cfg.apiKey}'" else "''")},
          'maintenance'             => ${if cfg.maintenance then "true" else "false"},
          'app_name'                => '${cfg.appName}',
          'environment'             => '${cfg.environment}',
          'header_items'            => [
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: link:
              "'${name}' => '${link}',") cfg.headerItems)}
          ],
          'footer_items'            => [
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: link:
              "'${name}' => '${link}',") cfg.footerItems)}
          ],
          'documentation_url'       => '${cfg.documantationUrl}',
          'email'                   => [
              'driver' => '${cfg.mail.driver}',
              'from'   => [
                  'address' => '${cfg.mail.from.address}',
                  'name'    => '${cfg.mail.from.name}',
              ],
              'host'       => '${cfg.mail.host}',
              'port'       => ${toString cfg.mail.port},
              'encryption' => ${if cfg.mail.encryption == null then "null" else "'${cfg.mail.encryption}'"},
              'username'   => '${cfg.mail.username}',
              'password'   => ${if cfg.mail.passwordFile != null then "file_get_contents('${cfg.mail.passwordFile}')" else (if cfg.mail.password != null then "'${cfg.mail.password}'" else "''")},
              'sendmail'   => '${cfg.mail.sendmail}',
          ],
          'theme'                   => ${toString cfg.theme},
          'available_themes'        => [
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (number: theme:
              "'${number}' => '${theme}',"
              ) cfg.availableThemes)}
          ],
          'rewrite_urls'            => ${if cfg.rewriteUrls then "true" else "false"},
          'home_site'               => '${cfg.homeSite}',
          'display_news'            => ${toString cfg.displayNews},
          'registration_enabled'    => ${if cfg.registration then "true" else "false"},
          'signup_requires_arrival' => ${if cfg.signupArrival then "true" else "false"},
          'autoarrive'              => ${if cfg.autoarrive then "true" else "false"},
          'signup_advance_hours'    => ${toString cfg.singupHours},
          'last_unsubscribe'        => ${toString cfg.lastUnsubscribe},
          'password_algorithm'      => ${if cfg.passwordAlgorithm == null then "PASSWORD_DEFAULT" else cfg.passwordAlgorithm},
          'min_password_length'     => ${toString cfg.minPasswordLength},
          'enable_dect'             => ${if cfg.dect then "true" else "false"},
          'enable_user_name'        => ${if cfg.userNames then "true" else "false"},
          'enable_pronoun'          => ${if cfg.pronoun then "true" else "false"},
          'enable_planned_arrival'  => ${if cfg.plannedArrival then "true" else "false"},
          'enable_tshirt_size'      => ${if cfg.tshirtSize then "true" else "false"},
          'max_freeloadable_shifts' => ${toString cfg.freeloadable},
          'timezone'                => '${cfg.timezone}',
          'night_shifts'            => [
              'enabled'    => ${if cfg.nightShifts.enable then "true" else "false"},
              'start'      => ${toString cfg.nightShifts.start},
              'end'        => ${toString cfg.nightShifts.end},
              'multiplier' => ${toString cfg.nightShifts.multiplier},
          ],
          'voucher_settings'        => [
              'initial_vouchers'   => ${toString cfg.voucher.initial},
              'shifts_per_voucher' => ${toString cfg.voucher.shifts},
              'hours_per_voucher'  => ${toString cfg.voucher.hours},
              'voucher_start'      => ${if cfg.voucher.start == null then "null" else "'${cfg.voucher.start}'"},
          ],
          'locales'                 => [
            'de_DE' => 'Deutsch',
            'en_US' => 'English',
          ],
          'default_locale'          => '${cfg.defaultLocale}',
          'tshirt_sizes'            => [
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (size: name:
            "'${size}' => '${name}',"
            ) cfg.availableTshirtSize)}
          ],
          'filter_max_duration' => ${toString cfg.filterMaxDuration},
          'session'                 => [
              'driver' => '${cfg.session.driver}',
              'name'   => '${cfg.session.name}',
          ],
          'trusted_proxies'         => '${cfg.trustedProxies}',
          'add_headers'             => ${if cfg.addHeaders then "true" else "false"},
          'headers'                 => [
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (header: value:
            "'${header}' => '${value}',"
            ) cfg.headers)}
          ],
          'credits'                 => [
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
            "'${name}' => '${value}',"
            ) cfg.credits)}
          ]
      ];
    '';
    checkPhase = "${pkgs.php}/bin/php -l $out";
  };
in {
  options = {
    services.engelsystem = {
      enable = mkEnableOption "Online tool for coordinating helpers and shifts on large events"; # TODO

      database.host = mkOption {
        type = types.str;
        default = "localhost";
        description = "MySQL host";
      };

      database.database = mkOption {
        type = types.str;
        default = "engelsystem";
        description = "MySQL database";
      };

      database.username = mkOption {
        type = types.str;
        default = "engelsystem";
        description = "MySQL username";
      };

      database.password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The password for accessing the MySQL database
          Warning: this is stored in cleartext in the Nix store!
          Use <option>database.passwordFile</option> instead.
        '';
      };

      database.passwordFile = mkOption { # ToDo
        type = types.nullOr types.path;
        default = null;
        example = "/run/keys/es_database";
        description = ''
          A file containign the password corresponding to
          <option>database.passwordFile</option>
        '';
      };

      apiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The api key for accessing the statistics
          Warning: this is stored in cleartext in the Nix store!
          Use <option>apiKeyFile</option> instead.
        '';
      };

      apiKeyFile = mkOption { # ToDo
        type = types.nullOr types.path;
        default = null;
        example = "/run/keys/es_apikey";
        description = ''
          A file containign the api key corresponding to
          <option>apiKey</option>
        '';
      };

      maintenance = mkOption {
        type = types.bool;
        default = false;
        description = "Enable maintenance mode (show a static page)";
      };

      appName = mkOption {
        type = types.str;
        default = "Engelsystem";
        description = "Application name (not the event name!)";
      };

      environment = mkOption {
        type = types.enum [ "production" "development" ];
        default = "production";
        description = "Set to development to enable debugging messages";
      };

      headerItems = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          Foo = "https://foo.bar/batz-%lang%.html";
        };
        description = ''
          Header links
          Available link placeholders: %lang%
        '';
      };

      footerItems = mkOption {
        type = types.attrsOf types.str;
        default = {
          FAQ = "https://events.ccc.de/congress/2013/wiki/Static:Volunteers";
          Contact = "mailto:ticket@c3heaven.de";
        };
        description = "Footer links";
      };

      documantationUrl = mkOption {
        type = types.str;
        default = "https://engelsystem.de/doc/";
        description = "Link to documentation or help";
      };

      mail = {
        driver = mkOption {
          type = types.enum [ "mail" "smtp" "sendmail" "log" ];
          default = "mail";
          description = "Can be mail, smtp, sendmail or log";
        };

        from.address = mkOption {
          type = types.str;
          example = "noreply@engelsystem.de";
          description = "From address of all emails";
        };

        from.name = mkOption {
          type = types.str;
          default = cfg.appName;
          description = "From name of all emails";
        };

        host = mkOption {
          type = types.str;
          default = "localhost";
          description = "mail server host";
        };

        port = mkOption {
          type = types.ints.u16;
          default = 587;
          description = "mail server port";
        };

        encryption = mkOption {
          type = types.nullOr (types.enum [ "tls" "ssl" ]);
          default = null;
          description = "Transport encryption like tls (for starttls) or ssl";
        };

        username = mkOption {
          type = types.str;
          #default = cfg.mail.from.address;
          example = "noreply@engelsystem.de";
          description = "username for mail server";
        };

        password = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Password for mail server
            Warnign: this is stored in cleartext in the Nix store!
            Use <option>mail.passwordFile</option> instead.
          '';
        };

        passwordFile = mkOption { # ToDo
          type = types.nullOr types.path;
          default = null;
          example = "/run/keys/es_mail_password";
          description = ''
            A file containign the mail password corresponding to
            <option>mail.password</option>
          '';
        };

        sendmail = mkOption {
          type = types.str;
          default = "${pkgs.postfix}/bin/sendmail -bs";
          description = "sendmail command to use";
        };
      };

      theme = mkOption {
        type = types.int;
        default = 1;
        description = "default theme, 1=style1.css";
      };

      availableThemes = mkOption {
        type = types.attrsOf types.str;
        default = {
          "0" = "Engelsystem light";
          "1" = "Engelsystem dark";
          "2" = "Engelsystem cccamp15";
          "3" = "Engelsystem 32c3 (2015)";
          "4" = "Engelsystem 33c3 (2016)";
          "5" = "Engelsystem 34c3 light (2017)";
          "6" = "Engelsystem 34c3 dark (2017)";
          "7" = "Engelsystem 35c3 dark (2018)";
          "8" = "Engelsystem cccamp19 blue (2019)";
          "9" = "Engelsystem cccamp19 yellow (2019)";
          "10" = "Engelsystem cccamp19 green (2019)";
          "11" = "Engelsystem high contrast";
          "12" = "Engelsystem 36c3 (2019)";
        };
        description = "Available themes";
      };

      rewriteUrls = mkOption {
        type = types.bool;
        default = true;
        description = "Rewrite URLs with mod_rewrite";
      };

      homeSite = mkOption {
        type = types.enum [ "news" "user_meetings" "user_shifts" "angletypes" "user_questions" ];
        default = "news";
        description = ''
          Redirect to this site after logging in or when pressing the top-left button
          Must be one of news, user_meetings, user_shifts, angeltypes, user_questions
        '';
      };

      displayNews = mkOption {
        type = types.int;
        default = 10;
        description = "Number of News shown on one site";
      };

      registration = mkOption {
        type = types.bool;
        default = true;
        description = "Users are able to sign up";
      };

      signupArrival = mkOption {
        type = types.bool;
        default = false;
        description = "Only arrived angels can sign up for shifts";
      };

      autoarrive = mkOption {
        type = types.bool;
        default = false;
        description = "Whether newly-registered user should automatically be marked as arrived";
      };

      singupHours = mkOption {
        type = types.int;
        default = 0;
        description = ''
          Only allow shift signup this number of hours in advance
          Setting this to 0 disables the feature
        '';
      };

      lastUnsubscribe = mkOption {
        type = types.int;
        default = 3;
        description = "Number of hours that an angel has to sign out own shifts";
      };

      passwordAlgorithm = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Define the algorithm to use for `password_verify()`
          If the user uses an old algorithm the password will be converted to the new format
          See https://secure.php.net/manual/en/password.constants.php for a complete list
        '';
      };

      minPasswordLength = mkOption {
        type = types.int;
        default = 8;
        description = "The minimum length for passwords";
      };

      dect = mkOption {
        type = types.bool;
        default = true;
        description = "Whether the DECT field should be enabled";
      };

      userNames = mkOption {
        type = types.bool;
        default = false;
        description = "Enables prename and lastname";
      };

      pronoun = mkOption {
        type = types.bool;
        default = false;
        description = "Enable displaying the pronoun fields";
      };

      plannedArrival = mkOption {
        type = types.bool;
        default = true;
        description = "Enables the planned arrival/leave date";
      };

      tshirtSize = mkOption {
        type = types.bool;
        default = true;
        description = "Enables the T-Shirt configuration on signup and profile";
      };

      freeloadable = mkOption {
        type = types.int;
        default = 2;
        description = "Number of shifts to freeload until angel is locked for shift signup";
      };

      timezone = mkOption {
        type = types.str;
        default = "Europe/Berlin";
        description = "Local timezone";
      };

      nightShifts.enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Multiply 'night shifts' and freeloaded shifts (start or end between 2 and 6 exclusive) by 2
          Disable to weigh every shift the same
        '';
      };

      nightShifts.start = mkOption {
        type = types.int;
        default = 2;
        description = ''
          when to start multipling shifts, see
          <option>nightShifts.enable</option>
        '';
      };

      nightShifts.end = mkOption {
        type = types.int;
        default = 6;
        description = ''
          when to end multipling shifts, see
          <option>nightShifts.enable</option>
        '';
      };

      nightShifts.multiplier = mkOption {
        type = types.int;
        default = 2;
        description = ''
          multiplier for shifts, see
          <option>nightShifts.enable</option>
        '';
      };

      voucher.initial = mkOption {
        type = types.int;
        default = 0;
        description = "voucher calculation";
      };

      voucher.shifts = mkOption {
        type = types.int;
        default = 0;
        description = "voucher calculation";
      };

      voucher.hours = mkOption {
        type = types.int;
        default = 2;
        description = "voucher calculation";
      };

      voucher.start = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "voucher calculation start (Y-m-d formatted)";
      };

      defaultLocale = mkOption {
        type = types.enum [ "de_DE" "en_US" ];
        default = "en_US";
        description = "The default locale to use";
      };

      availableTshirtSize = mkOption {
        type = types.attrsOf types.str;
        default = {
          "S" = "Small Straight-Cut";
          "S-G" = "Small Fitted-Cut";
          "M" = "Medium Straight-Cut";
          "M-G" = "Medium Fitted-Cut";
          "L" = "Large Straight-Cut";
          "L-G" = "Large Fitted-Cut";
          "XL" = "XLarge Straight-Cut";
          "XL-G" = "XLarge Fitted-Cut";
          "2XL" = "2XLarge Straight-Cut";
          "3XL" = "3XLarge Straight-Cut";
          "4XL" = "4XLarge Straight-Cut";
        };
        description = "Available T-Shirt sizes";
      };

      filterMaxDuration = mkOption {
        type = types.int;
        default = 0;
        description = ''
          Shifts overview
          Set max number of hours that can be shown at once
        '';
      };

      session.driver = mkOption {
        type = types.enum [ "pdo" "native" ];
        default = "pdo";
        description = "driver for cookie storage";
      };

      session.name = mkOption {
        type = types.str;
        default = "session";
        description = "cookie name";
      };

      trustedProxies = mkOption {
        type = types.str;
        default = "127.0.0.0/8,::ffff:127.0.0.0/8,::1/128";
        description = "IP addresses of reverse proxies that are trusted, can be an array or a comma separated list";
      };

      addHeaders = mkOption {
        type = types.bool;
        default = true;
        description = "Add additional headers";
      };

      headers = mkOption {
        type = types.attrsOf types.str;
        default = {
          "X-Content-Type-Options" = "nosniff";
          "X-Frame-Options" = "sameorigin";
          "Referrer-Policy" = "strict-origin-when-cross-origin";
          "Content-Security-Policy" = "default-src \\'self\\' \\'unsafe-inline\\' \\'unsafe-eval\\'";
          "X-XSS-Protection" = "1; mode=block";
          "Feature-Policy" = "autoplay \\'none\\'";
        };
        example = {
          "Strict-Transport-Security" = "max-age=7776000";
          "Expect-CT" = "max-age=7776000,enforce,report-uri=\"[uri]\"";
        };
        description = ''
          headers to set
          see <option>addHeaders</option>
        '';
      };

      credits = mkOption {
        type = types.attrsOf types.str;
        default = {
          "Contribution" = ''
            Please visit [engelsystem/engelsystem](https://github.com/engelsystem/engelsystem) if
            you want to to contribute, have found any [bugs](https://github.com/engelsystem/engelsystem/issues) 
            or need help.
          '';
        };
        description = "A list of credits";
      };

      domain = mkOption {
        type = types.str;
        example = "engelsystem.de";
        description = "domain to serve on";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc."engelsystem/config.php".source = engelsystemConfig;

    services.phpfpm.pools."${user}" = {
      user = user;
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
          root = "${package}/share/engelsystem/public";
          extraConfig = ''
            index index.php;
            try_files $uri $uri/ /index.php?$args;
            autoindex off;
          '';
        };
        "~ \\.php$" = {
          root = "${package}/share/engelsystem/public";
          extraConfig = ''
  					fastcgi_pass unix:${config.services.phpfpm.pools."${user}".socket};
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include ${config.services.nginx.package}/conf/fastcgi_params;
            include ${config.services.nginx.package}/conf/fastcgi.conf;
          '';
        };
      };
    };

    systemd.services."${user}-init"= {
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = user;
      };
      script = ''
        mkdir -p /var/lib/${user}/app
        mkdir -p /var/lib/${user}/cache/views
        ${package}/bin/migrate
      '';
    };
    systemd.services."phpfpm-${user}".after = [ "${user}-init" ];

    users.users."${user}" = {
      isSystemUser = true;
      createHome = true;
      home = "/var/lib/${user}";
      group = user;
    };
    users.groups."${user}" = {};
  };
}
