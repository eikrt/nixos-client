# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let fehLaunch = pkgs.writeText "feh.sh" 
    ''
echo "sleep 5 && ${pkgs.feh}/bin/feh -F -Z -R 1 /home/user/abzug-receiver/images/latest.png" > /home/user/abzug-receiver/weston/img.sh
    '';
initImg = pkgs.writeText "initImg.sh" 
    ''
echo "${pkgs.gcc}/bin/gcc /home/user/abzug-receiver/weston/img.c -o /home/user/abzug-receiver/weston/img" > /home/user/abzug-receiver/weston/init.sh
    '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  networking.hostName = "nixos"; # Define your hostname.
#  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "fi";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.user = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
  services.mosquitto = {
  enable = false;
  listeners = [
    {
      users.root = {
        acl = [
          "readwrite #"
          ];
        };
      }
    ];
  };
  # Enable automatic login for the user.
  services.getty.autologinUser = "user";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  hardware.opengl.enable = true;
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    wget
    openssl
    weston 
    feh 
  ];

systemd.services."fetcher" = {
	enable = true;
	unitConfig = {
		type="Simple";
	};
	serviceConfig = {
		ExecStart="${pkgs.git}/bin/git clone https://github.com/eikrt/abzug-receiver /home/user/abzug-receiver";
	};
};
systemd.services."westonl" = {
	enable = true;
	unitConfig = {
		Type = "oneshot";
	#	Requires = "weston.socket";
#		After = "weston.socket";
	};
	   serviceConfig = {
	     Environment = "XDG_RUNTIME_DIR=/var/run/user/1000"; 
	     ExecStartPre = ["${pkgs.bash}/bin/bash ${initImg}" "${pkgs.bash}/bin/bash /home/user/abzug-receiver/weston/init.sh" "${pkgs.bash}/bin/bash ${fehLaunch}" "${pkgs.bash}/bin/bash /home/user/abzug-receiver/weston/init.sh"];
	     ExecStart = "${pkgs.weston}/bin/weston --config=/home/user/abzug-receiver/weston/weston.ini";
	    # ExecStartPost = "${pkgs.weston}/bin/weston-terminal";
	     RestartOn = "failure";
	};
	   wantedBy = [ "graphical-session.target" ];
};
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
  system.stateVersion = "23.11"; # Did you read the comment?

}
