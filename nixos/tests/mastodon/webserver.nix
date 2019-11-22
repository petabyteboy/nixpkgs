import ../make-test.nix ({ pkgs, ...} : let

  basicConfig = { ... }: {
    services.mastodon = {
      enable = true;
      configureNginx = false;
    };
  };

  databasePasswordFile = toString (pkgs.writeTextFile {
    name = "dbPassFile";
    text = "";
  });

  smtpPasswordFile = toString (pkgs.writeTextFile {
    name = "smtpPasswordFile";
    text = "";
  });

in {
  name = "mastodon-webserver";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [];
  };

  nodes = let
  in rec {
    alice =
      { ... }:
      {
        imports = [ basicConfig ];
        virtualisation.memorySize = 2048;
        services.mastodon = {
          database.passwordFile = databasePasswordFile;
          smtp.passwordFile = smtpPasswordFile;
          smtp.user = "alice";
          smtp.fromAddress = "admin@alice.example.org";
          localDomain = "alice.example.org";
          otpSecretFile = toString (pkgs.writeTextFile {
            name = "alice-otp-secret";
            text = "18d8666a34f20bd7142a777bd71a9cfd55f39ec724c11388541a37ab08115452fc480f193055e68f1f2a9bd5b55c563af6f63b7c25fa7dbede802e4f207862ac";
          });
          secretKeyBaseFile = toString (pkgs.writeTextFile {
            name = "alice-secret-key-base";
            text = "acd4438d9ac8ed80349e6749e319eaff526cc403d2af02083500b57f499fc0bd3fc66f9e04a1ba1fd80ddf72d6f78c5eee6b898802655a8f1c37146c5ec6d6db";
          });
          vapidPrivateKeyFile = toString (pkgs.writeTextFile {
            name = "alice-vapid-private-key";
            text = "_JCD_zhlqASblUh2d_h4t44_DRIkxWnLmSi9uv77jO4=";
          });
          vapidPublicKey = "BInrV6Jdwl7N3CPoLgfWJS2QpQp0-8TseN7vRAa3lCBS1BqlZAi4x_0F0-ynHwY8GCcnFJ0QjvdUB-gBLNnfjRg=";
        };
      };
    };

  testScript =
    ''
      startAll;
      $alice->waitForUnit("multi-user.target");
      $alice->waitForOpenPort(55001);
      $alice->succeed("curl http://localhost:55001/");
    '';
})
