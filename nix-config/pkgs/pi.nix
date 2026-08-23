{lib, stdenv, fetchurl, autoPatchelfHook}: stdenv.mkDerivation rec {
  pname = "pi";
  version = "0.84.1";

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";
    sha256 = "sha256-VjTX69GCdLY68zcelC80LXS+oBI4lXXB0f8VzmyoDC8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/pi $out/bin
    cp -r . $out/share/pi/
    cat > $out/bin/pi <<EOF
    #!/bin/sh
    exec $out/share/pi/pi "\$@"
    EOF
    chmod +x $out/bin/pi $out/share/pi/pi
    runHook postInstall
  '';

  meta = with lib; {
    description = "AI agent toolkit: unified LLM API, agent loop, TUI, coding agent CLI";
    homepage = "https://github.com/earendil-works/pi";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pi";
  };
}
