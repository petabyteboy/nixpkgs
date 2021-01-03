{ stdenv
, fetchFromGitHub
, fetchpatch
, jdk
, SDL2
, pkg-config
, stb
, ant
, makeWrapper

# from mindustry
, gradle_6
, mkDeps
, glew
, version
}:

let
  pname = "arc-natives";
  # Arc is usually tagged in sync with Mindustry, you can check this in Mindustry/gradle.properties
  inherit version;
  src = fetchFromGitHub {
    owner = "Anuken";
    repo = "Arc";
    rev = "v${version}";
    sha256 = "0inzyj01442da7794cpxlaab7di9gv1snc97cbffqsdxgin16i7d";
  };
  patches = [
    ./0001-fix-include-path-for-SDL2-on-linux.patch
    # upstream fix for https://github.com/Anuken/Arc/issues/40, remove on next release
    (fetchpatch {
      url = "https://github.com/Anuken/Arc/commit/b2f3d212c1a88a62f140f5cb04f4c86e61332d1c.patch";
      sha256 = "1z0vxr906mmi8vk75s3xv6cbn2flv2pikkv5yifmiq1xywhc1gwz";
    })
  ];
  buildInputs = [ SDL2 glew ];
  nativeBuildInputs = [ pkg-config gradle_6 makeWrapper jdk ant ];
  postPatch = ''
    cp ${stb.src}/stb_image.h arc-core/csrc/
    cp -r ${fetchFromGitHub {
      owner = "Anuken";
      repo = "soloud";
      # this is never pinned in upstream, see https://github.com/Anuken/Arc/issues/39
      rev = "8553049c6fb0d1eaa7f57c1793b96219c84e8ba5";
      sha256 = "076vnjs2qxd65qq5i37gbmj5v5i04a1vw0kznq986gv9190jj531";
    }} arc-core/csrc/soloud
    chmod u+w -R arc-core/csrc/soloud
  '';
  deps = mkDeps {
    gradleTasks = [ "sdlnatives -Pdynamic" ];
    outputHash = "1flr5cihqpimxk1bk43gbqsg25scc2rxq5b7qsnnzijv608vkj1f";
    inherit pname version src postPatch buildInputs nativeBuildInputs patches;
  };
in stdenv.mkDerivation rec {
  inherit pname version src postPatch buildInputs nativeBuildInputs patches;
  buildPhase = ''
    echo $PATH
    export GRADLE_USER_HOME=$(mktemp -d)
    # point to offline repo
    sed -ie "s#mavenCentral()#mavenCentral(); maven { url '${deps}' }#g" build.gradle
    gradle --offline --no-daemon sdlnatives -Pdynamic
  '';
  installPhase = ''
    install -Dm644 backends/backend-sdl/libs/linux64/libsdl-arc64.so $out/libsdl-arc64.so
    patchelf --add-needed ${glew.out}/lib/libGLEW.so $out/libsdl-arc64.so
    patchelf --add-needed ${SDL2}/lib/libSDL2.so $out/libsdl-arc64.so
  '';
}
