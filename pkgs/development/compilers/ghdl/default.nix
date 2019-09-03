{ stdenv, fetchFromGitHub, gnat, zlib, llvm, lib
, backend ? "mcode" }:

assert backend == "mcode" || backend == "llvm";

let
  inherit (lib) optional optionals maintainers platforms licenses;
  version = "0.36";

in stdenv.mkDerivation rec {
  name = "ghdl-${backend}-${version}";

  src = fetchFromGitHub {
    owner = "ghdl";
    repo = "ghdl";
    rev = "v${version}";
    sha256 = "0wcn4qgalc8mqrpi0nyy5pd74kjf9ldzp3pvz53p3fa6s8fswq0c";
  };

  LIBRARY_PATH = "${stdenv.cc.libc}/lib";

  buildInputs = [ gnat zlib ];

  preConfigure = ''
    # If llvm 7.0 works, 7.x releases should work too.
    sed -i 's/check_version 7.0/check_version 7/g' configure
  '';

  configureFlags = optional (backend == "llvm")
    "--with-llvm-config=${llvm}/bin/llvm-config";

  hardeningDisable = [ "format" ];

  enableParallelBuilding = true;

  meta = {
    homepage = "https://github.com/ghdl/ghdl";
    description = "VHDL 2008/93/87 simulator";
    maintainers = with maintainers; [ lucus16 ];
    platforms = platforms.linux;
    license = licenses.gpl2;
  };
}
