{ config, lib, pkgs, ... }:
{
  system.stateVersion = "23.11";
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  fileSystems = {
    "/"        = { fsType = "zfs";  device = "zpool/root";    };
    "/nix"     = { fsType = "zfs";  device = "zpool/nix";     };
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
      { directory="/home/snipsel/.config/git";  user="snipsel";   group="users"; }
      { directory="/home/snipsel/.config/fish"; user="snipsel";   group="users"; }

      "/srv/git"
      "/srv/ts"
      "/var/lib/tailscale"
      { directory="/var/lib/acme";              user="acme";      group="acme"; }
      { directory="/var/lib/headscale";         user="headscale"; group="headscale"; }
    ];
    files = [
      "/etc/machine-id"
      "/home/snipsel/.ssh/known_hosts"
      "/home/snipsel/.ssh/id_ed25519"
      "/home/snipsel/.ssh/id_ed25519.pub"
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

  programs = {
    git    = { enable = true; };
    neovim = { enable = true; defaultEditor = true; };
    fish   = { enable = true; interactiveShellInit = "set fish_greeting"; };
    bash   = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    ripgrep
    fzf
    eza
    kitty
  ];

  users.mutableUsers = false;
  users.users.snipsel = {
    isNormalUser = true;
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
}
