{ stdenv
, fetchurl
, autoPatchelfHook
, ncurses5 }:

stdenv.mkDerivation {
  pname = "gnats-bootstrap";
  version = "2014";

  buildInputs = [
    ncurses5
  ];

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  src = fetchurl {
    name = "gnat-gpl-2014-x86_64-linux-bin.tar.gz";
    url = "https://community.download.adacore.com/v1/6eb6eef6bb897e4c743a519bfebe0b1d6fc409c6?filename=gnat-gpl-2014-x86_64-linux-bin.tar.gz";
    sha256 = "0cxpxbx3dnq6fsy4k3qil377znv8k13nn3xgfha9jmpm9p4shqw0";
  };

  buildPhase = ":";

  passthru = {
    langC = true; # TRICK for gcc-wrapper to wrap it
    langCC = false;
    langFortran = false;
    langAda = true;
  };

  installPhase = ''
    mkdir -p $out
    cp -R . $out

    rm $out/bin/gps_exe
    rm -R $out/lib/python2.7/ $out/share/gdb-7.7/python-2.7.3 $out/lib/gtk-3.0 $out/lib/gps/gdk-pixbuf-2.0 $out/lib/gps $out/lib/libpyglib-gi-2.0-python.so.0.0.0
  '';
}
