## NixOS Dotfiles Configuration

This repository contains personal NixOS configurations and is managed using Nix Flakes. The following commands and guidelines are intended for use by developers and tools interacting with this codebase.

### Build and Test

- **Build/Switch:** To apply local changes, run `make switch`. This command will build the new configuration and activate it.
- **Linting:** Use `nix flake check --all-systems --no-build` to ensure all files are syntactically correct and conform to the project structure.
- **Formatting:** To automatically format all `.nix` files, run `nix fmt`.

### Code Style

- **Formatting:** All `.nix` files must be formatted with `nix fmt` before committing.
- **Imports:** When adding new files, they must be explicitly imported in `flake.nix` or another relevant file.
- **Naming Conventions:** All variables and functions must be written in `camelCase`.
- **Modularity:** Configurations are organized into modules by function. New files should be placed in the appropriate directory (e.g., `user/apps/terminal/` for terminal applications).
- **Error Handling:** All shell scripts must include `set -euo pipefail` to ensure proper error handling and prevent unexpected behavior.
- **Commits:** All commits must follow the Conventional Commits specification.
- **Dependencies:** All dependencies must be managed through `flake.nix` to ensure reproducibility.
- **Documentation:** All functions and modules must include a comment describing their purpose and usage.
- **Testing:** While there are no automated tests, all changes must be manually tested before committing.
- **Pull Requests:** All pull requests must be reviewed and approved by at least one other person before merging.
- **Profiles:** User-specific configurations are managed through profiles in the `profiles/` directory. Each profile has its own `configuration.nix` and `home.nix`.
- **Secrets:** No secrets should be stored in this repository. Use a secrets management tool like `age` or `sops` instead.
- **Hardware:** Hardware-specific configurations should be placed in the `system/hardware/` directory.
- **Styling:** Visual styles and themes are managed in the `user/style/` directory, separate from functional configurations.
- **Window Managers:** Window manager configurations are located in `user/wm/`, with corresponding system-level settings in `system/wm/`.
- **Applications:** User-specific application settings are defined in `user/apps/`, categorized by function.
- **Languages:** Language-specific development environments are configured in `user/lang/`.
- **System Services:** System-level services and daemons are configured in `system/` and should be kept separate from user-specific settings.
