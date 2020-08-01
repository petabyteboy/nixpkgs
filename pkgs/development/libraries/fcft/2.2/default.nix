{ stdenv, lib, fetchgit, pkg-config, meson, ninja, freetype, fontconfig, pixman, tllist, scdoc }:

stdenv.mkDerivation rec {
  pname = "fcft";
  version = "2.2.4";

  src = fetchgit {
    url = "https://codeberg.org/dnkl/fcft.git";
    rev = "${version}";
    sha256 = "1ynzbgiwhlhp9ialws7jnh72jvdsrwd9xfwvphmm86fir4brfiz7";
  };

  nativeBuildInputs = [ pkg-config meson ninja scdoc ];
  buildInputs = [ freetype fontconfig pixman tllist ];

  meta = with lib; {
    homepage = "https://codeberg.org/dnkl/fcft";
    description = "Simple library for font loading and glyph rasterization";
    maintainers = with maintainers; [ fionera ];
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
