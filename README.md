# NixOS & macOS Configuration

This repository contains my personal NixOS and macOS configurations, managed using [Nix Flakes](https://nixos.wiki/wiki/Flakes) and [home-manager](https://github.com/nix-community/home-manager).

## Structure

The repository is organized into the following directories:

-   `flake.nix`: The entry point for the NixOS configuration. It defines the hosts, inputs, and general settings.
-   `profiles/`: Contains the main configuration files for each host (`configuration.nix` and `home.nix`). Each subdirectory represents a different machine or setup.
-   `system/`: Contains system-wide configurations that are imported into the profiles. This includes hardware settings, applications, security policies, and window manager settings.
-   `user/`: Contains user-specific configurations managed by `home-manager`. This includes application settings (editors, browsers, terminals), shell configurations, and language-specific development environments.
-   `themes/`: Holds color schemes and themes that can be applied across the system.

## Installation

> NOTE: This is obviously my personal configuration so it might not work for you.

Use the `make switch` command after updating the `flake.nix` to the correct profile/system settings.
