{ config, lib, pkgs, ... }:

let
  impermanence = builtins.fetchTarball "https://github.com/nix-community/impermanence/archive/master.tar.gz";
in
{
  imports = [ 
    ./hardware-configuration.nix
    ./linode.nix
    "${impermanence}/nixos.nix"
  ];

  fileSystems = {
    "/"        = { fsType = "zfs";  device = "zpool/root";    };
    "/nix"     = { fsType = "zfs";  device = "zpool/nix";     };
    "/home"    = { fsType = "zfs";  device = "zpool/home";    };
    "/persist" = { fsType = "zfs";  device = "zpool/persist"; neededForBoot = true;};
    "/boot"    = { fsType = "ext2"; device = "/dev/disk/by-label/boot"; };
  };
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  boot = {
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelParams = lib.mkAfter [ "elevator=none" ];
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r zpool/root@blank
    '';
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      ChallengeResponseAuthentication = false;
    };
    allowSFTP = false;
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
    hostKeys = [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  users.mutableUsers = false;
  users.users.snipsel = {
    isNormalUser = true;
    home = "/home/snipsel";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAoVyOo3d6mPu9w7T1IR92aXROQZibIQFwraEMD5QAB"
    ];
  };

  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  system.stateVersion = "23.11";
}
