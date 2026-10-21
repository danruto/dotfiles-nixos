{ config, lib, pkgs, ... }:

{
  # Script to automatically reconnect Thunderbolt monitors on disconnect.
  # Started by udev when a Thunderbolt peripheral appears and exits once none
  # remain, so it never polls on battery away from the desk.
  systemd.services.thunderbolt-monitor-watchdog = {
    description = "Thunderbolt Monitor Auto-Reconnect Watchdog";
    after = [ "bolt.service" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "5s";
      ExecStart = pkgs.writeShellScript "tb-monitor-watchdog" ''
        #!${pkgs.bash}/bin/bash

        CHECK_INTERVAL=5

        # Host routers are named <domain>-0; anything else is a peripheral.
        peripheral_connected() {
          for dev in /sys/bus/thunderbolt/devices/*-*; do
            case "''${dev##*/}" in
              *-0 | *:*) ;;
              *) return 0 ;;
            esac
          done
          return 1
        }

        while peripheral_connected; do
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

  services.udev.extraRules = ''
    # Start the watchdog when a Thunderbolt peripheral (not a host router) appears
    ACTION=="add", SUBSYSTEM=="thunderbolt", ENV{DEVTYPE}=="thunderbolt_device", KERNEL!="*-0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="thunderbolt-monitor-watchdog.service"

    # When Thunderbolt device disconnects, trigger PCI rescan after a delay
    ACTION=="remove", SUBSYSTEM=="thunderbolt", RUN+="${pkgs.bash}/bin/bash -c 'sleep 2 && echo 1 > /sys/bus/pci/rescan'"
  '';
}
