{
  lib,
  stdenvNoCC,
  makeWrapper,
  makeDesktopItem,
  # regular jdk doesnt work due to problems with JavaFX even with .override { enableJavaFX = true; }
  openjdk17-bootstrap,
  xorg,
  libGL,
  gtk3,
  glib,
  alsa-lib,
  unstable ? false,
}: let
  pname = "faf-client";

  versionStable = "2023.1.2";
  sha256Stable = "0lfyfbvjzfgkq3b485d8ma8fjc3hbc5p5h2ffl3lrvai6ksa59g2";
  srcStable = builtins.fetchTarball {
    url = "https://github.com/FAForever/downlords-faf-client/releases/download/v${versionStable}/faf_unix_${builtins.replaceStrings ["."] ["_"] versionStable}.tar.gz";
    sha256 = sha256Stable;
  };

  versionUnstable = "2023.2.0-alpha-2";
  sha256Unstable = "02qvp8n40hwhc6mj6drsvwxkk9ig7fjx1jn0k7pk78cxq1brjvaq";
  srcUnstable = builtins.fetchTarball {
    url = "https://github.com/FAForever/downlords-faf-client/releases/download/v${versionUnstable}/faf_unix_${builtins.replaceStrings ["."] ["_"] versionUnstable}.tar.gz";
    sha256 = sha256Unstable;
  };

  meta = with lib; {
    description = "Official client for Forged Alliance Forever";
    homepage = "https://github.com/FAForever/downlords-faf-client";
    license = licenses.mit;
  };

  icon = builtins.fetchurl {
    url = "https://github.com/FAForever/downlords-faf-client/raw/11f5d9a7a728883374510cdc0bec51c9aa4126d7/src/media/appicon/256.png";
    name = "faf-client.png";
    sha256 = "0zc2npsiqanw1kwm78n25g26f9f0avr9w05fd8aisk191zi7mj5r";
  };
  desktopItem = makeDesktopItem {
    inherit icon;
    name = "faf-client";
    exec = "faf-client";
    comment = meta.description;
    desktopName = "Forged Alliance Forever";
    categories = ["Game"];
    keywords = ["FAF" "Supreme Commander"];
  };

  libs = [
    alsa-lib
    glib
    gtk3.out
    libGL
    xorg.libXxf86vm
  ];
in
  stdenvNoCC.mkDerivation {
    inherit pname meta desktopItem;
    version =
      if unstable
      then versionUnstable
      else versionStable;
    src =
      if unstable
      then srcUnstable
      else srcStable;

    preferLocalBuild = true;
    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -rfv * .install4j $out

      mkdir $out/bin
      makeWrapper $out/faf-client $out/bin/faf-client \
        --chdir $out \
        --set INSTALL4J_JAVA_HOME ${openjdk17-bootstrap} \
        --suffix LD_LIBRARY_PATH : ${lib.strings.makeLibraryPath libs}

      ln -s ../natives/faf-uid $out/lib/faf-uid
      ln -s ${./faf-client-setup.py} $out/bin/faf-client-setup

      mkdir $out/share
      cp -r ${desktopItem}/share/* $out/share/

      runHook postInstall
    '';

    passthru.updateScript = ./update.sh;
  }
