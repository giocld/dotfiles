{lib, stdenv, fetchurl, makeWrapper, autoPatchelfHook, libsForQt5, cairo, pango, at-spi2-core, cups, libgbm, libGL, nss, nspr, alsa-lib, libXdamage, libXrandr}:
stdenv.mkDerivation rec {
  pname = "helium";
  version = "0.15.3.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
    sha256 = "sha256-IEYWTZ48ioufDCdzXgGy/TZw3dHh45mqZuPW0j3DoYY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    cairo
    pango
    at-spi2-core
    cups
    libgbm
    libGL
    nss
    nspr
    alsa-lib
    libXdamage
    libXrandr
  ] ++ (with libsForQt5; [
    qtbase
    qtwayland
    qtdeclarative
    qtsvg
  ]);

  autoPatchelfIgnoreMissingDeps = [
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];

  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/helium
    tar -xJf $src --strip-components=1 -C $out/lib/helium
    install -Dm644 $out/lib/helium/helium.desktop $out/share/applications/helium.desktop
    runHook postInstall
  '';

  postFixup = let
    qtbase' = libsForQt5.qtbase;
    plugins = lib.makeSearchPath qtbase'.qtPluginPrefix (with libsForQt5; [
      qtbase
      qtwayland.bin
    ]);
  in ''
    makeWrapper $out/lib/helium/helium-wrapper $out/bin/helium \
      --prefix QT_PLUGIN_PATH : ${plugins} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib libGL ]}
  '';

  meta = with lib; {
    description = "Private, fast, and honest web browser";
    homepage = "https://github.com/imputnet/helium";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
