# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
    imports =
        [ # Include the results of the hardware scan.
        ./hardware-configuration.nix
    ];

    # Bootloader.
    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
    boot.loader.grub.useOSProber = true;

    # Setup keyfile
    boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
};

# Enable grub cryptodisk
boot.loader.grub.enableCryptodisk=true;

boot.initrd.luks.devices."luks-1003d289-d93e-4308-b502-45c484f90f90".keyFile = "/crypto_keyfile.bin";
networking.hostName = "nixos"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

# Configure network proxy if necessary
# networking.proxy.default = "http://user:password@proxy:port/";
# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

# Enable networking
networking.networkmanager.enable = true;

# Set your time zone.
time.timeZone = "Europe/Lisbon";

# Select internationalisation properties.
i18n.defaultLocale = "pt_PT.utf8";

# Enable the X11 windowing system.
services.xserver.enable = true;
services.xserver.windowManager.dwm.enable = true;
services.xserver.displayManager.lightdm.enable = false;
services.xserver.displayManager.startx.enable = true;


#nixpkgs.overlays = [
#	(final: prev: {
#		dwm = prev.dwm.overrideAttrs (old: { src = /home/sorath/.config/suckless/dwm-6.3 ;});
#	})
#];

# Configure keymap in X11
    services.xserver = {
        layout = "pt";
        xkbVariant = "";
};

# Configure console keymap
console.keyMap = "pt-latin1";

# Enable CUPS to print documents.
services.printing.enable = false;

# Enable sound with pipewire.
sound.enable = true;
hardware.pulseaudio.enable = false;
security.rtkit.enable = true;
services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
};

# Enable touchpad support (enabled default in most desktopManager).
services.xserver.libinput.enable = true;

# Define a user account. Don't forget to set a password with ‘passwd’.
users.users.sorath = {
    isNormalUser = true;
    description = "Sorath Panzer";
    extraGroups = [ "networkmanager" "wheel" ];
};

users.extraUsers.sorath = {
    shell = pkgs.zsh;
 };

# Some programs need SUID wrappers, can be configured further or are
# started in user sessions.
# programs.mtr.enable = true;
#programs.gnupg.agent = {
#  enable = true;
#  enableSSHSupport = true;
#};

# List services that you want to enable:

# Enable the OpenSSH daemon.
services.openssh.enable = true;
services.sshd.enable = true;

services.openssh.passwordAuthentication = true;
services.openssh.permitRootLogin = "yes";

# Open ports in the firewall.
# networking.firewall.allowedTCPPorts = [ ... ];
# networking.firewall.allowedUDPPorts = [ ... ];
# Or disable the firewall altogether.
# networking.firewall.enable = false;

#nixpkgs.config.allowUnfree = true;

# Enable NUR
# nixpkgs.config.packageOverrides = pkgs: {
#     nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
#       inherit pkgs;
#   };
# };

# zsh
programs.zsh.enable = true;

# Fonts
fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Hack" ]; })
];

# List packages installed in system profile. To search, run:
# $ nix search wget
environment.systemPackages = with pkgs; [
    btrfs-progs
    dunst
    feh
    ffmpeg
    ffmpegthumbnailer
    flatpak
    fzf
    git
    i3lock
    imagemagick
    light
    lm_sensors
    neovim
    ntfs3g
    picom
    python39Packages.six
    scrot
    stow
    syncthing
    tig
    trash-cli
    udiskie
    unzip
    w3m
    wireguard-tools
    xdotool
#    xorg.libX11
#    xorg.libXft
#    xorg.xauth
#    xorg.xf86inputevdev
#    xorg.xf86inputsynaptics
#    xorg.xf86inputlibinput
#    xorg.xinit
    xorg.xinput
#    xorg.xkbcomp
#    xorg.xorgserver
    xorg.xrandr
    xorg.xrdb
    xorg.xset
    youtube-dl
    zsh
    gnumake
    gcc
    xorg.libXext
    xorg.libXinerama
    xorg.libXrandr
    xorg.xrandr
#    xorg.libXrender
#    river
];

nix = {
    # Hard link identical files in the store automatically
    autoOptimiseStore = true;
    # automatically trigger garbage collection
    gc.automatic = true;
    gc.dates = "weekly";
    gc.options = "--delete-older-than 30d";
};

# This value determines the NixOS release from which the default
# settings for stateful data, like file locations and database versions
# on your system were taken. It‘s perfectly fine and recommended to leavecatenate(variables, "bootdev", bootdev)
# this value at the release version of the first install of this system.
# Before changing this value read the documentation for this option
# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
system.autoUpgrade.enable = true;
system.stateVersion = "22.05"; # Did you read the comment?

}
