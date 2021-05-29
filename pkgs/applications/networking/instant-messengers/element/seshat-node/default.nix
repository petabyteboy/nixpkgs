{ rustPlatform, fetchFromGitHub, nodejs, python3, callPackage, fixup_yarn_lock, yarn, sqlcipher, electron }:

rustPlatform.buildRustPackage rec {
  pname = "seshat-node";
  version = "2.2.4";

  src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "seshat";
    rev = version;
    sha256 = "0kj73k15dyjz8c147jrhvc3x7w294ws2m8calaphc8q1d7iall8n";
  };

  sourceRoot = "source/seshat-node/native";

  nativeBuildInputs = [ nodejs python3 yarn ];
  buildInputs = [ sqlcipher ];


  yarnOfflineCache = (callPackage ./seshat-yarndeps.nix {}).offline_cache;

  buildPhase = ''
    cd ..
    chmod u+w . ./yarn.lock

    # Option 1
    # tar -xf ${electron.headers}
    # export npm_config_nodedir=$PWD/node_headers

    # Option 2
    mkdir -p .electron-gyp/${electron.version}
    tar -x -C .electron-gyp/${electron.version} --strip-components=1 -f ${electron.headers}
    echo 9 > .electron-gyp/${electron.version}/installVersion

    export npm_config_target=${electron.version}
    export npm_config_arch=x64
    export npm_config_target_arch=x64
    export npm_config_runtime=electron
    export npm_config_build_from_source=true,
    export npm_config_devdir=$PWD/.electron-gyp

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

  cargoSha256 = "1ckyjvycqw35g6d7022pqbch5cg79drp6lwc0s5mw5787klckijm";
}
