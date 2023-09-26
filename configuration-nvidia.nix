{ lib, config, pkgs, ... }:

let

  FLATPAK = true;

    nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';

in
{
imports = [ ./hardware-configuration.nix ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_level=3" ];
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

  fileSystems."/media/Bunker" = {
    device = "192.168.1.105:/mnt/Bunker/Vault";
    fsType = "nfs";
    options = [ "noauto" ];
  };

  #fileSystems."/media/Bunker/Crypta" = {
    #device = "192.168.1.105:/mnt/Bunker/Crypta";
    #fsType = "nfs";
    #options = [ "noauto" ];
  #};

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  hardware = {
    hackrf.enable = true;
    rtl-sdr.enable = true;
    bluetooth.enable = true;
        cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
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
    hostName = "LegionX";
    hostId = "ca1d6250";
    networkmanager.enable = true;
    firewall.enable = true;
    enableIPv6 = false;
    wireguard = {
      enable = true;
    };
    #wg-quick.interfaces.wg0.autostart;
  };

  services = {
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
      videoDrivers =  [ "nvidia" ];
      deviceSection = ''
        Option "DRI" "3"
        Option "TearFree" "true"
      '';
            screenSection = ''
        Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
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
    apparmor.enable = true;
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

  environment = {
    sessionVariables.NIXOS_OZONE_WL = "1";
    variables.VDPAU_DRIVER = lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
    systemPackages = with pkgs; [
      gcc gnumake btrfs-progs ntfs3g openssh arp-scan
      dunst ffmpeg fzf git groff imagemagick file sanoid zip clamav killall lf light lm_sensors ncdu neovim pandoc poppler_utils imv
      scrot sox stow syncthing tig trash-cli udiskie unzip usbutils w3m xdg-user-dirs jq yt-dlp zathura pulseaudio bzip2 mpv bc
      python310Packages.adblock python39Packages.pip python39Packages.six qutebrowser
      appimage-run android-udev-rules android-file-transfer android-tools
      qemu virt-manager docker-compose spice libvirt bridge-utils
      wineWowPackages.waylandFull
      foot wayland-protocols waybar ydotool tofi alacritty wl-clipboard grim swaybg mpvpaper slurp libnotify grim swww wofi
      gthumb brave popcorntime keepassxc libreoffice-still tdesktop fragments signal-desktop logseq ghostscript
      chatgpt-cli vimPlugins.ChatGPT-nvim nvd fluffychat
      nvidia-offload mesa-demos
    ];
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

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

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
