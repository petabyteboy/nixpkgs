{ stdenv, fetchFromGitHub, cmake
, zlib, boost, openssl, python3, ncurses, SystemConfiguration
}:

let
  version = "2.0.1";

  # Make sure we override python, so the correct version is chosen
  boostPython = boost.override { enablePython = true; python = python3; };

in stdenv.mkDerivation {
  pname = "libtorrent-rasterbar";
  inherit version;

  src = fetchFromGitHub {
    owner = "arvidn";
    repo = "libtorrent";
    rev = "v${version}";
    sha256 = "04ppw901babkfkis89pyb8kiyn39kb21k1s838xjq5ghbral1b1c";
    fetchSubmodules = true;
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ cmake ];

  buildInputs = [ boostPython openssl zlib python3 ncurses ]
    ++ stdenv.lib.optionals stdenv.isDarwin [ SystemConfiguration ];

  postInstall = ''
    moveToOutput "include" "$dev"
    moveToOutput "lib/${python3.libPrefix}" "$python"
  '';

  outputs = [ "out" "dev" "python" ];

  cmakeFlags = [
    "-Dpython-bindings=on"
  ];

  meta = with stdenv.lib; {
    homepage = "https://libtorrent.org/";
    description = "A C++ BitTorrent implementation focusing on efficiency and scalability";
    license = licenses.bsd3;
    maintainers = [ maintainers.phreedom ];
    broken = stdenv.isDarwin;
    platforms = platforms.unix;
  };
}
