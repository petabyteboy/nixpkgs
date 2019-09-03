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

  buildInputs = [ gnat zlib ];

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
