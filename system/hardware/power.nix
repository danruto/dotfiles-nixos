{ pkgs-unstable, ... }:

{
  environment.systemPackages = with pkgs-unstable; [ tlp powertop ];

  # Disable auto-cpufreq - using TLP instead
  services.auto-cpufreq.enable = false;

  # Enable powertop auto-tuning
  powerManagement.powertop.enable = true;
  # Let TLP handle CPU governor instead of setting it globally
  # powerManagement.cpuFreqGovernor = "schedutil";

  # Disable NMI watchdog for power savings (PowerTOP recommendation)
  boot.kernelParams = [
    "nmi_watchdog=0"
    "processor.max_cstate=10"
    "intel_idle.max_cstate=10"
    "usbcore.autosuspend=-1"
  ];

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

  # Additional power management optimizations
  services.udev.extraRules = ''
    # Enable runtime PM for all PCI devices (PowerTOP recommendation)
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"

    # Disable USB autosuspend for input devices and problematic peripherals
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="03", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1532", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="03f0", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="a8f8", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="14ed", ATTR{power/control}="on"
  '';

  # PowerTOP auto-tune service
  systemd.services.powertop-auto-tune = {
    description = "PowerTOP auto-tune";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs-unstable.powertop}/bin/powertop --auto-tune";
    };
  };

  services.tlp = {
    enable = true;
    settings = {
      # CPU governors - performance for AC, powersave for battery
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Intel P-state energy performance preference
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Intel P-state performance scaling
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 40; # Aggressive battery saving

      # Intel Turbo Boost
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Intel Hardware P-state (HWP) dynamic boost
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Platform profiles for 12th gen
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # USB power management - disable to prevent disconnections
      USB_AUTOSUSPEND = 0;
      USB_BLACKLIST_PHONE = 1;
      USB_BLACKLIST_WWAN = 1;

      # WiFi power management
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Runtime power management
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # PCIe power management
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Disk power management
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "128 128";
      DISK_SPINDOWN_TIMEOUT_ON_AC = "0 0";
      DISK_SPINDOWN_TIMEOUT_ON_BAT = "60 60";

      # SATA link power management
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "min_power";

      # Battery charge thresholds
      START_CHARGE_THRESH_BAT1 = 40;
      STOP_CHARGE_THRESH_BAT1 = 80;

      # Kernel laptop mode
      DISK_IDLE_SECS_ON_AC = 0;
      DISK_IDLE_SECS_ON_BAT = 2;
      MAX_LOST_WORK_SECS_ON_AC = 15;
      MAX_LOST_WORK_SECS_ON_BAT = 60;

      # Audio codec power management (PowerTOP recommendation)
      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      # VM writeback timeout optimization
      DIRTY_WRITEBACK_CENTISECS_ON_AC = 1500;
      DIRTY_WRITEBACK_CENTISECS_ON_BAT = 6000;
    };
  };
}
