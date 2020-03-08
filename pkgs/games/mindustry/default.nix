{ stdenv
, makeWrapper
, makeDesktopItem
, fetchFromGitHub
, gradle_5
, perl
, jre
, libpulseaudio
, jdk
, zip
, SDL2
, glew
, ant
, openal
, pkgconfig

# Make the build version easily overridable.
# Server and client build versions must match, and an empty build version means
# any build is allowed, so this parameter acts as a simple whitelist.
# Takes the package version and returns the build version.
, makeBuildVersion ? (v: v)
, enableClient ? true
, enableServer ? true
}:

let
  pname = "mindustry";
  # Note: when raising the version, ensure that all SNAPSHOT versions in
  # build.gradle are replaced by a fixed version
  # (the current one at the time of release) (see postPatch).
  version = "master";
  buildVersion = makeBuildVersion version;

  src = fetchFromGitHub {
    owner = "Anuken";
    repo = "Mindustry";
    rev = "9ef394a99ea06b5e39e9208839e946a8602afd63";
    sha256 = "01qliqypjbwsjy1cq4nwx9irhamqk3qndyj95n5i5zgkw8av3js4";
  };

  desktopItem = makeDesktopItem {
    type = "Application";
    name = "Mindustry";
    desktopName = "Mindustry";
    exec = "mindustry";
    icon = "mindustry";
  };

  postPatch = ''
    # Remove unbuildable iOS stuff
    sed -i '/^project(":ios"){/,/^}/d' build.gradle
    sed -i '/robo(vm|VM)/d' build.gradle
    rm ios/build.gradle

    # Pin 'SNAPSHOT' versions
    sed -i 's/com.github.anuken:packr:-SNAPSHOT/com.github.anuken:packr:034efe51781d2d8faa90370492133241bfb0283c/' build.gradle
  '';

  # fake build to pre-download deps into fixed-output derivation
  mkDeps = args: stdenv.mkDerivation (args // {
    pname = "${args.pname}-deps";
    nativeBuildInputs = [ gradle_5 perl ] ++ stdenv.lib.optional (args ? nativeBuildInputs) args.nativeBuildInputs;
    buildPhase = ''
      export GRADLE_USER_HOME=$(mktemp -d)
      ${stdenv.lib.concatMapStringsSep "\n" (v: "gradle --no-daemon ${v} -Pbuildversion=${buildVersion}") args.gradleTasks}
    '';
    # perl code mavenizes pathes (com.squareup.okio/okio/1.13.0/a9283170b7305c8d92d25aff02a6ab7e45d06cbe/okio-1.13.0.jar -> com/squareup/okio/okio/1.13.0/okio-1.13.0.jar)
    installPhase = ''
      find $GRADLE_USER_HOME/caches/modules-2 -type f -regex '.*\.\(jar\|pom\)' \
        | perl -pe 's#(.*/([^/]+)/([^/]+)/([^/]+)/[0-9a-f]{30,40}/([^/\s]+))$# ($x = $2) =~ tr|\.|/|; "install -Dm444 $1 \$out/$x/$3/$4/$5" #e' \
        | sh
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  });

  deps = mkDeps {
    # Here we build both the server and the client so we only have to specify
    # one hash for 'deps'. Deps can be garbage collected after the build,
    # so this is not really an issue.
    gradleTasks = [
      "desktop:dist"
      "server:dist"
    ];
    outputHash = "0dgx1m4qhjqicq9zjx3l6b26k8cy2053s440ivyq7n9r103y9iqd";
    inherit version src postPatch pname;
  };

  # Separate commands for building and installing the server and the client
  buildClient = ''
    gradle --offline --no-daemon desktop:dist -Pbuildversion=${buildVersion}
  '';
  buildServer = ''
    gradle --offline --no-daemon server:dist -Pbuildversion=${buildVersion}
  '';
  installClient = ''
    install -Dm644 desktop/build/libs/Mindustry.jar $out/share/mindustry.jar
    mkdir -p $out/bin

    makeWrapper ${jre}/bin/java $out/bin/mindustry \
      --prefix LD_LIBRARY_PATH : ${libpulseaudio}/lib \
      --prefix LD_LIBRARY_PATH : ${glew.out}/lib \
      --set SDL_VIDEODRIVER x11 \
      --add-flags "-jar $out/share/mindustry.jar"

    makeWrapper ${jre}/bin/java $out/bin/mindustry-wayland \
      --prefix LD_LIBRARY_PATH : ${libpulseaudio}/lib \
      --prefix LD_LIBRARY_PATH : ${glew-egl.out}/lib \
      --set SDL_VIDEODRIVER wayland \
      --add-flags "-jar $out/share/mindustry.jar"

    install -Dm644 core/assets/icons/icon_64.png $out/share/icons/hicolor/64x64/apps/mindustry.png
    install -Dm644 ${desktopItem}/share/applications/Mindustry.desktop $out/share/applications/Mindustry.desktop

    pushd ${arc-natives}
    zip $out/share/mindustry.jar libsdl-arc64.so
    popd
    pushd ${SDL2}/lib
    zip $out/share/mindustry.jar libSDL2.so
    popd
  '';
  installServer = ''
    install -Dm644 server/build/libs/server-release.jar $out/share/mindustry-server.jar
    mkdir -p $out/bin
    makeWrapper ${jre}/bin/java $out/bin/mindustry-server \
      --add-flags "-jar $out/share/mindustry-server.jar"
  '';

  glew-egl = glew.overrideAttrs (oldAttrs: {
    pname = "glew-egl";
    makeFlags = [ "SYSTEM=linux-egl" ];
  });

  arc-natives = let
    pname = "arc-natives";
    version = "1.0";
    src = fetchFromGitHub {
      owner = "PetaByteBoy";
      repo = "Arc";
      rev = "feature/dynamic-natives";
      sha256 = "0fz36mcv3ri447mhi95l42b06gjn1ahq2z731jl80y46i37m5vr0";
    };
    buildInputs = [ SDL2 glew openal ];
    nativeBuildInputs = [ pkgconfig gradle_5 makeWrapper zip jdk ant ];
    deps = mkDeps {
      gradleTasks = [ "sdlnatives -Pdynamic" ];
      outputHash = "0hy43j7pkbw4wq7424zh4sm3wb4p21yp92r15wzfb3fmjbymcmsr";
      inherit pname version src buildInputs nativeBuildInputs;
    };
  in stdenv.mkDerivation rec {
    inherit pname version src buildInputs nativeBuildInputs;
    buildPhase = ''
      echo $PATH
      export GRADLE_USER_HOME=$(mktemp -d)
      # point to offline repo
      sed -ie "s#mavenCentral()#mavenCentral(); maven { url '${deps}' }#g" build.gradle
      gradle --offline --no-daemon sdlnatives -Pdynamic
    '';
    installPhase = ''
      install -Dm644 backends/backend-sdl/libs/linux64/libsdl-arc64.so $out/libsdl-arc64.so
    '';
  };

in
assert stdenv.lib.assertMsg (enableClient || enableServer)
  "mindustry: at least one of 'enableClient' and 'enableServer' must be true";
stdenv.mkDerivation rec {
  inherit pname version src postPatch;

  buildInputs = stdenv.lib.optional enableClient [ SDL2 glew ];
  nativeBuildInputs = [ gradle_5 makeWrapper zip ];

  buildPhase = with stdenv.lib; ''
    export GRADLE_USER_HOME=$(mktemp -d)
    # point to offline repo
    sed -ie "s#mavenLocal()#mavenLocal(); maven { url '${deps}' }#g" build.gradle
    ${optionalString enableClient buildClient}
    ${optionalString enableServer buildServer}
  '';

  installPhase = with stdenv.lib; ''
    ${optionalString enableClient installClient}
    ${optionalString enableServer installServer}
  '';

  meta = with stdenv.lib; {
    homepage = "https://mindustrygame.github.io/";
    downloadPage = "https://github.com/Anuken/Mindustry/releases";
    description = "A sandbox tower defense game";
    license = licenses.gpl3;
    maintainers = with maintainers; [ fgaz ];
    platforms = [ "x86_64-linux" ];
  };
}

