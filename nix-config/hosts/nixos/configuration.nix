{ username, terminal, assets, inputs, serenity-emoji, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
    timeout = 0;
  };

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
  ];

  boot.plymouth.enable = true;
  stylix.targets.plymouth = {
    logo = assets.none;
    logoAnimated = false;
  };

  console.keyMap = lib.mkForce "us";

  networking.hostName = "nixos";
  networking.firewall.checkReversePath = "loose";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
  networking.wireless.iwd = {
    enable = true;
    settings.Settings.AlwaysRandomizeAddress = true;
  };

  time.timeZone = "Europe/Athens";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  hardware.graphics.enable = true;
  hardware.uinput.enable = true;
  hardware.bluetooth.enable = true;

  security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.logind.settings.Login.HandlePowerKey = "ignore";

  services.greetd = {
    enable = true;

    settings = let
      command = "Hyprland > /dev/null";
    in rec {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --cmd '${command}'";
        user = username;
      };

      initial_session = {
        inherit command;
        user = username;
      };
    };
  };

  programs = {
    hyprland.enable = true;

    fish.enable = true;

    fuse.userAllowOther = true;

    nh = {
      enable = true;

      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };

      flake = lib.mkForce "/home/gio/configs/current";
    };

    thunar = {
      enable = true;

      plugins = [
        pkgs.thunar-archive-plugin
        pkgs.thunar-volman
      ];
    };

    xfconf.enable = true;
  };

  services = {
    blueman.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "hyprland";
  };

  # blueman picks its tray backend once at startup: without an SNI watcher
  # (waybar) it silently falls back to the X11 tray icon, which is invisible
  # on Wayland. Start it after waybar, and pin the display env because the
  # session manager may carry a stale socket name (blueman then crashes GTK
  # init on restart).
  systemd.user.services.blueman-applet = {
    after = [ "waybar.service" ];
    serviceConfig.Environment = "DISPLAY=:0 WAYLAND_DISPLAY=wayland-1";
  };

  services.udev.packages = [
    pkgs.swayosd
  ];

  systemd.services.swayosd-libinput-backend = {
    description = "swayosd libinput backend";

    documentation = [
      "https://github.com/erikreider/swayosd"
    ];

    wantedBy = [ "graphical.target" ];
    partOf = [ "graphical.target" ];
    after = [ "graphical.target" ];

    serviceConfig = {
      Type = "dbus";
      BusName = "org.erikreider.swayosd";
      ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
      Restart = "on-failure";
    };
  };

  virtualisation = {
    containers.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;

      defaultNetwork.settings.dns_enabled = true;
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    initialPassword = "changeme";
  };

  users.groups = {
    input.members = [ username ];
    uinput.members = [ username ];
  };

  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
    ];

    substituters = [
      "https://cache.nixos.org"
      "https://anyrun.cachix.org"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      "devenv.cachix.org-1:w1cLUi8Q3a55ra3m8JWzmPaNVQ9mMNTsAStLze3ZGo8="
      "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8ZY7bkqOicIy2PD0TVMhN3rdw="
    ];

    trusted-users = [
      "@wheel"
      "root"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  stylix = {
    enable = true;

    image = assets.desk;

    polarity = "dark";

    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    override = {
      base01 = "1d2021";
      base0D = "ebdbb2";
      base0E = "a89984";
    };

    cursor = {
      size = 24;
      name = "macOS";
      package = pkgs.apple-cursor;
    };

    fonts = {
      emoji = {
        name = "SerenityOS Emoji";
        package = serenity-emoji;
      };

      serif = {
        name = "Monocraft";
        package = pkgs.monocraft;
      };

      sansSerif = {
        name = "Monocraft";
        package = pkgs.monocraft;
      };

      monospace = {
        name = "Monocraft";
        package = pkgs.monocraft;
      };
    };
  };
  stylix.targets.gnome-text-editor.enable = false;

  # Don't inject Chromium policies (BrowserThemeColor) — it makes Chromium-based
  # browsers (Helium, Chrome) report "managed by your organisation" and locks
  # their theme.
  stylix.targets.chromium.enable = false;

  home-manager.users.${username} = {
    home.persistence = lib.mkForce {};

    stylix.targets.gnome-text-editor.enable = false;

    stylix.icons = {
      enable = true;

      dark = "Colloid-Gruvbox-Dark";

      package = (pkgs.colloid-icon-theme.overrideAttrs (old: {
        preInstall = old.preInstall or "" + ''
          echo "[categories@2x/22]" >> ./src/index.theme
          echo "Size=22" >> ./src/index.theme
          echo "Scale=2" >> ./src/index.theme
          echo "Context=Categories" >> ./src/index.theme
          echo "Type=Fixed" >> ./src/index.theme
        '';
      })).override {
        schemeVariants = [ "gruvbox" ];
      };
    };

    wayland.windowManager.hyprland.settings = {
      monitor = lib.mkForce [
        {
          output = "DP-3";
          mode = "preferred";
          position = "0x0";
          scale = 1;
        }
        {
          output = "DP-2";
          mode = "preferred";
          position = "1920x0";
          scale = 1;
        }
      ];

      workspace_rule = [
        { workspace = "1"; monitor = "DP-2"; }
        { workspace = "2"; monitor = "DP-2"; }
        { workspace = "3"; monitor = "DP-2"; }
        { workspace = "4"; monitor = "DP-2"; }
        { workspace = "5"; monitor = "DP-2"; }
        { workspace = "6"; monitor = "DP-3"; }
        { workspace = "7"; monitor = "DP-3"; }
        { workspace = "8"; monitor = "DP-3"; }
        { workspace = "9"; monitor = "DP-3"; }
        { workspace = "10"; monitor = "DP-3"; }
      ];

      config = {
        decoration = lib.mkForce {
          rounding = 1;

          active_opacity = 0.85;
          inactive_opacity = 0.80;

          shadow = {
            enabled = false;
          };

          blur = {
            enabled = true;
            size = 6;
            passes = 2;
            vibrancy = 0.2;
          };
        };
      };
    };
  };

  environment.sessionVariables.GDK_SCALE = lib.mkForce "1";

  environment.persistence = lib.mkForce {};

  environment.pathsToLink = [
    "/share/soundfonts"
  ];

  environment.systemPackages = with pkgs; [
    networkmanager
    iw
    blueman
    docker-compose
    podman-compose
    podman-tui
    dive
    devenv

    soundfont-fluid

    swayosd
    obs-studio
  ];

  system.stateVersion = "24.11";
}
