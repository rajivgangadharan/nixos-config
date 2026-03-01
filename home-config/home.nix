# =============================================================================
# Home Manager — shared Regolith 3.x desktop module
#
# Generic module: does NOT set home.username / home.homeDirectory.
# Import this from a per-user wrapper (home-rajivg.nix, home-rishir.nix …)
# that sets those identity fields.
#
# Manages: i3 config, i3blocks, picom, dunst, rofi, GTK theme,
#          Xresources (Solarized Dark), alacritty
# =============================================================================
{ config, pkgs, lib, ... }:

let
  # ── Solarized Dark colour palette ────────────────────────────────────────────
  # (matches /usr/share/regolith-look/solarized-dark/root exactly)
  base03  = "#002b36";
  base02  = "#073642";
  base01  = "#586e75";
  base00  = "#657b83";
  base0   = "#839496";
  base1   = "#93a1a1";
  base2   = "#eee8d5";
  base3   = "#fdf6e3";
  yellow  = "#b58900";
  orange  = "#cb4b16";
  red     = "#dc322f";
  magenta = "#d33682";
  violet  = "#6c71c4";
  blue    = "#268bd2";
  cyan    = "#2aa198";
  green   = "#859900";

  # Polkit agent Nix store path (GNOME — same agent used by regolith-session-flashback)
  polkitAgent = "${pkgs.polkit_gnome}/lib/polkit-gnome/polkit-gnome-authentication-agent-1";

