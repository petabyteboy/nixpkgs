{ fetchurl, fetchpatch, stdenv, systemd, lib }:

stdenv.mkDerivation rec {
  pname = "unscd";
  version = "0.54";

  src = fetchurl {
    url = "https://busybox.net/~vda/${pname}/nscd-${version}.c";
    sha256 = "0iv4iwgs3sjnqnwd7dpcw6s7i4ar9q89vgsms32clx14fdqjrqch";
  };

  unpackPhase = ''
    cp $src nscd.c
    chmod u+w nscd.c
  '';

  patches = [
    (fetchpatch {
      url = "https://sources.debian.org/data/main/u/${pname}/${version}-1/debian/patches/change_invalidate_request_info_output";
      sha256 = "17whakazpisiq9nnw3zybaf7v3lqkww7n6jkx0igxv4z2r3mby6l";
    })
    (fetchpatch {
      url = "https://sources.debian.org/data/main/u/${pname}/${version}-1/debian/patches/support_large_numbers_in_config";
      sha256 = "0jrqb4cwclwirpqfb6cvnmiff3sm2jhxnjwxa7h0wx78sg0y3bpp";
    })
    (fetchpatch {
      url = "https://sources.debian.org/data/main/u/${pname}/${version}-1/debian/patches/no_debug_on_invalidate";
      sha256 = "0znwzb522zgikb0mm7awzpvvmy0wf5z7l3jgjlkdpgj0scxgz86w";
    })
    (fetchpatch {
      url = "https://sources.debian.org/data/main/u/${pname}/${version}-1/debian/patches/notify_systemd_about_successful_startup";
      sha256 = "1ipwmbfwm65yisy74nig9960vxpjx683l3skgxfgssfx1jb9z2mc";
    })
    ./remove-old-socket.diff
  ];

  buildInputs = [ systemd ];

  buildPhase = ''
    gcc -Wall \
      -Wl,--sort-section -Wl,alignment \
      -Wl,--sort-common \
      -fomit-frame-pointer \
      -lsystemd \
      -o nscd nscd.c
  '';

  installPhase = ''
    install -Dm755 -t $out/bin nscd
  '';

  meta = with lib; {
    homepage = "https://busybox.net/~vda/unscd/";
    description = "Less buggy replacement for the glibc name service cache daemon";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ petabyteboy ];
  };
}
