{ config, lib, pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
  ];

  # Additional kernel modules for power management
  boot.kernelModules = [
    "intel_rapl_msr"  # Intel RAPL energy monitoring
  ];

  # Kernel module parameters for power optimization
  boot.extraModprobeConfig = ''
    # Intel audio codec power management
    options snd_hda_intel power_save=1 power_save_controller=Y
    
    # WiFi power management
    options iwlwifi power_save=1 power_level=5
  '';
}
