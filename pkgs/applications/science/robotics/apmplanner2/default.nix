{ lib, mkDerivation, fetchFromGitHub, fetchpatch, qmake
, qtbase, qtscript, qtwebkit, qtserialport, qtsvg, qtdeclarative, qtquickcontrols2
, alsaLib, libsndfile, flite, openssl, udev, SDL2
}:

mkDerivation rec {
  pname = "apmplanner2";
  version = "2.0.28-rc1";

  src = fetchFromGitHub {
    owner = "ArduPilot";
    repo = "apm_planner";
    rev = version;
    sha256 = "18yn8bdz5hmgb0m5hlk8bibz4cj4g25w75pm1rvc4ds0mr1qgyjd";
  };

  buildInputs = [
    alsaLib libsndfile flite openssl udev SDL2
    qtbase qtscript qtwebkit qtserialport qtsvg qtdeclarative qtquickcontrols2
  ];

  nativeBuildInputs = [ qmake ];

  qmakeFlags = [ "apm_planner.pro" ];

  # this ugly hack is necessary, as `bin/apmplanner2` needs the contents of `share/APMPlanner2` inside of `bin/`
  preFixup = ''
    ln --relative --symbolic $out/share/APMPlanner2/* $out/bin/
    substituteInPlace $out/share/applications/apmplanner2.desktop \
      --replace /usr $out
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Ground station software for autonomous vehicles";
    longDescription = ''
      A GUI ground control station for autonomous vehicles using the MAVLink protocol.
      Includes support for the APM and PX4 based controllers.
    '';
    homepage = "https://ardupilot.org/planner2/";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ wucke13 ];
  };
}
