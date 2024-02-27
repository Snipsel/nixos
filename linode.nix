{ config, lib, pkgs, modulesPath, ... }:{

  boot = {
    kernelParams = [ "elevator=none" "console=ttyS0,19200n8" ];
    loader = {
      timeout = 30;
      grub = {
        enable = true;
        device = "/dev/sda";
        efiSupport = false;
        zfsSupport = true;
        extraConfig = ''
          serial --speed=19200 --unit=0 --word=8 --parity=no --stops=1;
          terminal_input serial;
          terminal_output serial
        '';
      };
    };
  };

  networking = {
    hostId = "c0ffee00";
    usePredictableInterfaceNames = false;
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };
}
