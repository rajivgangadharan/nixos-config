# =============================================================================
# NixOS configuration — Regolith 3.x look & feel
# Mirrors: i3-gaps + Solarized Dark + picom + LightDM + rofi + dunst
#
# Setup steps:
#   1. Copy hardware-configuration.nix from the installer (nixos-generate-config)
#   2. Add required channels:
#        sudo nix-channel --add \
#          https://github.com/nix-community/disko/archive/main.tar.gz disko
#        sudo nix-channel --add \
#          https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz \
#          home-manager
#        sudo nix-channel --update
#   3. Uncomment the disko + disk-config and home-manager imports below
#   4. sudo nixos-rebuild switch
# =============================================================================
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Disko — declarative disk partitioning (requires disko channel, see step 2)
    # <disko/module.nix>   # ← uncomment after adding disko channel
    # ./disk-config.nix    # ← uncomment together with the line above
    # Home Manager — user dotfiles (requires home-manager channel, see step 2)
    # <home-manager/nixos> # ← uncomment after adding home-manager channel
  ];

  # ── Boot ────────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hibernation — swap is partition 3 on the NVMe (36G, matches 32G RAM)
  boot.resumeDevice = "/dev/disk/by-id/nvme-CT500P3SSD8_2234E65A6AD2-part3";

  # ── Networking ───────────────────────────────────────────────────────────────
  networking.hostName             = "nixos"; # ← change to your hostname
  networking.networkmanager.enable = true;

  # ── Locale / Time ────────────────────────────────────────────────────────────
  time.timeZone      = "America/New_York"; # ← change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Users ────────────────────────────────────────────────────────────────────
  users.users.rajivg = {
    isNormalUser    = true;
    description     = "Rajiv G";
    extraGroups     = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell           = pkgs.bash;
    initialPassword = "nixos"; # ← temporary; forced to change on first login
  };

  users.users.rishir = {
    isNormalUser    = true;
    description     = "Rishi Rajiv";
    extraGroups     = [ "networkmanager" "video" "audio" "input" ]; # no wheel — not a sudoer
    shell           = pkgs.bash;
    initialPassword = "nixos"; # ← temporary; forced to change on first login
  };

  # Force both users to set a new password on first login.
  # chage -d 0 sets sp_lstchg = 0, which PAM/login treat as "expired: must change now".
  # The state file prevents this from re-triggering on every nixos-rebuild.
  system.activationScripts.forcePasswordExpiry = {
    deps = [ "users" ];
    text = ''
      for user in rajivg rishir; do
        state="/var/lib/nixos/pw-expire-done-$user"
        if [ ! -f "$state" ]; then
          chage -d 0 "$user" 2>/dev/null && touch "$state"
        fi
      done
    '';
  };

  security.sudo.wheelNeedsPassword = true;

  # ── Display — Regolith-style i3 desktop ──────────────────────────────────────
  services.xserver = {
    enable = true;

    # LightDM with Arc-Dark GTK greeter (matches Regolith's lightdm config)
    displayManager.lightdm = {
      enable = true;
      greeters.gtk = {
        enable    = true;
        theme     = { name = "Arc-Dark";  package = pkgs.arc-theme;      };
        iconTheme = { name = "Arc";       package = pkgs.arc-icon-theme; };
        cursorTheme.name = "Adwaita";
        extraConfig = ''
          font-name=Noto Sans 11
          xft-antialias=true
          xft-hintstyle=hintslight
          xft-rgba=rgb
        '';
      };
    };

    # i3 window manager — includes gap support since i3 4.20
    windowManager.i3.enable = true;
  };

  # Set i3 as the default session
  services.displayManager.defaultSession = "none+i3";

  # ── Polkit (for privileged GUI operations) ───────────────────────────────────
  security.polkit.enable = true;

  # ── Audio — PipeWire (modern replacement for PulseAudio) ────────────────────
  services.pipewire = {
    enable       = true;
    alsa.enable  = true;
    pulse.enable = true;
  };
  hardware.pulseaudio.enable = false;
  security.rtkit.enable      = true;

  # ── Fonts ─────────────────────────────────────────────────────────────────────
  # MesloLGS Nerd Font is what Regolith uses for the status bar and terminal.
  # NixOS 24.11+ uses nerd-fonts.<name>; for older nixpkgs use:
  #   (nerdfonts.override { fonts = [ "Meslo" "DejaVuSansMono" ]; })
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.meslo-lg           # MesloLGS Nerd Font — bar & terminal
      nerd-fonts.dejavu-sans-mono   # DejaVu Sans Mono Nerd Font
      noto-fonts
      noto-fonts-emoji
      dejavu_fonts
    ];
    fontconfig.defaultFonts = {
      monospace = [ "MesloLGS Nerd Font Mono" "DejaVu Sans Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif     = [ "Noto Serif" ];
    };
  };

  # Needed for GTK apps to read dconf settings (theme, icon theme, fonts)
  programs.dconf.enable = true;

  # ── System Packages ───────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # ── WM tooling ──────────────────────────────────────────────────────────────
    i3blocks              # status bar (replaces i3xrocks; same i3blocks protocol)
    rofi                  # app launcher (replaces ilia — not packaged in nixpkgs)
    picom                 # compositor  (replaces picom-glx)
    feh                   # wallpaper setter
    unclutter-xfixes      # hide idle mouse pointer (regolith-unclutter-xfixes)
    dunst                 # notifications (replaces rofication)
    libnotify             # notify-send
    xdotool               # window manipulation (used for kill keybinding)
    xdg-utils             # xdg-open, xdg-settings
    xss-lock              # auto-lock on screen blank / suspend

    # ── GTK theming ─────────────────────────────────────────────────────────────
    arc-theme             # Arc-Dark GTK theme (close to SolArc-Dark)
    arc-icon-theme        # Arc icon theme
    lxappearance          # GUI theme switcher (handy for adjustments)

    # ── Polkit authentication agent ──────────────────────────────────────────────
    polkit_gnome          # GNOME polkit agent — same as regolith-session-flashback uses

    # ── Terminal & file manager ──────────────────────────────────────────────────
    alacritty             # terminal (MesloLGS Nerd Font configured in home.nix)
    nautilus              # file manager ($mod+Shift+n)

    # ── System tray ─────────────────────────────────────────────────────────────
    networkmanagerapplet  # nm-applet — wifi/vpn tray icon

    # ── Media / hardware ────────────────────────────────────────────────────────
    brightnessctl         # screen brightness (XF86MonBrightness*)
    pamixer               # PulseAudio/PipeWire CLI (XF86Audio*)
    playerctl             # media player control (XF86AudioPlay/Next/Prev)

    # ── Screenshots ─────────────────────────────────────────────────────────────
    scrot                 # screenshot tool (Print key)
    xclip                 # clipboard integration

    # ── Essentials ──────────────────────────────────────────────────────────────
    git curl wget htop xorg.xsetroot
  ];

  # ── Hardware ──────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;   # required by hardware.enableAllFirmware
  hardware.enableAllFirmware  = true;

  # ── Home Manager (user dotfiles: i3 config, picom, dunst, GTK, alacritty…) ───
  # After adding the home-manager channel (step 2), uncomment this block:
  # home-manager = {
  #   useGlobalPkgs   = true;  # use system pkgs in home.nix
  #   useUserPackages = true;  # install user packages into profile
  #   users.rajivg    = import ./home-config/home-rajivg.nix;
  #   users.rishir    = import ./home-config/home-rishir.nix;
  # };

  system.stateVersion = "24.11";
}
