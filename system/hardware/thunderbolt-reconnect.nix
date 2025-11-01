{ config, lib, pkgs, ... }:

{
  # Script to automatically reconnect Thunderbolt monitors on disconnect
  systemd.services.thunderbolt-monitor-watchdog = {
    description = "Thunderbolt Monitor Auto-Reconnect Watchdog";
    after = [ "bolt.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      ExecStart = pkgs.writeShellScript "tb-monitor-watchdog" ''
        #!${pkgs.bash}/bin/bash

        MONITOR_UUID="af758780-0033-f9cc-ffff-ffffffffffff"
        CHECK_INTERVAL=5

        while true; do
          # Check if monitor is authorized but DisplayPort is disconnected
          if ${pkgs.bolt}/bin/boltctl list | grep -q "status:.*authorized"; then
            # Check if any external displays are active
            DISPLAY_COUNT=$(${pkgs.coreutils}/bin/ls /sys/class/drm/card*/card*-DP-*/status 2>/dev/null | \
              ${pkgs.coreutils}/bin/xargs ${pkgs.coreutils}/bin/cat 2>/dev/null | \
              ${pkgs.gnugrep}/bin/grep -c "^connected" || echo "0")

            if [ "$DISPLAY_COUNT" -eq "0" ]; then
              echo "[$(${pkgs.coreutils}/bin/date)] No external displays detected, attempting reconnect..."

              # Try PCI rescan to trigger re-detection
              echo 1 | ${pkgs.coreutils}/bin/tee /sys/bus/pci/rescan > /dev/null 2>&1

              # Wait a bit for detection
              ${pkgs.coreutils}/bin/sleep 2
            fi
          fi

          ${pkgs.coreutils}/bin/sleep $CHECK_INTERVAL
        done
      '';
    };
  };

  # Udev rule to trigger immediate reconnect on Thunderbolt disconnect
  services.udev.extraRules = ''
    # When Thunderbolt device disconnects, trigger PCI rescan after a delay
    ACTION=="remove", SUBSYSTEM=="thunderbolt", RUN+="${pkgs.bash}/bin/bash -c 'sleep 2 && echo 1 > /sys/bus/pci/rescan'"
  '';
}
