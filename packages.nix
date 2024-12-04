# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

  fonts.packages = with pkgs; [
    cantarell-fonts
    font-awesome
  ];

  nixpkgs.config.allowUnfree = true; #for google-chrome etc

{
  environment.systemPackages = with pkgs; [
    # System Tools & CLI
    git
    wget
    htop
    tmux
    screen
    #trash-cli
    bat
    xclip
    file
    lm_sensors
    dmidecode
    jdupes
    fdupes
    hashcat
    yt-dlp
    #pciutils # lspci
    #busybox # Tiny versions of common UNIX utilities in a single small executable
    #toybox
    tree
    bash-completion
    curl
    rsync

    #appimage-run
    #virtualbox
    #libreoffice

    # File System & Disk Utilities
    #services.gvfs.enable = true;
    gvfs
    nfs-utils
    ntfs3g
    gparted
    baobab
    udisks
    smartmontools

    # Networking Tools
    sshfs
    iperf3
    wireshark
    sshpass
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses
    #    mtr # A network diagnostic tool
    dnsutils  # `dig` + `nslookup`
    #    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    filezilla
    syncthing
    networkmanagerapplet
    whois
    tcpdump
    netcat-gnu
    openvpn

    # Screenshot & Screen Recording
    scrot
    screenkey
    flameshot
    simplescreenrecorder

    # Torrent
    rqbit
    transmission
    transmission-gtk

    # Sound & Audio
    audacity
    pavucontrol
    spotify
    #spotify-tui
    #spotube
    #cava Console-based Audio Visualizer for Alsa

    # Video Players
    vlc
    mpv

    # Video Editing
    obs-studio
    #obs-studio-plugins.wlrobs
    kdenlive
      # GPU stuff  dep
    	#amdvlk
    	#rocm-opencl-icd
    	#glaxnimate (dep)


    # File Managers
    pcmanfm
    #dolphin
    #mc
    #ranger

    # IDEs & Editors
    vim
    emacs
    #vscodium
    #neovide
    #neovim

    # Communication
    discord
    telegram-desktop
    pidgin

    # Terminal Emulators
    alacritty
    kitty

    # Security & Password Management
    keepassxc
    keepass
    openssl
    gnupg

    # Web Browsers
    google-chrome
    #chromium
    #firefox-bin

    # System Information
    neofetch

    # Themes & Appearance
    flat-remix-gtk
    flat-remix-icon-theme
    lxappearance

    # Image Viewers & Editors
    nomacs
    #imagemagick
    krita

    # Phone
    #adb-sync

    # Development Tools
    jq
    bc
    rustc
    cargo
    gcc
    cmake
    clang
    libclang
    llvm
    pkg-config
    pciutils
    usbutils

    python3
    python3Full
    #python3Packages.pip
    #python311Packages.pip
    #python3Packages.requests

    # Multimedia
    ffmpeg
    ffmpegthumbs
    ffmpegthumbnailer

    # Archives
    file-roller
    zip
    xz
    unzip
    p7zip
    rar
    gzip
    xarchiver
    peazip

    # Window Manager
    sway
    grim      # Screenshot tool
    slurp     # Select area for screenshots
    wl-clipboard # Clipboard utilities
    mako      # Notification daemon

    #kanshi

    #rofi
    #wofi
    #dmenu

    #libnotify   # For notify-send command for mako
    #dunst       # Notification daemon
    
    # Optional Extras
    waypipe
    #swaybg
    #swayidle
    #xwayland
    
    #wdisplays
    
    # glib # gsettings for gtk config
    #
    #programs.ssh.forwardAgent = true;

    # Bars
    i3status-rust
    #waybar
    #i3status
    #i3blocks

  ];
}
