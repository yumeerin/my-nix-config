# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 150;
    priority = 100;
  };

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  # FlatPak 
  services.flatpak.enable = true;
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Vim-style hjkl navigation via keyd: only active while RIGHT Alt is held.
  # Right-Alt+h/j/k/l emit the arrow keys; hjkl stay letters.
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          altgr = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };
        };
      };
    };
  };

  # Keep the keyd virtual keyboard treated as internal by libinput, otherwise
  # the touchpad's disable-while-typing interferes with navigation.
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd*
    AttrKeyboardIntegration=internal
  '';

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.yume = {
    isNormalUser = true;
    description = "yume";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
   # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Unity Hub extracts Android SDK/JDK/NDK module zips with the `unzip`
  # command, and its shader-compiler subprocess needs `libtinfo.so.6`;
  # both are missing from its FHS sandbox on NixOS:
  #   - Android setup failed with "Command 'unzip' not found"
  #   - Editor showed "Shader compiler init error: failed to get IPCC"
  #     (UnityShaderCompiler died loading libtinfo.so.6)
  nixpkgs.overlays = [
    (final: prev: {
      unityhub = prev.unityhub.override {
        extraPkgs = pkgs: with pkgs; [ unzip ];
        # libtinfo.so.6 (from ncurses) is added to the sandbox's /usr/lib,
        # but the Hub's FHS loader cache can't be used to resolve it, so the
        # actual fix is the activationScript below symlinking it into each
        # editor. Keep ncurses here anyway (harmless, may help other tools).
        extraLibs = pkgs: with pkgs; [ ncurses ];
      };
    })
  ];

  # UnityShaderCompiler only finds shared libraries through its $ORIGIN/../lib
  # (i.e. Editor/Data/lib). The libs inside the Hub's FHS sandbox aren't
  # resolvable by the loader there (no usable ld.so.cache), so without this
  # symlink the shader compiler dies at startup and the editor reports
  # "Shader compiler init error: failed to get IPCC".
  systemd.user.services.unityShaderCompiler = {
    description = "Symlink libtinfo.so.6 into Unity editor Data/lib";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "fix-unity-shader-libs" ''
        for d in /home/yume/Unity/Hub/Editor/*/Editor/Data; do
          if [ -d "$d" ]; then
            mkdir -p "$d/lib"
            ln -sfn ${pkgs.ncurses}/lib/libtinfo.so.6 "$d/lib/libtinfo.so.6"
          fi
        done
      ''}";
    };
  };

  systemd.user.paths.unityShaderCompiler = {
    description = "Watch for new Unity editor installs";
    wantedBy = [ "default.target" ];
    pathConfig = {
      PathChanged = [ "/home/yume/Unity/Hub/Editor/" ];
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    keyd
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    tailscale 
    unityhub
    unzip
    fastfetch
    emacs
    ayugram-desktop
    gh
    git
    rustup
    vscode
    vscode-extensions.rust-lang.rust-analyzer    
    gcc
    lmms-full
];

  # Enable the Tailscale VPN.
  services.tailscale.enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
