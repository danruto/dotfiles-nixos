{ pkgs-unstable, ... }:

{
  environment.systemPackages = with pkgs-unstable; [ tlp ];

  services.auto-cpufreq = {
    enable = false;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };
  #services.auto-cpufreq.settings = {
  #  charger = {
  #    governor = "performance";
  #    turbo = "auto";
  #  };
  #  battery = {
  #    governor = "schedutil";
  #    scaling_max_freq = 3800000;
  #    turbo = "never";
  #  };
  #};
  powerManagement.powertop.enable = false;
  # powerManagement.cpuFreqGovernor = "powersave";

  services.upower.enable = true;
  services.upower.criticalPowerAction = "Hibernate";
  services.thermald.enable = true;
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    # lidSwitch = "suspend";
    # lidSwitchExternalPower = "suspend";
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=1h
  '';

  services.tlp = {
    enable = true;
    # package = pkgs.unstable.tlp;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      #
      # CPU_MIN_PERF_ON_AC = 0;
      # CPU_MAX_PERF_ON_AC = 100;
      # CPU_MIN_PERF_ON_BAT = 0;
      # CPU_MAX_PERF_ON_BAT = 80;

      START_CHARGE_THRESH_BAT1 = 40; # 40 and bellow it starts to charge
      STOP_CHARGE_THRESH_BAT1 = 80; # 80 and above it stops charging
    };
  };
}
