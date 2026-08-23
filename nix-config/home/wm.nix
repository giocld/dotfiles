{ config, lib, username, terminal, pkgs, ... }:

let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  home.packages = with pkgs; [
    hyprpaper
    hyprpicker
    swayidle
    grimblast
    wl-clipboard
    bluetui
    impala
    proton-vpn
  ];

  services = {
    swayosd = {
      enable = true;
      stylePath = ./files/.config/swayosd/style.css;
    };

    dunst = {
      enable = true;

      settings = {
        global = {
          frame_width = 4;
          offset = "10x10";
        };

        # Spotify sends a "now playing" notification on every track change.
        # DeltaTune shows the current song instead, so ignore these.
        "ignore-spotify-nowplaying" = {
          appname = "Spotify";
          skip_display = true;
        };
      };
    };

    cliphist.enable = true;
  };

  programs = {
    anyrun = {
      enable = true;

      config = {
        plugins = with pkgs.inputs.anyrun; [
          applications
          translate
          rink
        ];

        hideIcons = true;
      };

      extraCss = ''
        * {
          border-radius: 0px;
          border-width: 4px;
        }
      '';
    };

    waybar = {
      enable = true;

      settings.main = {
        height = 1;

        layer = "bottom";
        position = "top";

        modules-left = [
          "hyprland/workspaces"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "network#vpn"
          "network#wifi"
          "pulseaudio"
          "tray"
        ];

        "hyprland/workspaces" = {
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };

        clock = {
          tooltip = true;
          tooltip-format = "{:%d/%m/%y}";
        };

        "network#vpn" = {
          interface = "proton0";
          format = "";
          format-disconnected = "*";
          tooltip = false;
        };

        "network#wifi" = {
          interface = "wlan0";
          format-linked = "";
          format-ethernet = "";
          format-disconnected = "";
          format-wifi = "{signalStrength}%";
          tooltip-format = "{essid}";
        };

        pulseaudio = {
          on-click = "exec ~/.local/bin/audio-menu input";
          on-click-right = "exec ~/.local/bin/audio-menu output";
          on-click-middle = "exec swayosd-client --output-volume=mute-toggle";
        };

        battery = {
          format-time = "{H}h{M}m";
          tooltip-format = "{time}";
        };
      };

      style = ''        * {
          border-radius: 0px;
          border-width: 0px;
          font-weight: normal;
        }

        window#waybar {
          background-color: ${colors.base00};
          color: #ccbf9c;
          border-bottom: 1px solid #3a3836;
        }

        tooltip {
          background: ${colors.base00};
          border-color: ${colors.base0E};
        }

        #workspaces button {
          color: ${colors.base0E};
          padding-left: 9px;
          padding-right: 8px;
        }
        #workspaces button.active,
        #workspaces button.focused {
          background: ${colors.base0D};
          color: ${colors.base00};
        }
      '' + (builtins.readFile ./files/.config/waybar/base.css);
    };

    swaylock.enable = true;

    kitty = {
      enable = true;

      settings = {
        confirm_os_window_close = 0;
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;

    configType = "lua";

    package = null;
    portalPackage = null;

    systemd = {
      enable = false;
      variables = [];
    };

    # Load Hyprspace during config parse so its Lua API (hl.plugin.overview.*)
    # is available to binds. With configType = "lua", the `plugins` option
    # renders hl.plugin.load(...) before settings, so plugin dispatchers work.
    plugins = [ pkgs.Hyprspace ];

    settings = {
      monitor = [
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1.6;
        }
      ];

      config = {
        decoration = {
          blur = {
            enabled = true;
            passes = 2;
            size = 4;
            vibrancy = 0.1;
          };

          shadow = {
            enabled = true;

          };

          active_opacity = 0.83;
          inactive_opacity = 0.77;
          rounding = 1;
        };

        dwindle = {
          preserve_split = true;
          smart_split = false;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        xwayland = {
          force_zero_scaling = true;
        };

        general = {
          border_size = 4;
          gaps_in = 1;
          gaps_out = 1;
          layout = "dwindle";
        };

        animations = {
          enabled = false;
        };

        input = {
          kb_layout = "us, gr";

          touchpad = {
            clickfinger_behavior = true;
            disable_while_typing = false;
            natural_scroll = true;
            tap_to_click = false;
          };
        };
      };

      # DeltaTune now-playing overlay: no border/shadow/blur around the words
      window_rule = [
        {
          name = "deltatune-overlay";
          match = { title = "^DeltaTune$"; };
          decorate = false;
          no_shadow = true;
          no_blur = true;
          no_anim = true;
        }
      ];

      # 3-finger horizontal swipe switches workspaces
      # (replaces the removed gestures.workspace_swipe option)
      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        }
      ];

      on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("waybar")
                hl.exec_cmd("hyprpaper")
                hl.exec_cmd("dunst")
                hl.exec_cmd("swayidle -w before-sleep 'swaylock -fu' lock 'swaylock -fu'")
                hl.exec_cmd("swayosd-server --style ${./files/.config/swayosd/style.css}")
                hl.exec_cmd("blueman-applet")
                hl.exec_cmd("wl-paste --watch cliphist -max-dedupe-search 10 -max-items 500 store")
                hl.exec_cmd("wl-paste --type image --watch cliphist -max-dedupe-search 10 -max-items 500 store")
              end
            '')
          ];
        }
      ];

      bind = [
        # workspace overview (Hyprspace)
        {
          _args = [
            "SUPER + grave"
            (lib.generators.mkLuaInline "function() hl.plugin.overview.toggle() end")
          ];
        }

        {
          _args = [
            "SUPER + RETURN"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("kitty")'')
          ];
        }

        {
          _args = [
            "SUPER + SPACE"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("anyrun")'')
          ];
        }

        {
          _args = [
            "SUPER + W"
            (lib.generators.mkLuaInline "hl.dsp.window.kill()")
          ];
        }

        {
          _args = [
            "SUPER + E"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("thunar")'')
          ];
        }

        {
          _args = [
            "SUPER + B"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("helium")'')
          ];
        }

        {
          _args = [
            "SUPER + CTRL + SHIFT + W"
            (lib.generators.mkLuaInline "hl.dsp.exit()")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + V"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("protonvpn-app")'')
          ];
        }

        {
          _args = [
            "SUPER + H"
            (lib.generators.mkLuaInline ''hl.dsp.focus({direction ="left"})'')
          ];
        }

        {
          _args = [
            "SUPER + L"
            (lib.generators.mkLuaInline ''hl.dsp.focus({direction ="right"})'')
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + H"
            (lib.generators.mkLuaInline ''hl.dsp.window.move({direction ="left"})'')
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + J"
            (lib.generators.mkLuaInline ''hl.dsp.window.move({direction ="down"})'')
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + L"
            (lib.generators.mkLuaInline ''hl.dsp.window.move({direction ="right"})'')
          ];
        }


        # screenshots
        {
          _args = [
            "SUPER + S"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("grimblast copy screen")'')
          ];
        }

        {
          _args = [
            "SUPER + CTRL + S"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("grimblast save screen")'')
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + S"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("grimblast copy area")'')
          ];
        }

        {
          _args = [
            "SUPER + CTRL + SHIFT + S"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("grimblast save area")'')
          ];
        }

        # clipboard
        {
          _args = [
            "SUPER + SHIFT + C"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("cliphist wipe")'')
          ];
        }

        # media keys
        {
          _args = [
            "XF86MonBrightnessDown"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --brightness=lower")'')
          ];
        }

        {
          _args = [
            "XF86MonBrightnessUp"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --brightness=raise")'')
          ];
        }

        {
          _args = [
            "XF86AudioLowerVolume"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --output-volume=lower")'')
          ];
        }

        {
          _args = [
            "XF86AudioRaiseVolume"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --output-volume=raise")'')
          ];
        }

        {
          _args = [
            "XF86AudioMute"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("swayosd-client --output-volume=mute-toggle")'')
          ];
        }

        {
          _args = [
            "SUPER + P"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("hyprpicker -al")'')
          ];
        }

        {
          _args = [
            "SUPER + F"
            (lib.generators.mkLuaInline "hl.dsp.window.fullscreen_state({internal = 1, client = 1, action = \"toggle\"})")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + F"
            (lib.generators.mkLuaInline "hl.dsp.window.fullscreen_state({internal = 2, client = 2, action = \"toggle\"})")
          ];
        }

        # groups (native hyprland, shown as tabs)
        {
          _args = [
            "SUPER + SHIFT + T"
            (lib.generators.mkLuaInline "hl.dsp.group.toggle()")
          ];
        }

        {
          _args = [
            "SUPER + T"
            (lib.generators.mkLuaInline "hl.dsp.group.next()")
          ];
        }

        {
          _args = [
            "SUPER + D"
            (lib.generators.mkLuaInline "hl.dsp.group.prev()")
          ];
        }

        # focus / move between nodes
        {
          _args = [
            "SUPER + left"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"left\" })")
          ];
        }

        {
          _args = [
            "SUPER + right"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"right\" })")
          ];
        }

        {
          _args = [
            "SUPER + up"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"up\" })")
          ];
        }

        {
          _args = [
            "SUPER + down"
            (lib.generators.mkLuaInline "hl.dsp.focus({ direction = \"down\" })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + left"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ direction = \"left\" })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + right"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ direction = \"right\" })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + up"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ direction = \"up\" })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + down"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ direction = \"down\" })")
          ];
        }

        # move window between screens
        {
          _args = [
            "SUPER + CTRL + SHIFT + left"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ direction = \"left\" })")
          ];
        }

        {
          _args = [
            "SUPER + CTRL + SHIFT + right"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ direction = \"right\" })")
          ];
        }

        # resize window (no mouse)
        {
          _args = [
            "SUPER + CTRL + left"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = -40, y = 0, relative = true })")
          ];
        }

        {
          _args = [
            "SUPER + CTRL + right"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = 40, y = 0, relative = true })")
          ];
        }

        {
          _args = [
            "SUPER + CTRL + up"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = 0, y = -40, relative = true })")
          ];
        }

        {
          _args = [
            "SUPER + CTRL + down"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = 0, y = 40, relative = true })")
          ];
        }

        {
          _args = [
            "SUPER + O"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("kitty opencode")'')
          ];
        }

        {
          _args = [
            "SUPER + D"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("vesktop")'')
          ];
        }

        {
          _args = [
            "SUPER + N"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("kitty nvim")'')
          ];
        }

        {
          _args = [
            "SUPER + V"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("codium")'')
          ];
        }

        {
          _args = [
            "SUPER + Z"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("zeditor")'')
          ];
        }

        {
          _args = [
            "ALT + S"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("$HOME/.local/share/spotify/spotify")'')
          ];
        }
        {
          _args = [
            "SUPER + I"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("idea")'')
          ];
        }

        # tab navigation
        {
          _args = [
            "SUPER + TAB"
            (lib.generators.mkLuaInline "hl.dsp.group.prev()")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + TAB"
            (lib.generators.mkLuaInline "hl.dsp.group.next()")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + E"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = \"empty\" })")
          ];
        }

        {
          _args = [
            "SUPER + 1"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 1 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 1"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 1, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 2"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 2 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 2"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 2, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 3"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 3 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 3"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 3, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 4"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 4 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 4"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 4, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 5"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 5 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 5"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 5, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 6"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 6 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 6"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 6, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 7"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 7 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 7"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 7, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 8"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 8 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 8"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 8, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 9"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 9 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 9"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 9, follow = false })")
          ];
        }

        {
          _args = [
            "SUPER + 0"
            (lib.generators.mkLuaInline "hl.dsp.focus({ workspace = 10 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + 0"
            (lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = 10, follow = false })")
          ];
        }

        # mouse binds (old bindm)
        {
          _args = [
            "SUPER + mouse:272"
            (lib.generators.mkLuaInline "hl.dsp.window.drag()")
            { mouse = true; }
          ];
        }

        {
          _args = [
            "SUPER + mouse:273"
            (lib.generators.mkLuaInline "hl.dsp.window.resize()")
            { mouse = true; }
          ];
        }
      ];
    };
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = let
      thunar = [
        "thunar.desktop"
      ];
    in {
      "inode/directory" = thunar;
      "inode/mount-point" = thunar;
    };
  };

  home.file.".config/xfce4/helpers.rc".text = ''
    TerminalEmulator=${terminal}
    TerminalEmulatorDismissed=true
  '';

  # Recolor blueman's tray icon to match the waybar text color
  home.file.".local/share/icons/Colloid-Gruvbox-Dark/status/symbolic/blueman-tray-symbolic.svg".source = ./files/.local/share/icons/Colloid-Gruvbox-Dark/status/symbolic/blueman-tray-symbolic.svg;

  stylix.targets.waybar.enable = false;
}
