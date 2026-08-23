{lib, fetchFromGitHub, gcc14Stdenv, meson, ninja, pkg-config, hyprland, pixman, libdrm, libinput}: gcc14Stdenv.mkDerivation rec {
  pname = "Hyprspace";
  version = "0.1+date=2026-07-25";

  src = fetchFromGitHub {
    owner = "KZDKM";
    repo = "Hyprspace";
    # PR #238: V2 API + Hyprland 0.56 support (not yet on master)
    rev = "0799be7464fac7ea959b7c6c7809dadd6c21c5aa";
    hash = "sha256-P27tvgpduDsMjk9mSti4We+a3kzYWYWznZKizvnyS+Q=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    hyprland.dev
    pixman
    libdrm
  ] ++ hyprland.buildInputs;

  installFlags = [
    "PREFIX=$(out)"
  ];

  postInstall = ''
    [ -f $out/lib/Hyprspace.so ] && mv $out/lib/Hyprspace.so $out/lib/libHyprspace.so || true
  '';

  meta = with lib; {
    description = "Workspace overview plugin for Hyprland";
    homepage = "https://github.com/KZDKM/Hyprspace";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
