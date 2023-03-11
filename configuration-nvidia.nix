{ lib, config, pkgs, ... }:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    export __GL_SHOW_GRAPHICS_OSD=1
    exec "$@"
  '';
in

{
imports = [ ./hardware-configuration.nix ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_level=3" "i915" ];
    initrd.secrets = { "/crypto_keyfile.bin" = null; };
    initrd.verbose = false;
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

  environment.variables = {
    VDPAU_DRIVER = lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
  };

  hardware = {
    cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      modesetting.enable = lib.mkDefault true;
      powerManagement.enable = lib.mkDefault true;
      nvidiaPersistenced = true;

      prime = {
        offload.enable = lib.mkOverride 990 true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    opengl.extraPackages = with pkgs; [
      vaapiIntel
      libvdpau-va-gl
      intel-media-driver
    ];
  };

  services = {
    getty.autologinUser = "sorath";
    tlp.enable = lib.mkDefault ((lib.versionOlder (lib.versions.majorMinor lib.version) "22.11")
                                       || !config.services.power-profiles-daemon.enable);
    thermald.enable = lib.mkDefault true;
    hdapsd.enable = lib.mkDefault true;
    syncthing = {
      enable = true;
      user = "sorath";
      configDir = "/home/sorath/.config/syncthing";
    };
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
      videoDrivers = lib.mkDefault [ "nvidia" ];
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
  };

  security.sudo.extraRules= [
    {  users = [ "sorath" ];
      commands = [
        { command = "/run/current-system/sw/bin/reboot,/run/current-system/sw/bin/poweroff,/run/current-system/sw/bin/zpool,/run/current-system/sw/bin/wg,/run/current-system/sw/bin/setleds" ;
          options= [ "NOPASSWD" ];
        }
      ];
    }
  ];

  users.users.sorath = {
    isNormalUser = true;
    description = "sorath";
    extraGroups = [ "networkmanager" "wheel" "disk" "video" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
     android-tools btrfs-progs dunst feh ffmpeg ffmpegthumbnailer file firefox fzf gcc git gnumake groff i3lock imagemagick
     keepassxc killall lf light lm_sensors libreoffice-still mpv ncdu neovim ntfs3g openssh pandoc picom poppler_utils qemu
     python310Packages.adblock python39Packages.pip python39Packages.six qutebrowser scrot sox stow syncthing tdesktop vaapiVdpau
     tig trash-cli udiskie ueberzug unzip usbutils w3m xclip xdg-user-dirs xdotool xorg.xf86videointel xorg.xinput xorg.xrandr jq nvidia-offload mesa-demos
     xorg.xrdb xorg.xset youtube-dl zathura pulseaudio dmenu signal-desktop bzip2 foot wayland-protocols hyprpaper mpvpaper waybar river dwl ydotool
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
  ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (self: super: {
        dwm = super.dwm.overrideAttrs (old: { src = /home/sorath/.config/suckless/dwm-6.4 ;});
        waybar = super.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];
  };

  programs = {
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