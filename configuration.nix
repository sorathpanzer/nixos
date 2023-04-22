{ config, pkgs, ... }:

let

  FLATPAK = true;

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
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
  };

  fileSystems."/media/Bunker" = {
    device = "192.168.1.104:/mnt/Bunker/Vault";
    fsType = "nfs";
    options = [ "noauto" ];
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    swapDevices = 4;
    numDevices = 4;
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
    hostName = "LegionX";
    hostId = "ca1d6250";
    networkmanager.enable = true;
    firewall.enable = true;
    wireguard = {
      enable = true;
    };
    #wg-quick.interfaces.wg0.autostart;
  };

  services = {
    blueman.enable = true;
    getty.autologinUser = "sorath";
    udisks2.enable = true;
        udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="0000", MODE="0600", OWNER="sorath"
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
      windowManager.dwm.enable = true;
      displayManager.lightdm.enable = false;
      displayManager.startx.enable = true;
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
  };

  security.sudo.extraRules= [
    {  users = [ "sorath" ];
      commands = [
        { command = "/run/current-system/sw/bin/reboot,/run/current-system/sw/bin/poweroff,/run/current-system/sw/bin/zpool,/run/current-system/sw/bin/wg,/run/current-system/sw/bin/setleds,/run/current-system/sw/bin/zpool" ;
          options= [ "NOPASSWD" ];
        }
      ];
    }
  ];

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

  users.users.sorath = {
    isNormalUser = true;
    description = "sorath";
    extraGroups = [ "networkmanager" "wheel" "disk" "video" "libvirtd" "docker" "plugdev" "adbusers" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    gcc gnumake btrfs-progs ntfs3g openssh
#    xorg.xinput xorg.xrandr xorg.xf86videointel xorg.xrdb xorg.xset xdotool i3lock mpv ffmpegthumbnailer dmenu ueberzug feh imv
    dunst ffmpeg fzf git groff imagemagick file sanoid zip clamav killall lf light lm_sensors ncdu neovim pandoc poppler_utils
    scrot sox stow syncthing tig trash-cli udiskie unzip usbutils w3m xdg-user-dirs jq yt-dlp zathura pulseaudio bzip2
    firefox popcorntime keepassxc libreoffice-still tdesktop fragments signal-desktop
    python310Packages.adblock python39Packages.pip python39Packages.six qutebrowser
    appimage-run android-udev-rules android-file-transfer android-tools
    qemu virt-manager docker-compose spice libvirt bridge-utils
    foot wayland-protocols hyprpaper waybar ydotool tofi alacritty wl-clipboard grim swaybg mpvpaper libsForQt5.pix
    wineWowPackages.stable wineWowPackages.waylandFull wget (wine.override { wineBuild = "wine64"; })
#   (pkgs.st.overrideAttrs (oldAttrs: {
#      name = "st";
#      src = /home/sorath/.config/suckless/st-0.9;
#    }))
#    (pkgs.dwmblocks.overrideAttrs (oldAttrs: {
#      name = "dwmblocks";
#      src = /home/sorath/.config/suckless/dwmblocks;
#    }))
#    (pkgs.sxiv.overrideAttrs (oldAttrs: {
#      name = "sxiv";
#      src = /home/sorath/.config/suckless/sxiv;
#    }))
  ];

  nixpkgs = {
    #config.allowUnfree = true;
    config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
    overlays = [
      (self: super: {
        dwm = super.dwm.overrideAttrs (old: { src = /home/sorath/.config/suckless/dwm-6.4 ;});
        waybar = super.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];
  };

# Fonts
  fonts.fonts = with pkgs; [
    fira-code
    fira
    jetbrains-mono
    fira-code-symbols
    powerline-fonts
    nerdfonts
  ];

  programs = {
    xwayland.enable = false;
    adb.enable = true;
    light.enable = true;
    waybar.enable = true;
  };

  sound.enable = true;
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "pt_PT.utf8";
  console.keyMap = "pt-latin1";

  xdg.portal = {
    enable = true;
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
      dates = "weekly";
    };
    stateVersion = "22.11";
  };
}
