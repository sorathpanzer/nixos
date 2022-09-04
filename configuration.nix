{ config, pkgs, ... }:

{
imports =
    [ 
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    splashImage = null;
    #enableCryptodisk = true;
  };
  
  #boot.initrd.luks.devices."luks-".keyfile = "/crypto_keyfile.bin";
  #boot.initrd.secrets = {
  #  "crypto_keyfile.bin = null;
  #};

  # Networking
  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "pt_PT.utf8";
  console.keyMap = "pt-latin1";
  services.xserver.layout = "pt";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sorath = {
    isNormalUser = true;
    description = "sorath";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
     btrfs-progs dunst feh ffmpeg ffmpegthumbnailer fzf git i3lock imagemagick light lm_sensors
     neovim ntfs3g picom python39Packages.six scrot stow syncthing tig trash-cli udiskie unzip
     w3m wireguard-tools xdotool youtube-dl gnumake gcc python39Packages.pip xclip
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

  services.xserver = {
    enable = true;
    windowManager.dwm.enable = true;
    displayManager.lightdm.enable = false;
    displayManager.startx.enable = true;
  };

  system.stateVersion = "22.05"; # Did you read the comment?

}
