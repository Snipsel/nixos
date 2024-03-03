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

  networking.nameservers = [ "100.100.100.100" "1.1.1.1" "1.0.0.1" ];
  networking.search = [ "ts.snipsel.net" ];

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "https://ts.snipsel.net";
      dns_config = {
        base_domain = "ts.snipsel.net";
	override_local_dns = true;
	nameservers = [
	  "1.1.1.1"
	  "1.0.0.1"
	];
	extra_records = [
	  {
	    name =  "home.snipsel.net";
	    type =  "A";
	    value = "100.64.0.1";
	  }
	];
      };
      logtail.enabled = false;
    };
  };
  services.tailscale = { enable = true; };

  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@snipsel.net";
  };
  services.nginx = {
    enable = true;
    virtualHosts."ts.snipsel.net" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.headscale.port}";
	proxyWebsockets = true;
      };
    };
    virtualHosts."home.snipsel.net" = {
      root = "/srv/ts";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    checkReversePath = "loose";
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  #services.resolved = {
  #  enable = true;
  #  dnssec = "true";
  #  domains = [ "~." ];
  #  fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
  #  dnsovertls = "true";
  #};

}
