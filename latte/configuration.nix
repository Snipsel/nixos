{ config, lib, pkgs, ... }:
{
  users.groups.git = {};
  users.users.git = {
    isSystemUser = true;
    home = "/srv/git";
    group = "git";
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys =
      config.users.users.snipsel.openssh.authorizedKeys.keys;
  };
  #environment.persistence."/persist".directories = lib.mkAfter [
  #   config.users.users.git.home
  #];
}