in {
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    arandr        # display layout GUI
    pavucontrol   # audio control GUI
  ];

  # ── i3 window manager ────────────────────────────────────────────────────────
  xsession.enable = true;
  xsession.windowManager.i3 = {
    enable  = true;
    package = pkgs.i3;

    config = {
      modifier = "Mod4"; # Super key — same as Regolith wm.mod

      fonts = {
        names = [ "MesloLGS Nerd Font" "MesloLGS Nerd Font Mono" ];
        size  = 12.0;
      };

      # ── Window colours (Solarized Dark — matches wm Xresource file) ────────────
      colors = {
        background = base03;
        focused = {
          border      = base03;
          background  = base01;
          text        = base3;
          indicator   = blue;
          childBorder = base01;
        };
        focusedInactive = {
          border      = base03;
          background  = base02;
          text        = base0;
          indicator   = base02;
          childBorder = base03;
        };
        unfocused = {
          border      = base03;
          background  = base02;
          text        = base0;
          indicator   = base02;
          childBorder = base03;
        };
        urgent = {
          border      = base03;
          background  = red;
          text        = base3;
          indicator   = red;
          childBorder = base03;
        };
        placeholder = {
          border      = base03;
          background  = base02;
          text        = base0;
          indicator   = base03;
          childBorder = base03;
        };
      };

      # ── Gaps (matches i3wm_gaps_inner/outer_size Xresource) ─────────────────────
      gaps = {
        inner       = 5;
        outer       = 0;
        smartGaps   = true;
        smartBorders = "on";
      };

      # ── Borders ──────────────────────────────────────────────────────────────────
      window = {
        border          = 1;
        titlebar        = false;
        hideEdgeBorders = "smart";
        commands = [
          # Work-around for i3 bug #5149 (force pixel border on all windows)
          { criteria = { class = ".*"; }; command = "border pixel 1"; }
          # GTK file-chooser and control-center panels float
          { criteria = { class = "Lxappearance"; }; command = "floating enable"; }
          { criteria = { class = "Arandr"; };       command = "floating enable"; }
          { criteria = { class = "Pavucontrol"; };  command = "floating enable"; }
        ];
      };
      floating = {
        border   = 1;
        titlebar = false;
      };

      focus = {
        followMouse   = false;
        mouseWarping  = false;
        newWindow     = "smart";
      };

      # ── Status bar (i3bar + i3blocks, hidden, shows on $mod) ──────────────────
      # Mirrors: wm.bar.mode = hide, position = bottom, font = MesloLGS Nerd Font 12
      bars = [{
        position    = "bottom";
        mode        = "hide";        # auto-hide — press Super to reveal
        hiddenState = "hide";
        modifier    = "Mod4";
        fonts = {
          names = [ "MesloLGS Nerd Font Mono" "MesloLGS Nerd Font" ];
          size  = 12.0;
        };
        # i3blocks reads ~/.config/i3/i3blocks.conf
        statusCommand  = "i3blocks -c ${config.xdg.configHome}/i3/i3blocks.conf";
        trayOutput     = "primary";
        separator      = " ";
        workspaceNumbers = false; # strip numbers — workspace names only
        extraConfig = "workspace_min_width 36";
        colors = {
          background        = base03;
          statusline        = base1;
          separator         = blue;
          focusedWorkspace  = { border = base02; background = base02; text = base2;  };
          activeWorkspace   = { border = base02; background = base02; text = base00; };
          inactiveWorkspace = { border = base03; background = base03; text = base00; };
          urgentWorkspace   = { border = red;    background = red;    text = base3;  };
        };
      }];

      # ── Keybindings (mirrors all Regolith common + i3 config.d partials) ────────
      keybindings =
        let
          mod = "Mod4";
          alt = "Mod1";
        in {
          # ── Launchers (15_base_launchers + 20_ilia) ──────────────────────────────
          # $mod+Return = terminal  (regolith: x-terminal-emulator → alacritty here)
          "${mod}+Return"           = "exec --no-startup-id alacritty";
          # $mod+Shift+Return = browser
          "${mod}+Shift+Return"     = "exec --no-startup-id xdg-open about:blank";
          # $mod+Space = app launcher  (regolith: ilia -p apps → rofi -show drun)
          "${mod}+space"            = "exec --no-startup-id rofi -show drun";
          # $mod+Shift+Space = run command  (regolith: ilia -p terminal)
          "${mod}+Shift+space"      = "exec --no-startup-id rofi -show run";
          # $mod+Ctrl+Space = window switcher  (regolith: ilia -p windows)
          "${mod}+ctrl+space"       = "exec --no-startup-id rofi -show window";
          # $mod+Alt+Space = file search  (regolith: ilia -p tracker)
          "${mod}+${alt}+space"     = "exec --no-startup-id rofi -show filebrowser";

          # ── Navigation (30_navigation) ───────────────────────────────────────────
          "${mod}+h"               = "focus left";
          "${mod}+j"               = "focus down";
          "${mod}+k"               = "focus up";
          "${mod}+l"               = "focus right";
          "${mod}+Left"            = "focus left";
          "${mod}+Down"            = "focus down";
          "${mod}+Up"              = "focus up";
          "${mod}+Right"           = "focus right";
          "${mod}+a"               = "focus parent";
          "${mod}+z"               = "focus child";
          "${mod}+Tab"             = "workspace next";
          "${mod}+Shift+Tab"       = "workspace prev";
          "${mod}+${alt}+Right"    = "workspace next";
          "${mod}+${alt}+Left"     = "workspace prev";
          "${mod}+ctrl+Tab"        = "workspace next_on_output";
          "${mod}+ctrl+Shift+Tab"  = "workspace prev_on_output";
          # Scratchpad
          "${mod}+ctrl+a"          = "scratchpad show";
          "${mod}+ctrl+m"          = "move to scratchpad";
          # focus last is not a built-in i3 command; bind removed to avoid parse error.
          # Re-enable with a helper like i3-cycle-focus if needed.

          # ── Move windows (40_workspace-config) ───────────────────────────────────
          "${mod}+Shift+h"         = "move left";
          "${mod}+Shift+j"         = "move down";
          "${mod}+Shift+k"         = "move up";
          "${mod}+Shift+l"         = "move right";
          "${mod}+Shift+Left"      = "move left";
          "${mod}+Shift+Down"      = "move down";
          "${mod}+Shift+Up"        = "move up";
          "${mod}+Shift+Right"     = "move right";
          # Move workspace to output
          "${mod}+ctrl+Shift+Left"  = "move workspace to output left";
          "${mod}+ctrl+Shift+Right" = "move workspace to output right";
          "${mod}+ctrl+Shift+Up"    = "move workspace to output up";
          "${mod}+ctrl+Shift+Down"  = "move workspace to output down";
          "${mod}+ctrl+Shift+h"     = "move workspace to output left";
          "${mod}+ctrl+Shift+l"     = "move workspace to output right";
          "${mod}+ctrl+Shift+k"     = "move workspace to output up";
          "${mod}+ctrl+Shift+j"     = "move workspace to output down";

          # ── Layout / orientation ──────────────────────────────────────────────────
          "${mod}+v"               = "split vertical";
          "${mod}+g"               = "split horizontal";
          "${mod}+BackSpace"       = "split toggle";
          "${mod}+f"               = "fullscreen toggle";
          "${mod}+Shift+f"         = "floating toggle";
          "${mod}+Shift+t"         = "focus mode_toggle";
          "${mod}+t"               = "layout toggle tabbed splith splitv";

          # ── Workspaces 1–10 ───────────────────────────────────────────────────────
          "${mod}+1"               = "workspace number 1";
          "${mod}+2"               = "workspace number 2";
          "${mod}+3"               = "workspace number 3";
          "${mod}+4"               = "workspace number 4";
          "${mod}+5"               = "workspace number 5";
          "${mod}+6"               = "workspace number 6";
          "${mod}+7"               = "workspace number 7";
          "${mod}+8"               = "workspace number 8";
          "${mod}+9"               = "workspace number 9";
          "${mod}+0"               = "workspace number 10";
          # Move container to workspace
          "${mod}+Shift+1"         = "move container to workspace number 1";
          "${mod}+Shift+2"         = "move container to workspace number 2";
          "${mod}+Shift+3"         = "move container to workspace number 3";
          "${mod}+Shift+4"         = "move container to workspace number 4";
          "${mod}+Shift+5"         = "move container to workspace number 5";
          "${mod}+Shift+6"         = "move container to workspace number 6";
          "${mod}+Shift+7"         = "move container to workspace number 7";
          "${mod}+Shift+8"         = "move container to workspace number 8";
          "${mod}+Shift+9"         = "move container to workspace number 9";
          "${mod}+Shift+0"         = "move container to workspace number 10";

          # ── Gaps (35_gaps) ────────────────────────────────────────────────────────
          "${mod}+plus"            = "gaps inner current plus 6";
          "${mod}+minus"           = "gaps inner current minus 6";
          "${mod}+Shift+plus"      = "gaps inner current plus 12";
          "${mod}+Shift+minus"     = "gaps inner current minus 12";

          # ── Session (55_session_keybindings) ─────────────────────────────────────
          "${mod}+Shift+q"         = "[con_id=\"__focused__\"] kill";
          "${mod}+${alt}+q"        = "[con_id=\"__focused__\"] exec --no-startup-id kill -9 $(xdotool getwindowfocus getwindowpid)";
          "${mod}+Shift+c"         = "reload";
          "${mod}+ctrl+r"          = "restart";
          "${mod}+Shift+r"         = "exec --no-startup-id i3-msg restart";
          # Logout / reboot / shutdown (standalone i3 — no gnome-session-quit)
          "${mod}+Shift+e"         = "exec --no-startup-id i3-nagbar -t warning -m 'Exit i3? This will end your X session.' -B 'Yes, exit' 'i3-msg exit'";
          "${mod}+Shift+b"         = "exec --no-startup-id systemctl reboot";
          "${mod}+Shift+p"         = "exec --no-startup-id systemctl poweroff";
          "${mod}+Shift+s"         = "exec --no-startup-id systemctl suspend";
          # Lock screen — solid Solarized Dark base03
          "${mod}+Escape"          = "exec --no-startup-id i3lock-color -c 002b36 --inside-color=073642ff --ring-color=268bd2ff --line-color=002b36ff --keyhl-color=2aa198ff --bshl-color=dc322fff";

          # ── System / config (60_config_keybindings) ──────────────────────────────
          "${mod}+i"               = "bar mode toggle";
          "${mod}+Shift+n"         = "exec --no-startup-id nautilus --new-window";
          # Settings — use gnome-control-center (or replace with your preferred settings app)
          "${mod}+c"               = "exec --no-startup-id env XDG_CURRENT_DESKTOP=GNOME gnome-control-center";
          "${mod}+d"               = "exec --no-startup-id env XDG_CURRENT_DESKTOP=GNOME gnome-control-center display";
          "${mod}+w"               = "exec --no-startup-id env XDG_CURRENT_DESKTOP=GNOME gnome-control-center wifi";
          "${mod}+b"               = "exec --no-startup-id env XDG_CURRENT_DESKTOP=GNOME gnome-control-center bluetooth";

          # ── Resize mode ───────────────────────────────────────────────────────────
          "${mod}+r"               = "mode \"Resize Mode\"";

          # ── Hardware / media keys ─────────────────────────────────────────────────
          "XF86AudioRaiseVolume"   = "exec --no-startup-id pamixer -i 5 && notify-send -t 1000 -h string:x-dunst-stack-tag:vol ' Volume' \"$(pamixer --get-volume)%\"";
          "XF86AudioLowerVolume"   = "exec --no-startup-id pamixer -d 5 && notify-send -t 1000 -h string:x-dunst-stack-tag:vol ' Volume' \"$(pamixer --get-volume)%\"";
          "XF86AudioMute"          = "exec --no-startup-id pamixer -t && notify-send -t 1000 -h string:x-dunst-stack-tag:vol ' Mute' \"$(pamixer --get-mute)\"";
          "XF86MonBrightnessUp"    = "exec --no-startup-id brightnessctl set +10% && notify-send -t 800 -h string:x-dunst-stack-tag:bright ' Brightness' \"$(brightnessctl get)\"";
          "XF86MonBrightnessDown"  = "exec --no-startup-id brightnessctl set 10%- && notify-send -t 800 -h string:x-dunst-stack-tag:bright ' Brightness' \"$(brightnessctl get)\"";
          "XF86AudioPlay"          = "exec --no-startup-id playerctl play-pause";
          "XF86AudioNext"          = "exec --no-startup-id playerctl next";
          "XF86AudioPrev"          = "exec --no-startup-id playerctl previous";

          # ── Screenshots ───────────────────────────────────────────────────────────
          "Print"                  = "exec --no-startup-id mkdir -p ~/Pictures && scrot '%Y-%m-%d_%H-%M-%S.png' -e 'mv $f ~/Pictures/ && notify-send -t 2000 \" Screenshot\" \"Saved to ~/Pictures\"'";
          "Shift+Print"            = "exec --no-startup-id mkdir -p ~/Pictures && scrot -s '%Y-%m-%d_%H-%M-%S.png' -e 'mv $f ~/Pictures/ && notify-send -t 2000 \" Screenshot\" \"Saved to ~/Pictures\"'";
        };

      # ── Resize mode (mirrors 50_resize-mode) ────────────────────────────────────
      modes."Resize Mode" = {
        h          = "resize shrink width 6 px or 6 ppt";
        j          = "resize grow height 6 px or 6 ppt";
        k          = "resize shrink height 6 px or 6 ppt";
        l          = "resize grow width 6 px or 6 ppt";
        Left       = "resize shrink width 6 px or 6 ppt";
        Down       = "resize grow height 6 px or 6 ppt";
        Up         = "resize shrink height 6 px or 6 ppt";
        Right      = "resize grow width 6 px or 6 ppt";
        # Large resize (Shift)
        "Shift+h"  = "resize shrink width 24 px or 24 ppt";
        "Shift+j"  = "resize grow height 24 px or 24 ppt";
        "Shift+k"  = "resize shrink height 24 px or 24 ppt";
        "Shift+l"  = "resize grow width 24 px or 24 ppt";
        Return     = "mode \"default\"";
        Escape     = "mode \"default\"";
        "Mod4+r"   = "mode \"default\"";
      };

      # ── Startup applications ──────────────────────────────────────────────────────
      startup = [
        # Wallpaper — re-apply on every i3 reload (always = true is intentional here)
        # Replace with: feh --bg-scale /path/to/wallpaper.jpg  then remove the xsetroot line
        { command = "xsetroot -solid '#002b36'"; always = true;  notification = false; }

        # Daemons — always = false: do NOT respawn on i3 reload/restart,
        # which would leave multiple instances running.

        # Compositor (picom) — GLX backend with shadows + fading
        # Config written to ~/.config/picom/picom.conf below
        { command = "picom --daemon";                                                        always = false; notification = false; }

        # Polkit authentication agent (same as regolith-session-flashback)
        { command = polkitAgent;                                                             always = false; notification = false; }

        # Network Manager tray applet
        { command = "nm-applet --indicator";                                                 always = false; notification = false; }

        # Hide mouse after 5 seconds of idle (regolith-unclutter-xfixes)
        { command = "unclutter -idle 5 -root";                                               always = false; notification = false; }

        # Notification daemon (replaces rofication-daemon)
        { command = "dunst";                                                                 always = false; notification = false; }

        # Lock screen on suspend / lid close
        { command = "xss-lock --transfer-sleep-lock -- i3lock-color -c 002b36 --nofork";    always = false; notification = false; }
      ];
    };

    # Extra config not covered by the HM module
    extraConfig = ''
      # Enable popup during fullscreen
      popup_during_fullscreen smart

      # Workspace assignments (add your own below)
      # assign [class="Firefox"] number 2
      # assign [class="Slack"] number 3
    '';
  };

  # ── picom compositor config ───────────────────────────────────────────────────
  # Mirrors /etc/regolith/picom/config (regolith-compositor-picom-glx)
  xdg.configFile."picom/picom.conf".text = ''
    # Backend — GLX (same as Regolith)
    backend = "glx";
    glx-no-stencil = true;
    glx-no-rebind-pixmap = true;
    use-damage = true;
    xrender-sync-fence = true;
    glx-copy-from-front = false;

    # Shadows
    shadow = true;
    shadow-radius = 7;
    shadow-offset-x = -7;
    shadow-offset-y = -7;
    shadow-opacity = 0.6;
    shadow-exclude = [
      "name = 'Notification'",
      "class_g = 'i3bar'",
      "class_g = 'i3-frame'",
      "_GTK_FRAME_EXTENTS@:c",
      "window_type = 'tooltip'",
      "window_type = 'dock'",
    ];

    # Fading (smooth window open/close)
    fading = true;
    fade-in-step  = 0.05;
    fade-out-step = 0.05;
    fade-exclude  = [];

    # Transparency
    inactive-opacity          = 0.95;
    active-opacity            = 1.0;
    frame-opacity             = 1.0;
    inactive-opacity-override = false;

    # Misc
    mark-wmwin-focused     = true;
    mark-ovredir-focused   = true;
    detect-rounded-corners = true;
    detect-client-opacity  = true;
    detect-transient       = true;
  '';

  # ── dunst notification daemon ─────────────────────────────────────────────────
  # Styled to match Solarized Dark (replaces regolith-rofication)
  xdg.configFile."dunst/dunstrc".text = ''
    [global]
        font              = MesloLGS Nerd Font 11
        markup            = full
        format            = "<b>%s</b>\n%b"
        sort              = yes
        indicate_hidden   = yes
        alignment         = left
        show_age_threshold = 60
        word_wrap         = yes
        ignore_newline    = no
        width             = 350
        height            = 300
        origin            = top-right
        offset            = 12x42
        transparency      = 8
        idle_threshold    = 120
        monitor           = 0
        follow            = mouse
        sticky_history    = yes
        history_length    = 20
        show_indicators   = yes
        line_height       = 0
        separator_height  = 2
        padding           = 10
        horizontal_padding = 12
        separator_color   = frame
        startup_notification = false
        corner_radius     = 0
        frame_width       = 1

    [urgency_low]
        background  = "${base02}"
        foreground  = "${base1}"
        frame_color = "${base03}"
        timeout     = 5

    [urgency_normal]
        background  = "${base02}"
        foreground  = "${base1}"
        frame_color = "${blue}"
        timeout     = 10

    [urgency_critical]
        background  = "${red}"
        foreground  = "${base3}"
        frame_color = "${base03}"
        timeout     = 0
  '';

  # ── i3blocks status bar config ────────────────────────────────────────────────
  # Blocks: net-traffic · cpu-usage · time  (mirrors i3xrocks conf.d order)
  # Uses Nerd Font glyphs from MesloLGS Nerd Font
  xdg.configFile."i3/i3blocks.conf".text = ''
    # ── Global defaults ──────────────────────────────────────────────────────────
    separator_block_width=25
    markup=pango
    color=${base00}

    # ── Network traffic ── (mirrors 30_net-traffic)
    [net-traffic]
    command=${config.xdg.configHome}/i3/blocks/net-traffic
    interval=3
    markup=pango

    # ── CPU usage ── (mirrors 40_cpu-usage)
    [cpu-usage]
    command=${config.xdg.configHome}/i3/blocks/cpu-usage
    interval=3
    min_width=CPU 100%
    markup=pango

    # ── Date/Time ── (mirrors 90_time)
    [time]
    command=date '+<span foreground="${base0}"> </span><span foreground="${base00}">%b %d %H:%M</span>'
    interval=10
    markup=pango
  '';

  # ── i3blocks scripts ─────────────────────────────────────────────────────────
  # net-traffic: shows per-second download/upload rate using a state file
  xdg.configFile."i3/blocks/net-traffic" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      IFACE=$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')
      if [ -z "$IFACE" ]; then
        printf '<span foreground="${base0}"> </span><span foreground="${base00}">no net</span>\n'
        exit 0
      fi

      STATE="/tmp/.i3blk-net-$IFACE"
      NOW=$(date +%s)
      RX=$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
      TX=$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes 2>/dev/null || echo 0)

      if [ -f "$STATE" ]; then
        read -r PREV_TIME PREV_RX PREV_TX < "$STATE"
        DELTA=$(( NOW - PREV_TIME ))
        if [ "$DELTA" -gt 0 ]; then
          RX_K=$(( (RX - PREV_RX) / DELTA / 1024 ))
          TX_K=$(( (TX - PREV_TX) / DELTA / 1024 ))
          printf '<span foreground="${base0}"> </span><span foreground="${base00}">↓%dK ↑%dK</span>\n' "$RX_K" "$TX_K"
        fi
      else
        printf '<span foreground="${base0}"> </span><span foreground="${base00}">…</span>\n'
      fi

      printf '%s %s %s\n' "$NOW" "$RX" "$TX" > "$STATE"
    '';
  };

  # cpu-usage: percentage from /proc/stat using a state file (no sleep needed)
  xdg.configFile."i3/blocks/cpu-usage" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      STATE="/tmp/.i3blk-cpu"

      # Read current cpu stats: cpu user nice system idle ...
      read -r _ u n s i _ < /proc/stat

      if [ -f "$STATE" ]; then
        read -r pu pn ps pi < "$STATE"
        USED=$(( (u + n + s) - (pu + pn + ps) ))
        IDLE=$(( i - pi ))
        TOTAL=$(( USED + IDLE ))
        if [ "$TOTAL" -gt 0 ]; then
          PCT=$(( USED * 100 / TOTAL ))
          # Colour: green < 50%, yellow < 80%, red >= 80%
          if   [ "$PCT" -ge 80 ]; then COL="${red}";
          elif [ "$PCT" -ge 50 ]; then COL="${yellow}";
          else                         COL="${base00}";
          fi
          printf '<span foreground="${base0}"> </span><span foreground="%s">%d%%</span>\n' "$COL" "$PCT"
        fi
      else
        printf '<span foreground="${base0}"> </span><span foreground="${base00}">…</span>\n'
      fi

      printf '%s %s %s %s\n' "$u" "$n" "$s" "$i" > "$STATE"
    '';
  };

  # ── rofi config (replaces ilia launcher) ─────────────────────────────────────
  programs.rofi = {
    enable      = true;
    theme       = "Arc-Dark";
    font        = "MesloLGS Nerd Font 12";
    terminal    = "alacritty";
    extraConfig = {
      modi                 = "drun,run,window,filebrowser";
      show-icons           = true;
      display-drun         = "  Apps";
      display-run          = "  Run";
      display-window       = "  Windows";
      display-filebrowser  = "  Files";
      drun-display-format  = "{name}";
      icon-theme           = "Arc";
    };
  };

  # ── GTK theming ───────────────────────────────────────────────────────────────
  # Arc-Dark is the closest nixpkgs equivalent to SolArc-Dark
  gtk = {
    enable = true;
    theme = {
      name    = "Arc-Dark";
      package = pkgs.arc-theme;
    };
    iconTheme = {
      name    = "Arc";
      package = pkgs.arc-icon-theme;
    };
    font = {
      name = "Noto Sans";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-button-images                 = 0;
      gtk-menu-images                   = 0;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Persist GTK settings across sessions
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme    = "Arc-Dark";
      icon-theme   = "Arc";
      font-name    = "Noto Sans 11";
    };
  };

  # ── Xresources — Solarized Dark palette ──────────────────────────────────────
  # Provides terminal colours for xterm-compatible apps + font/DPI hints
  xresources.properties = {
    # Colours (matches solarized-dark look exactly)
    "*.foreground"   = base1;
    "*.background"   = base03;
    "*.cursorColor"  = base1;
    # Black / DarkGrey
    "*.color0"  = base02;   "*.color8"  = base03;
    # Red / Bright Red
    "*.color1"  = red;      "*.color9"  = orange;
    # Green / Bright Green
    "*.color2"  = green;    "*.color10" = base01;
    # Yellow / Bright Yellow
    "*.color3"  = yellow;   "*.color11" = base00;
    # Blue / Bright Blue
    "*.color4"  = blue;     "*.color12" = base0;
    # Magenta / Bright Magenta
    "*.color5"  = magenta;  "*.color13" = violet;
    # Cyan / Bright Cyan
    "*.color6"  = cyan;     "*.color14" = base1;
    # White / Bright White
    "*.color7"  = base2;    "*.color15" = base3;
    # Font rendering
    "Xft.dpi"       = 96;
    "Xft.antialias" = "true";
    "Xft.hinting"   = "true";
    "Xft.hintstyle" = "hintslight";
    "Xft.rgba"      = "rgb";
  };

  # ── alacritty terminal ────────────────────────────────────────────────────────
  # Solarized Dark colours + MesloLGS Nerd Font (matches Regolith terminal look)
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding    = { x = 10; y = 8; };
        decorations = "none";
        opacity     = 0.97;
      };
      scrolling.history = 10000;
      font = {
        normal = { family = "MesloLGS Nerd Font Mono"; style = "Regular"; };
        bold   = { family = "MesloLGS Nerd Font Mono"; style = "Bold";    };
        italic = { family = "MesloLGS Nerd Font Mono"; style = "Italic";  };
        size   = 12.0;
      };
      colors = {
        primary    = { background = base03; foreground = base1;  };
        cursor     = { text = base03; cursor = base1; };
        normal = {
          black   = base02;  red     = red;
          green   = green;   yellow  = yellow;
          blue    = blue;    magenta = magenta;
          cyan    = cyan;    white   = base2;
        };
        bright = {
          black   = base03;  red     = orange;
          green   = base01;  yellow  = base00;
          blue    = base0;   magenta = violet;
          cyan    = base1;   white   = base3;
        };
      };
    };
  };

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
