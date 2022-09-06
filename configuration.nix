{ config, pkgs, ... }:

{
imports =
    [
        ./hardware-configuration.nix
    ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
      splashImage = null;
      #enableCryptodisk = true;
    };
    #initrd {
    #  luks.devices."luks-".keyfile = "/crypto_keyfile.bin";
    #  secrets = {
    #   "crypto_keyfile.bin = null;
    #  };
    #};
  };

  networking = {
    hostName = "VirtualX";
    networkmanager.enable = true;
  };

  services = {
    syncthing.enable = true;
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
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
     btrfs-progs dunst feh ffmpeg ffmpegthumbnailer fzf git i3lock imagemagick light lm_sensors
     neovim ntfs3g picom python39Packages.six scrot stow syncthing tig trash-cli udiskie unzip
     w3m wireguard-tools xdotool youtube-dl gnumake gcc python39Packages.pip xclip ueberzug
     python39Packages.adblock lf
   (pkgs.st.overrideAttrs (oldAttrs: {
      name = "st";
      src = /home/sorath/.config/suckless/st-0.8.5;
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
      src = /home/sorath/.config/suckless/dmenu-5.1;
    }))
  ];

  nixpkgs.overlays = [
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: { src = /home/sorath/.config/suckless/dwm-6.3 ;});
    })
  ];

  programs.adb.enable = true;
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "pt_PT.utf8";
  console.keyMap = "pt-latin1";

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 30d";
  };

  system = {
    autoUpgrade = {
      enable = true;
      dates = "weekly";
    };
    stateVersion = "22.05";
  };
}
