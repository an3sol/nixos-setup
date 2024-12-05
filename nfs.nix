# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{

  # List of system packages including NFS utilities
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  # Enable NFS support
    services.rpcbind.enable = true;
    services.nfs.server.enable = false;  # Set to true if you want to serve NFS


    # Create the mount points
    systemd.tmpfiles.rules = [
      "d /mnt/nfs-private 0755 root root"
      "d /mnt/nfs-public 0755 root root"
    ];

    # Configure the NFS mounts
    fileSystems."/mnt/nfs-private" = {
      device = "10.1.1.171:/srv/media";
      fsType = "nfs";
      options = [
        "nfsvers=3"
        "x-systemd.automount"
        "x-systemd.requires=network-online.target"
        "x-systemd.idle-timeout=600"  # Unmount after 10 minutes of inactivity
        "noauto"
        "x-systemd.mount-timeout=10"
        "retry=30"
        "_netdev"
      ];
    };

    fileSystems."/mnt/nfs-public" = {
      device = "10.1.1.171:/srv/public";
      fsType = "nfs";
      options = [
        "nfsvers=3"
        "x-systemd.automount"
        "x-systemd.requires=network-online.target"
        "x-systemd.idle-timeout=600"
        "noauto"
        "x-systemd.mount-timeout=10"
        "retry=30"
        "_netdev"
      ];
    };

    # Ensure network is online before mounting
#    systemd.services.network-online.enable = true;

    systemd.services.wait-for-nfs-server = {
    description = "Wait for NFS server to be available";
    after = [ "network-online.target" ];
    before = [ "remote-fs-pre.target" ];
    wantedBy = [ "remote-fs.target" ];
    requires = [ "network-online.target" ]; # Explicitly depend on network-online.target
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.netcat}/bin/nc -z 10.1.1.171 22 || exit 1'";
    };
  };
}
