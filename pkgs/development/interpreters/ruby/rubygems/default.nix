{ stdenv, lib, fetchurl, fetchpatch }:

stdenv.mkDerivation rec {
  name = "rubygems";
  version = "3.0.3";

  src = fetchurl {
    url = "https://rubygems.org/rubygems/rubygems-${version}.tgz";
    sha256 = "0b6b9ads8522804xv8b8498gqwsv4qawv13f81kyc7g966y7lfmy";
  };

  patches = [
    ./0001-add-post-extract-hook.patch
    ./0002-binaries-with-env-shebang.patch
    ./0003-gem-install-default-to-user.patch
    (fetchpatch {
      url = https://patch-diff.githubusercontent.com/raw/rubygems/rubygems/pull/2596.patch;
      sha256 = "0m1s5brd30bqcr8v99sczihm83g270philx83kkw5bpix462fdm3";
    })
  ];

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  meta = with lib; {
    description = "Package management framework for Ruby";
    homepage = https://rubygems.org/;
    license = with licenses; [ mit /* or */ ruby ];
    maintainers = with maintainers; [ qyliss zimbatm ];
  };
}
