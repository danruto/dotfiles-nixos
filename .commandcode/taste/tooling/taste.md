# Tooling

- Prefers running latest/beta versions of tools (e.g., opencode v2 beta over the pinned v1) and periodically asks to "version bump" pinned versions in llm.nix. Confidence: 0.8
- When a Nix package build fails because of its test suite (e.g., neovim), prefers disabling the tests rather than debugging/fixing the suite. Confidence: 0.7
- In dotfiles, skill configs should reference local folder variants (like pb-skills) rather than remote variants. Confidence: 0.6
