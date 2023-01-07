{ config, pkgs, ... }:

{
imports = [ ./hardware-configuration.nix ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_level=3" ];
    initrd.secrets = { "/crypto_keyfile.bin" = null; };
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

  networking = {
    hostName = "VirtualX";
    hostId = "HOSTID";
    networkmanager.enable = true;
    firewall.enable = true;
    wireguard = {
      enable = true;
    };
    #wg-quick.interfaces.wg0.autostart;
  };

  services = {
    getty.autologinUser = "sorath";
    syncthing.enable = true;
    flatpak.enable = true;
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

  users.users.sorath = {
    isNormalUser = true;
    description = "sorath";
    extraGroups = [ "networkmanager" "wheel" "disk" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
     android-tools btrfs-progs dunst feh ffmpeg ffmpegthumbnailer file firefox fzf gcc git gnumake groff i3lock imagemagick
     keepassxc killall lf light lm_sensors libreoffice-still mpv ncdu neovim ntfs3g pandoc picom poppler_utils qemu
     python310Packages.adblock python39Packages.pip python39Packages.six qutebrowser scrot sox stow syncthing tdesktop
     tig trash-cli udiskie ueberzug unzip usbutils w3m xclip xdg-user-dirs xdotool xorg.xf86videointel xorg.xinput xorg.xrandr
     xorg.xrdb xorg.xset youtube-dl zathura
   (pkgs.st.overrideAttrs (oldAttrs: {
      name = "st";
      src = /home/sorath/.config/suckless/st-0.9;
    }))
    (pkgs.dwmblocks.overrideAttrs (oldAttrs: {
      name = "dwmblocks";
      src = /home/sorath/.config/suckless/dwmblocks;
    }))
    (pkgs.sxiv.overrideAttrs (oldAttrs: {
      name = "sxiv";
      src = /home/sorath/.config/suckless/sxiv;
    }))
    (pkgs.dmenu.overrideAttrs (oldAttrs: {
      name = "dmenu";
      src = /home/sorath/.config/suckless/dmenu-5.2;
    }))
  ];

  nixpkgs.overlays = [
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: { src = /home/sorath/.config/suckless/dwm-6.4 ;});
    })
  ];

  programs.adb.enable = true;
  programs.light.enable = true;
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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
    gc.options = "--delete-older-than 30d";
  };

  system = {
    autoUpgrade = {
      enable = true;
      dates = "weekly";
    };
    stateVersion = "22.11";
  };
}
