{ lib, pkgs, pi, ... }:

let
  flattenAttrs = path: set: builtins.foldl' (acc: name:
    let
      value = set.${name};
      newPath = path ++ [ name ];
    in
      if builtins.isAttrs value
      then acc // flattenAttrs newPath value
      else acc // { "${builtins.concatStringsSep "." newPath}" = value; }
  ) {} (builtins.attrNames set);
in
{
  programs = {
    neovim = {
      enable = true;
      viAlias = false;
      vimAlias = true;
      withPython3 = false;
      withRuby = false;
    };

    vscodium = {
      enable = true;
      package = pkgs.vscodium;

      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          rust-lang.rust-analyzer
        ];

        userSettings = flattenAttrs [] {
          # ---- minimal ui ----
          window = {
            customMenuBarAltFocus = false;
            menuBarVisibility = "toggle";
            titleBarStyle = "native";
            title = " ";
            commandCenter = false;
          };

          workbench = {
            colorTheme = lib.mkForce "Default Dark Modern";
            startupEditor = "none";
            activityBar.visible = false;
            statusBar.visible = false;
            layoutControl.enabled = false;
            tree.renderIndentGuides = "none";
            editor.showTabs = "none";
          };

          editor = {
            fontFamily = "Monocraft";
            fontSize = lib.mkForce 12;
            fontLigatures = true;

            minimap.enabled = false;
            glyphMargin = false;
            folding = false;
            showFoldingControls = "never";
            guides.indentation = false;
            renderLineHighlight = "none";
            renderWhitespace = "none";
            overviewRulerBorder = false;
            hideCursorInOverviewRuler = true;
            scrollbar.vertical = "hidden";
            scrollbar.horizontal = "hidden";
            stickyScroll.enabled = false;
            bracketPairColorization.enabled = false;
            cursorBlinking = "phase";
            cursorSmoothCaretAnimation = "on";
            tabSizing = "shrink";
          };

          files.autoSave = "onFocusChange";

          breadcrumbs.enabled = false;

          explorer = {
            openEditors.visible = 0;
            compactFolders = true;
            decorations.colors = false;
          };

          terminal.integrated = {
            fontFamily = "Monocraft";
            minimumContrastRatio = 1;
          };

          # ---- vague workbench colors ----
          workbench.colorCustomizations = {
            # base
            foreground = "#cdcdcd";
            descriptionForeground = "#878787";
            disabledForeground = "#606079";
            border = "#252530";
            contrastBorder = "#252530";
            focusBorder = "#86bece";
            selection.background = "#86bece";
            errorForeground = "#d8647e";

            # editor
            "editor.background" = "#141415";
            "editor.foreground" = "#cdcdcd";
            "editorLineNumber.foreground" = "#878787";
            "editorLineNumber.activeForeground" = "#cdcdcd";
            "editorCursor.foreground" = "#86bece";
            "editor.selectionBackground" = "#86bece";
            "editor.inactiveSelectionBackground" = "#333738";
            "editor.lineHighlightBackground" = "#1c1c24";
            "editorIndentGuide.background" = "#252530";
            "editorIndentGuide.activeBackground" = "#333738";
            "editorGutter.background" = "#141415";
            "editor.findMatchBackground" = "#405065";
            "editor.findMatchBorder" = "#86bece";
            "editorError.foreground" = "#d8647e";
            "editorWarning.foreground" = "#f3be7c";
            "editorInfo.foreground" = "#7e98e8";
            "editorLink.foreground" = "#7e98e8";
            "editorBracketMatch.border" = "#86bece";

            # widgets / popups
            "editorWidget.background" = "#1c1c24";
            "editorWidget.border" = "#252530";
            "editorSuggestWidget.background" = "#1c1c24";
            "editorSuggestWidget.selectedBackground" = "#252530";
            "editorHoverWidget.background" = "#1c1c24";
            "editorHoverWidget.border" = "#252530";

            # input / dropdown / button
            "input.background" = "#1c1c24";
            "input.foreground" = "#cdcdcd";
            "input.border" = "#252530";
            "input.placeholderForeground" = "#606079";
            "inputOption.activeBorder" = "#86bece";
            "dropdown.background" = "#1c1c24";
            "dropdown.foreground" = "#cdcdcd";
            "dropdown.border" = "#252530";
            "button.background" = "#252530";
            "button.hoverBackground" = "#333738";
            "button.foreground" = "#cdcdcd";
            "badge.background" = "#86bece";
            "badge.foreground" = "#141415";

            # lists / sidebar
            "list.background" = "#141415";
            "list.foreground" = "#cdcdcd";
            "list.hoverBackground" = "#252530";
            "list.focusBackground" = "#252530";
            "list.activeSelectionBackground" = "#333738";
            "list.activeSelectionForeground" = "#cdcdcd";
            "list.inactiveSelectionBackground" = "#252530";
            "list.highlightForeground" = "#86bece";
            "sideBar.background" = "#141415";
            "sideBar.foreground" = "#cdcdcd";
            "sideBar.border" = "#252530";
            "sideBarTitle.foreground" = "#878787";
            "sideBarSectionHeader.background" = "#1c1c24";

            # activity / status / title bars
            "activityBar.background" = "#141415";
            "activityBar.foreground" = "#878787";
            "activityBar.inactiveForeground" = "#606079";
            "activityBar.activeBorder" = "#86bece";
            "activityBarBadge.background" = "#86bece";
            "activityBarBadge.foreground" = "#141415";
            "statusBar.background" = "#141415";
            "statusBar.foreground" = "#878787";
            "statusBar.border" = "#252530";
            "statusBarItem.hoverBackground" = "#252530";
            "titleBar.activeBackground" = "#141415";
            "titleBar.activeForeground" = "#cdcdcd";
            "titleBar.inactiveBackground" = "#1c1c24";
            "titleBar.border" = "#252530";

            # tabs / editor group / panel
            "editorGroupHeader.tabsBackground" = "#141415";
            "editorGroupHeader.border" = "#252530";
            "editorGroup.border" = "#252530";
            "tab.activeBackground" = "#1c1c24";
            "tab.activeForeground" = "#cdcdcd";
            "tab.activeBorder" = "#86bece";
            "tab.inactiveBackground" = "#141415";
            "tab.inactiveForeground" = "#878787";
            "tab.hoverBackground" = "#252530";
            "tab.border" = "#252530";
            "panel.background" = "#141415";
            "panel.border" = "#252530";
            "panelTitle.activeBorder" = "#86bece";
            "panelTitle.activeForeground" = "#cdcdcd";
            "panelTitle.inactiveForeground" = "#878787";

            # quick input / menu / notification
            "quickInput.background" = "#1c1c24";
            "quickInput.foreground" = "#cdcdcd";
            "menu.background" = "#1c1c24";
            "menu.foreground" = "#cdcdcd";
            "menu.selectionBackground" = "#333738";
            "menu.selectionForeground" = "#cdcdcd";
            "menu.border" = "#252530";
            "notification.background" = "#1c1c24";
            "notification.border" = "#252530";

            # scrollbar
            "scrollbarSlider.background" = "#252530";
            "scrollbarSlider.hoverBackground" = "#333738";
            "scrollbarSlider.activeBackground" = "#333738";

            # terminal
            "terminal.background" = "#141415";
            "terminal.foreground" = "#cdcdcd";
            "terminal.ansiBlack" = "#141415";
            "terminal.ansiRed" = "#d8647e";
            "terminal.ansiGreen" = "#7fa563";
            "terminal.ansiYellow" = "#e8b589";
            "terminal.ansiBlue" = "#6e94b2";
            "terminal.ansiMagenta" = "#bb9dbd";
            "terminal.ansiCyan" = "#86bece";
            "terminal.ansiWhite" = "#cdcdcd";
            "terminal.ansiBrightBlack" = "#606079";
            "terminal.ansiBrightRed" = "#d8647e";
            "terminal.ansiBrightGreen" = "#7fa563";
            "terminal.ansiBrightYellow" = "#e8b589";
            "terminal.ansiBrightBlue" = "#6e94b2";
            "terminal.ansiBrightMagenta" = "#bb9dbd";
            "terminal.ansiBrightCyan" = "#86bece";
            "terminal.ansiBrightWhite" = "#cdcdcd";

            # git
            "gitDecoration.addedResourceForeground" = "#7fa563";
            "gitDecoration.modifiedResourceForeground" = "#e8b589";
            "gitDecoration.deletedResourceForeground" = "#d8647e";
            "gitDecoration.untrackedResourceForeground" = "#86bece";
          };

          # ---- vague syntax colors ----
          editor.tokenColorCustomizations = {
            comments = "#606079";
            strings = "#e8b589";
            numbers = "#e0a363";
            keywords = "#6e94b2";
            types = "#9bb4bc";
            functions = "#c48282";
            variables = "#cdcdcd";

            textMateRules = [
              { scope = "constant"; settings.foreground = "#aeaed1"; }
              { scope = "constant.language"; settings.foreground = "#b4d4cf"; }
              { scope = "constant.numeric"; settings.foreground = "#e0a363"; }
              { scope = "constant.character"; settings.foreground = "#e8b589"; }
              { scope = "constant.character.escape"; settings.foreground = "#e0a363"; }
              { scope = "constant.other"; settings.foreground = "#aeaed1"; }

              { scope = "entity.name.function"; settings.foreground = "#c48282"; }
              { scope = "entity.name.function.macro"; settings.foreground = "#c48282"; }
              { scope = "entity.name.type"; settings.foreground = "#9bb4bc"; }
              { scope = "entity.name.tag"; settings.foreground = "#9bb4bc"; }
              { scope = "entity.name.label"; settings.foreground = "#c48282"; }
              { scope = "entity.other.attribute-name"; settings.foreground = "#c3c3d5"; }
              { scope = "entity.name.namespace"; settings.foreground = "#c3c3d5"; }

              { scope = "keyword.operator"; settings.foreground = "#90a0b5"; }
              { scope = "storage.type"; settings.foreground = "#9bb4bc"; }

              { scope = "support.function"; settings.foreground = "#c48282"; }
              { scope = "support.function.builtin"; settings.foreground = "#b4d4cf"; }
              { scope = "support.type"; settings.foreground = "#9bb4bc"; }
              { scope = "support.type.builtin"; settings.foreground = "#b4d4cf"; }
              { scope = "support.variable.property"; settings.foreground = "#c3c3d5"; }

              { scope = "variable.language"; settings.foreground = "#b4d4cf"; }
              { scope = "variable.parameter"; settings.foreground = "#bb9dbd"; }
              { scope = "variable.function"; settings.foreground = "#c48282"; }
              { scope = "variable.other.property"; settings.foreground = "#c3c3d5"; }
              { scope = "variable.other.member"; settings.foreground = "#c3c3d5"; }

              { scope = "punctuation"; settings.foreground = "#878787"; }
              { scope = "meta"; settings.foreground = "#c3c3d5"; }
              { scope = "namespace"; settings.foreground = "#c3c3d5"; }
              { scope = "preprocessor"; settings.foreground = "#b4d4cf"; }
              { scope = "meta.preprocessor"; settings.foreground = "#b4d4cf"; }

              { scope = "markup.heading"; settings.foreground = "#c48282"; }
              { scope = "markup.bold"; settings.foreground = "#c48282"; }
              { scope = "markup.italic"; settings.foreground = "#e8b589"; }
              { scope = "markup.list"; settings.foreground = "#e0a363"; }
              { scope = "markup.quote"; settings.foreground = "#90a0b5"; }
              { scope = "markup.link"; settings.foreground = "#7e98e8"; }
              { scope = "markup.underline.link"; settings.foreground = "#7e98e8"; }
              { scope = "markup.raw"; settings.foreground = "#e8b589"; }

              { scope = "string.escape"; settings.foreground = "#e0a363"; }
              { scope = "string.regexp"; settings.foreground = "#e8b589"; }
              { scope = "string.other.link"; settings.foreground = "#7e98e8"; }
            ];
          };
        };
      };
    };
  };

  home.packages = with pkgs; [
    zed-editor
    opencode
    jetbrains.idea
    pi
    omp

    pyright
    ruff
    lua-language-server
    clang-tools
    vim-language-server
    bash-language-server
    yaml-language-server
    rust-analyzer
    gopls
    go
    nixd
    nixfmt
    texlab

    git
    gcc
    ripgrep
    fd
  ];

  home.file = {
    ".config/nvim".source = ./files/.config/nvim;
    ".config/zed/settings.json".source = ./files/.config/zed/settings.json;
    ".config/zed/themes/vague.json".source = ./files/.config/zed/themes/vague.json;
    ".local/bin/nvim-python3" = {
      executable = true;
      source = "${pkgs.python3.withPackages (ps: [ ps.pynvim ])}/bin/python3";
    };
  };

  # VSCodium writes to its settings.json when you change settings in the UI;
  # home-manager links it into the read-only store, so replace it with a
  # writable copy after every switch.
  home.activation.makeVscodiumSettingsWritable = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    settings="$HOME/.config/VSCodium/User/settings.json"
    if [ -L "$settings" ]; then
      cp -L "$settings" "$settings.tmp" && mv "$settings.tmp" "$settings" && chmod u+w "$settings"
    fi
    rm -f "$HOME/.config/VSCodium/User/settings.json.backup"
  '';

  # Zed auto-downloads some language servers (e.g. package-version-server) as
  # generic dynamically-linked binaries, which NixOS cannot execute. Patch them
  # to use the Nix dynamic loader whenever zed pulls a fresh copy.
  home.activation.patchZedLanguageServers = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    for server in $HOME/.local/share/zed/languages/*/*; do
      [ -f "$server" ] || continue
      if [ "$(${pkgs.patchelf}/bin/patchelf --print-interpreter "$server" 2>/dev/null)" = "/lib64/ld-linux-x86-64.so.2" ]; then
        ${pkgs.patchelf}/bin/patchelf \
          --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 \
          --add-rpath ${lib.makeLibraryPath [ pkgs.openssl_3 pkgs.gcc.cc.lib pkgs.glibc ]} \
          "$server"
      fi
    done
  '';
}
