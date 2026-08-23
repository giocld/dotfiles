{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tilt

    lazygit
    lazydocker
    fastfetch
    btop

    ffmpeg
    p7zip
    unzip
    gnumake
    fluidsynth
    bun

    fish
    eza
    starship
    fluidsynth
    soundfont-fluid
    wlr-randr
    fuzzel
  ];

  programs = {
    bat.enable = true;

    carapace = {
      enable = true;
      enableFishIntegration = true;
    };

    direnv = {
      enable = true;
      enableFishIntegration = true;
    };

    fzf.enable = true;

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  home.file = {
    ".config/fish/config.fish".source = ./files/.config/fish/config.fish;
    ".config/fish/conf.d/vague_theme.fish".source = ./files/.config/fish/conf.d/vague_theme.fish;
    ".config/starship/starship.toml".source = ./files/.config/starship/starship.toml;
    ".config/fastfetch/config.jsonc".source = ./files/.config/fastfetch/config.jsonc;
    ".config/fastfetch/logo.txt".source = ./files/.config/fastfetch/logo.txt;
    ".config/fuzzel/fuzzel.ini".source = ./files/.config/fuzzel/fuzzel.ini;
    ".local/bin/audio-menu" = {
      source = ./files/.local/bin/audio-menu;
      executable = true;
    };
  };
}
