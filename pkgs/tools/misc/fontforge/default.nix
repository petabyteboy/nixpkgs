{ stdenv, fetchurl, lib
, fetchpatch
, cmake, perl, uthash, pkg-config, gettext
, python, freetype, zlib, glib, libungif, libpng, libjpeg, libtiff, libxml2, cairo, pango
, readline, woff2, zeromq, libuninameslist
, withSpiro ? false, libspiro
, withGTK ? false, gtk3
, withGUI ? withGTK
, withPython ? true
, withExtras ? true
, Carbon ? null, Cocoa ? null
}:

assert withGTK -> withGUI;

stdenv.mkDerivation rec {
  pname = "fontforge";
  version = "20201107";

  src = fetchurl {
    url = "https://github.com/${pname}/${pname}/releases/download/${version}/${pname}-${version}.tar.xz";
    sha256 = "0y3c8x1i6yf6ak9m5dhr1nldgfmg7zhnwdfd57ffs698c27vmg38";
  };

  # use $SOURCE_DATE_EPOCH instead of non-deterministic timestamps
  postPatch = ''
    find . -type f -name '*.c' -exec sed -r -i 's#\btime\(&(.+)\)#if (getenv("SOURCE_DATE_EPOCH")) \1=atol(getenv("SOURCE_DATE_EPOCH")); else &#g' {} \;
    sed -r -i 's#author\s*!=\s*NULL#& \&\& !getenv("SOURCE_DATE_EPOCH")#g'                            fontforge/cvexport.c fontforge/dumppfa.c fontforge/print.c fontforge/svg.c fontforge/splineutil2.c
    sed -r -i 's#\bb.st_mtime#getenv("SOURCE_DATE_EPOCH") ? atol(getenv("SOURCE_DATE_EPOCH")) : &#g'  fontforge/parsepfa.c fontforge/sfd.c fontforge/svg.c
    sed -r -i 's#^\s*ttf_fftm_dump#if (!getenv("SOURCE_DATE_EPOCH")) ttf_fftm_dump#g'                 fontforge/tottf.c
    sed -r -i 's#sprintf\(.+ author \);#if (!getenv("SOURCE_DATE_EPOCH")) &#g'                        fontforgeexe/fontinfo.c
  '';

  # do not use x87's 80-bit arithmetic, rouding errors result in very different font binaries
  NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isi686 "-msse2 -mfpmath=sse";

  nativeBuildInputs = [ pkg-config cmake ];
  buildInputs = [
    readline uthash woff2 zeromq libuninameslist
    python freetype zlib glib libungif libpng libjpeg libtiff libxml2
  ]
    ++ lib.optionals withSpiro [libspiro]
    ++ lib.optionals withGUI [ gtk3 cairo pango ]
    ++ lib.optionals stdenv.isDarwin [ Carbon Cocoa ];

  cmakeFlags = [ "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON" ]
    ++ lib.optional (!withSpiro) "-DENABLE_LIBSPIRO=OFF"
    ++ lib.optional (!withGUI) "-DENABLE_GUI=OFF"
    ++ lib.optional (!withGTK) "-DENABLE_X11=ON"
    ++ lib.optional withExtras "-DENABLE_FONTFORGE_EXTRAS=ON";

  # work-around: git isn't really used, but configuration fails without it
  preConfigure = ''
    # The way $version propagates to $version of .pe-scripts (https://github.com/dejavu-fonts/dejavu-fonts/blob/358190f/scripts/generate.pe#L19)
    export SOURCE_DATE_EPOCH=$(date -d ${version} +%s)
  '';

  postInstall =
    # get rid of the runtime dependency on python
    lib.optionalString (!withPython) ''
      rm -r "$out/share/fontforge/python"
    '';

  meta = {
    description = "A font editor";
    homepage = "http://fontforge.github.io";
    platforms = lib.platforms.all;
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.erictapen ];
  };
}
