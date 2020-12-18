{ stdenv
, fetchFromGitLab
, meson
, ninja
, pkg-config
, wrapGAppsHook
, libinput
, gnome3
, glib
, gtk3
, wayland
, dbus
, cmake
, libdrm
, libxkbcommon
, wlroots
, python3
}:

stdenv.mkDerivation rec {
  pname = "phoc";
  version = "0.5.1";

  src = fetchFromGitLab {
    domain = "source.puri.sm";
    owner = "Librem5";
    repo = pname;
    rev = "v${version}";
    sha256 = "0g2l3g4680f9jqlsaksmknhxa9wx8dby94qsd93maf0ik9hj7a88";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wrapGAppsHook
    python3
  ];

  buildInputs = [
    libdrm.dev
    libxkbcommon
    libinput
    glib
    gtk3
    gnome3.gnome-desktop
    # For keybindings settings schemas
    gnome3.mutter
    wayland
    wlroots
  ];

  mesonFlags = ["-Dembed-wlroots=disabled"];

  prePatch = ''
    patchShebangs build-aux/post_install.py
  '';

  postInstall = ''
    ${glib.dev}/bin/glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  meta = with stdenv.lib; {
    description = "Wayland compositor for mobile phones like the Librem 5";
    homepage = "https://source.puri.sm/Librem5/phoc";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ masipcat ];
    platforms = platforms.linux;
  };
}
