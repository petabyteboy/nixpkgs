{ rustPlatform, fetchFromGitHub, nodejs-14_x, python3, callPackage, fixup_yarn_lock, yarn, sqlcipher }:

rustPlatform.buildRustPackage rec {
  pname = "seshat-node";
  version = "2.2.4";

  src = fetchFromGitHub {
    owner = "petabyteboy";
    repo = "seshat";
    rev = "a67737e7185376a85a39a225826651e6a8b82a7f";
    sha256 = "0x8zdya1ga566j106gafs65q9a9xnhmycalcbkwksc3ssar3xw96";
  };

  sourceRoot = "source/seshat-node/native";

  nativeBuildInputs = [ nodejs-14_x python3 yarn ];
  buildInputs = [ sqlcipher ];

  npm_config_nodedir = nodejs-14_x;

  yarnOfflineCache = (callPackage ./seshat-yarndeps.nix {}).offline_cache;

  buildPhase = ''
    cd ..
    chmod u+w . ./yarn.lock

    export HOME=/tmp
    yarn config --offline set yarn-offline-mirror ${yarnOfflineCache}
    ${fixup_yarn_lock}/bin/fixup_yarn_lock yarn.lock
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs node_modules/

    node_modules/.bin/neon build --release
  '';

  doCheck = false;

  installPhase = ''
    shopt -s extglob
    rm -rf native/!(index.node)
    rm -rf node_modules
    cp -r . $out
  '';

  cargoSha256 = "09lr8gf9ig7fij9y2s9sj5xv5yk1v3fimy8169i656av7ppshq93";
}
