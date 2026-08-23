{ config, lib, pkgs, ... }:

let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  programs = {
    nixcord = {
      enable = true;

      discord = {
        enable = false;
      };

      vesktop = {
        enable = true;
      };

      config = {
        plugins = {
          gifPaste = {
            enable = true;
          };

          fakeNitro = {
            enable = true;
          };

          fixCodeblockGap = {
            enable = true;
          };

          fixYoutubeEmbeds = {
            enable = true;
          };

          youtubeAdblock = {
            enable = true;
          };
        };

        useQuickCss = true;
        disableMinSize = true;
      };
    };

    yt-dlp.enable = true;

    mpv = {
      enable = true;

      config = {
        background = "color";
        background-color = lib.mkDefault colors.base00;
      };
    };

    imv = {
      enable = true;

      settings = {
        options = {
          background = colors.base00;
        };
      };
    };

    zathura.enable = true;
  };

  home.packages = with pkgs; [
    spotify
    spicetify-cli
  ];

  # Launcher entry pointing at the spicetify-patched copy
  # (the packaged desktop file execs the read-only store binary).
  home.file.".local/share/applications/spotify.desktop" = {
    text = ''
      [Desktop Entry]
      Name=Spotify
      Comment=Play music with the spicetify-patched client
      Exec=${config.home.homeDirectory}/.local/share/spotify/spotify %U
      Icon=spotify
      Type=Application
      Terminal=false
      Categories=AudioVideo;Audio;Player;
    '';
  };

  home.file.".local/bin/spicetify-setup.sh" = {
    source = ./files/.local/bin/spicetify-setup.sh;
    executable = true;
  };

  # spicetify writes state into its config dir, so seed a writable copy once.
  home.activation.seedSpicetify = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -e "$HOME/.config/spicetify" ]; then
      mkdir -p "$HOME/.config"
      cp -aL ${./files/.config/spicetify} "$HOME/.config/spicetify"
      chmod -R u+w "$HOME/.config/spicetify"
    fi
  '';

  xdg.mimeApps = {
    enable = true;

    defaultApplications = let
      helium = [
        "helium.desktop"
      ];
    in {
      "text/xml" = helium;
      "text/html" = helium;
      "x-scheme-handler/http" = helium;
      "x-scheme-handler/https" = helium;
    };
  };
}
