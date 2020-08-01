{ stdenv, lib, fetchgit, pkg-config, meson, ninja, freetype, fontconfig, pixman, tllist }:

stdenv.mkDerivation rec {
  pname = "fcft";
  version = "1.1.7";

  src = fetchgit {
    url = "https://codeberg.org/dnkl/fcft.git";
    rev = "${version}";
    sha256 = "078d8vjxps5cyz7sc14nqjl2fclvz3g18dj1ilih4w5fl7wpyaw7";
  };

  nativeBuildInputs = [ pkg-config meson ninja ];
  buildInputs = [ freetype fontconfig pixman tllist ];

  meta = with lib; {
    homepage = "https://codeberg.org/dnkl/fcft";
    description = "Simple library for font loading and glyph rasterization";
    maintainers = with maintainers; [ fionera ];
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
