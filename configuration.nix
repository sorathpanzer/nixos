{ config, pkgs, lib,... }:

let

  FLATPAK = true;

  unstable = import
    (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/master)
    # reuse the current configuration
    { config = config.nixpkgs.config; };

in
{
imports = [ ./hardware-configuration.nix ];

  environment = {
    etc = {
    "pam.d/swaylock".text = ''
    auth include login
    '';
	  "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
		bluez_monitor.properties = {
			["bluez5.enable-sbc-xq"] = true,
			["bluez5.enable-msbc"] = true,
			["bluez5.enable-hw-volume"] = true,
			["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
		}
	'';
};
    sessionVariables.NIXOS_OZONE_WL = "1";
    systemPackages = with pkgs; [
      gcc gnumake btrfs-progs ntfs3g openssh arp-scan
      dunst ffmpeg ffmpegthumbnailer fzf git groff imagemagick file sanoid zip clamav killall lf light lm_sensors neovim pandoc poppler_utils imv unar
      scrot sox stow syncthing tig trash-cli udiskie unzip usbutils w3m xdg-user-dirs jq yt-dlp zathura pulseaudio bzip2 mpv bc mediainfo ripgrep lzop
      python310Packages.adblock python39Packages.pip python39Packages.six qutebrowser-qt6 gparted
      appimage-run android-udev-rules android-file-transfer android-tools
      qemu virt-manager docker-compose spice libvirt bridge-utils
      wineWowPackages.waylandFull
      foot wayland-protocols ydotool tofi alacritty wl-clipboard grim mpvpaper slurp libnotify swww
      popcorntime keepassxc libreoffice-still tdesktop fragments signal-desktop logseq ghostscript
      chatgpt-cli vimPlugins.ChatGPT-nvim nvd librewolf
      unstable.hyprland unstable.waybar unstable.yazi dua xfce.tumbler vimiv-qt hyprpicker
      calibre ly swaylock qimgv
      helix nodePackages.bash-language-server marksman lf fd whatsapp-for-linux
    ];
  };

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_level=3" ];
    kernelModules = [ "uinput" ];
    initrd.secrets = { "/crypto_keyfile.bin" = null; };
    initrd.verbose = false;
    extraModprobeConfig = "options kvm_intel nested=1";
    kernel.sysctl = {
      "vm.max_map_count" = "2147483642";
      "vm.swappiness" = "5";
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
  };

  fileSystems."/media/Bunker/Vault" = {
    device = "192.168.1.120:/mnt/Bunker/Vault";
    fsType = "nfs";
    options = [ "noauto" ];
  };

  fileSystems."/media/Bunker/Crypta" = {
    device = "192.168.1.120:/mnt/Bunker/Crypta";
    fsType = "nfs";
    options = [ "noauto" ];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  hardware = {
    hackrf.enable = true;
    rtl-sdr.enable = true;
    bluetooth.enable = true;
    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    hostName = "LegionX";
    hostId = "ca1d6250";
    networkmanager.enable = true;
    networkmanager.dns = "none";
    firewall.enable = true;
    enableIPv6 = false;
    wireguard = {
      enable = true;
    };
    #wg-quick.interfaces.wg0.autostart;
  };

  services = {
    tumbler.enable = true;
    tor.enable = true;
    spice-vdagentd.enable = true;
    dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };
    fwupd.enable = true;
    blueman.enable = true;
    getty.autologinUser = "sorath";
    udisks2.enable = true;
        udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="0000", MODE="0600", OWNER="sorath"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="0003", MODE="0600", OWNER="sorath"
  '';
    syncthing = {
      enable = true;
      user = "sorath";
      configDir = "/home/sorath/.config/syncthing";
    };
    flatpak.enable = FLATPAK;
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    xserver = {
      enable = true;
      displayManager.lightdm.enable = false;
      layout = "pt";
      videoDrivers = [ "intel" ];
      deviceSection = ''
        Option "DRI" "3"
        Option "TearFree" "true"
      '';
      libinput = {
        enable = true;
        touchpad = {
          accelProfile = "adaptive";
          naturalScrolling = true;
          tapping = false;
        };
      };
    };
    cron = {
      enable = true;
      systemCronJobs = [
        "0 14,22,6 * * *      root    flatpak update >> /tmp/cron.log"
      ];
    };
  };

  security = {
    polkit.enable = true;
    #apparmor.enable = true;
    sudo.extraRules= [
      {  users = [ "sorath" ];
        commands = [
          { command = "/run/current-system/sw/bin/reboot,/run/current-system/sw/bin/poweroff,/run/current-system/sw/bin/zpool,/run/current-system/sw/bin/wg,/run/current-system/sw/bin/setleds,/run/current-system/sw/bin/zpool" ;
            options= [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  virtualisation.libvirtd = {
    enable = true;
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  systemd = {
  oomd.enable = false;
  services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };
  user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
  };
   extraConfig = ''
     DefaultTimeoutStopSec=10s
   '';
};

  users.users.sorath = {
    isNormalUser = true;
    description = "sorath";
    extraGroups = [ "networkmanager" "wheel" "disk" "video" "libvirtd" "docker" "plugdev" "adbusers" ];
    shell = pkgs.zsh;
  };

  users.users.marcia = {
    isNormalUser = true;
    description = "marcia";
    extraGroups = [ "networkmanager" "wheel" "disk" "video" "plugdev" ];
    shell = pkgs.zsh;
  };

  programs.steam = {
	  enable = true;
	  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
	  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
	};

  nixpkgs = {
    config.allowUnfree = true;
    #config.permittedInsecurePackages = [
      #"electron-20.3.11"
    #];
    config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
    overlays = [
      (self: super: {
        waybar = super.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];
  };

# Fonts
fonts = {
  fonts = with pkgs; [
    fira-code
    fira
    jetbrains-mono
    fira-code-symbols
    powerline-fonts
    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "Meslo" ]; })
  ];
  fontconfig = {
      enable = true;
      defaultFonts = {
	      monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
	      serif = [ "Noto Serif" "Source Han Serif" ];
	      sansSerif = [ "Noto Sans" "Source Han Sans" ];
      };
    };
};

  programs = {
    hyprland.enable = true;
    xwayland.enable = false;
    hyprland.xwayland.enable = false;
    adb.enable = true;
    light.enable = true;
    waybar.enable = true;
    zsh.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  sound.enable = true;
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "pt_PT.utf8";
  console.keyMap = "pt-latin1";

  nix = {
    settings.auto-optimise-store = true;
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 7d";
    extraOptions = "experimental-features = nix-command flakes";
    package = pkgs.nixFlakes;
  };

  system = {
    copySystemConfiguration = true;
    autoUpgrade = {
      enable = true;
      dates = "daily";
    };
    stateVersion = "23.05";
  };
}
