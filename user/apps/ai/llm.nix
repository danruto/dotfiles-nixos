{ pkgs, pkgs-unstable, pkgs-master, fff, lib, config, ... }:
let
  # Standalone home (e.g. orb-arch via `make hm/switch`) skips Pi: its install
  # activation shells out to a global npm install that fails on read-only/Nix
  # store setups, and Pi isn't wanted on that profile anyway.
  # piEnabled = platform != "standalone";
  piEnabled = true;

  fff-mcp = fff.packages.${pkgs.stdenv.hostPlatform.system}.default;
  lazypi = pkgs.callPackage ./lazypi.nix { };
  dsh = pkgs-unstable.callPackage ./dsh.nix { };
  command-code = pkgs-unstable.callPackage ./command-code.nix { };

  # nixpkgs-master fetches zstd-compressed binaries; take checksums from
  # https://downloads.claude.ai/claude-code-releases/<version>/manifest.zst.json
  claude-code-unwrapped = pkgs-master.claude-code.override {
    manifest = {
      version = "2.1.309";
      platforms = {
        "darwin-arm64" = { binary = "claude.zst"; checksum = "614eb35bb650dee9cfa4a7821a60d5eab75fbcabe2c1b8aa408d2e93f06c1370"; };
        "darwin-x64" = { binary = "claude.zst"; checksum = "7426a8b80fe213e90b8e58682a54668aa7efe838939c9b2cab8d6089ab13befb"; };
        "linux-arm64" = { binary = "claude.zst"; checksum = "a2f75e390c4afc3c610db69e7ff2587327f135f161cad5f088c2d0de6e5a9441"; };
        "linux-x64" = { binary = "claude.zst"; checksum = "e52289b95def16148c8d0a48b1ccc0d357429e73473a9a20ac0638fb7460a59b"; };
      };
    };
  };

  # Load pb straight from the live checkout instead of the pb-skills marketplace,
  # whose installed copy is a stale snapshot under <config dir>/plugins/cache.
  # Wrapping the binary (not a fish function) covers every launcher: claude,
  # claude-healix, claude-nm and herdr. The flag is accepted before subcommands,
  # and a missing dir on hosts without the checkout is ignored.
  claude-code = pkgs.symlinkJoin {
    name = "claude-code-${claude-code-unwrapped.version}";
    paths = [ claude-code-unwrapped ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --add-flags "--plugin-dir ${config.home.homeDirectory}/dev/pixelbrush/pb-skills/plugins/pb"
    '';
    inherit (claude-code-unwrapped) meta;
  };

  # nixpkgs builds tokscale from Rust source, which takes far too long. Upstream
  # publishes the same release as prebuilt per-platform binaries on npm, so pull
  # those instead. Bumping means a new version + four integrity hashes from
  # `npm view @tokscale/cli-<plat> dist.integrity`.
  tokscale =
    let
      version = "4.20.0";
      sources = {
        "x86_64-linux" = { plat = "linux-x64-gnu"; hash = "sha512-YhqI91zM4UeRqa0tm6fj7qjAf9TVaO8WjLf+eWQoTSrEPCJ80/9iIS/tdc8gNHe5dVnSc6Yr1kAMVgdnEpJsQQ=="; };
        "aarch64-linux" = { plat = "linux-arm64-gnu"; hash = "sha512-6YZSZsHq+gmNmGxQzxthjT03MAQYAezPgQXbfhcdIv1x/1euTFU1CKJ13qot8+N8Jl5uJnL7Zmv7m4aiWG9gWQ=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-UGa+GakljqaeyMgz+0P9UBSi5Z5SWzuFrUs21DT2TBWabN1e6ETDNXKKn2bu15X+2f/HkPT81HK9K4/GbQ1hHg=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-9FQjSubJRDF9eKA/+bMg5pgEseo2dZFcbBVZWKEuTRQDJg+rUD4nrtvQZ1pR8XAhes3gS7BNb0gxdvuodTEKBg=="; };
      };
      target = sources.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "tokscale";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@tokscale/cli-${target.plat}/-/cli-${target.plat}-${version}.tgz";
        inherit (target) hash;
      };
      nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
      installPhase = "install -Dm755 bin/tokscale $out/bin/tokscale";
      meta = {
        description = "Track token usage across AI coding agents from your terminal";
        homepage = "https://github.com/junhoyeo/tokscale";
        license = pkgs.lib.licenses.mit;
        platforms = builtins.attrNames sources;
        mainProgram = "tokscale";
      };
    };

  pi-coding-agent = pkgs-master.callPackage ./pi.nix { };

  # opencode v2 ships as prebuilt bun binaries under the @opencode/cli npm
  # scope; nixpkgs' `opencode` is still the v1 source build. Bumping means a
  # new version + four hashes from
  # `npm view @opencode/cli-<plat>@<version> dist.integrity`.
  opencode =
    let
      version = "2.1.3";
      hashes = {
        "x86_64-linux" = { plat = "linux-x64"; hash = "sha512-WVO7TebdgAcPnoOQ390ny3oyqpCH5MpPU76lHXml3G/wJz6QLxjzsQW2Lrabiewg046yAeKlf+1nPPZElF1qPw=="; };
        "aarch64-linux" = { plat = "linux-arm64"; hash = "sha512-Two8nCzLbQC5jZc5oAeize3hCPKSawa/tCm2N7s6EIqeEcdPU7VAQNYiyEkrC4UhDJk91EpplsizPg8XmHCdmA=="; };
        "x86_64-darwin" = { plat = "darwin-x64"; hash = "sha512-WOaOLjzodos6VdjwaoU4rf8s4cGw0y+nNGkffEqz/8/e3tAPx+qgNZdPda0Q0k74PVDEM99GSYFFgvCiSy2UUg=="; };
        "aarch64-darwin" = { plat = "darwin-arm64"; hash = "sha512-EwunTL9Q/6GT+vnA5e9NJyLdFFHpj77bQI1JdyNNtSI7dKO/DHW2RlvKMty2uvONCTfA4zdkwop9GalLw5becg=="; };
      };
      target = hashes.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "opencode";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@opencode/cli-${target.plat}/-/cli-${target.plat}-${version}.tgz";
        inherit (target) hash;
      };
      nativeBuildInputs = [ pkgs.makeBinaryWrapper ]
        ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
      installPhase = ''
        runHook preInstall
        install -Dm755 bin/opencode $out/bin/opencode
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.sqlite ]} \
          --set OPENCODE_DISABLE_AUTOUPDATE true
        runHook postInstall
      '';
      # bun --compile binary: the JS payload is appended to the ELF, stripping
      # it corrupts the executable (nixpkgs' own opencode does the same).
      dontStrip = true;
      meta = {
        description = "AI coding agent built for the terminal";
        homepage = "https://github.com/anomalyco/opencode";
        platforms = builtins.attrNames hashes;
        mainProgram = "opencode";
      };
    };

  revdiff =
    let
      version = "1.13.0";
      sources = {
        "x86_64-linux" = { suffix = "linux_amd64"; hash = "sha256-bML8vcsuhlpwY5RfBzX2mRb2jMIaiGhUIXIzx5PttMc="; };
        "aarch64-linux" = { suffix = "linux_arm64"; hash = "sha256-QEkq6zalfxDCvKGlzJX66GnXI2v7BO+32dHD2ChRr/U="; };
        "x86_64-darwin" = { suffix = "darwin_amd64"; hash = "sha256-6TPjW/kbKuIKXIP3+d+KsNBpfx49b9l1qAnLOQnejPY="; };
        "aarch64-darwin" = { suffix = "darwin_arm64"; hash = "sha256-mXzMnxZP4HIOY0m9k8c+eennDdAFjufMeoysTBYx6aQ="; };
      };
      target = sources.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "revdiff";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/umputun/revdiff/releases/download/v${version}/revdiff_${version}_${target.suffix}.tar.gz";
        inherit (target) hash;
      };
      nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.autoPatchelfHook;
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 revdiff $out/bin/revdiff
        runHook postInstall
      '';
      meta = {
        description = "TUI for reviewing diffs, files, and documents with inline annotations";
        homepage = "https://revdiff.com";
        platforms = builtins.attrNames sources;
      };
    };

  aiConfigs = "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs";

  # Both Claude Code subscriptions share one config set: ~/.claude (default) and
  # ~/.claude-healix (selected with CLAUDE_CONFIG_DIR).
  claudeDirs = [ ".claude" ".claude-healix" ".claude-nm" ];
in
{
  home.packages = (with pkgs-unstable; [
    # opencode
    sox # voice for cc
    revdiff
    # amp-cli
    # gemini-cli
    # codex
    # nur.repos.charmbracelet.crush
  ]) ++ [
    dsh
    tokscale
    command-code
    claude-code
    opencode
    pkgs-unstable.codex
    fff-mcp # on PATH so Claude/Pi MCP configs can reference `fff-mcp` by name
  ] ++ lib.optionals piEnabled [
    pi-coding-agent
    lazypi
  ];

  # CLAUDE.md, the statusline scripts and settings.json are out-of-store symlinks
  # to the live working tree (like herdr's config.toml) so edits — including
  # Claude Code's own writes to settings.json — land directly in this repo
  # without a redeploy. Both subscription dirs in `claudeDirs` get the same set,
  # so there is nothing to hand-copy between them. Assumes the repo is checked
  # out at ~/dotfiles-nixos. fff-mcp is on PATH (see home.packages) so the static
  # Claude/OMP MCP configs can reference it by bare name instead of a store path.
  #
  # NOTE: Claude Code does NOT read `mcpServers` from settings.json — the key is
  # not in the settings schema and is silently ignored. MCP servers only load
  # from ~/.claude.json or a repo's .mcp.json. ~/.claude.json is mutable state
  # this flake does not manage, so on a fresh machine register fff manually:
  #     claude mcp add --scope user fff fff-mcp
  # Verify with `claude mcp list` (expect "fff: fff-mcp - ✔ Connected").
  # Pi's MCP config is unaffected and still reads its own settings file.
  home.file = (lib.foldl' lib.mergeAttrs { } (map
    (dir: {
      "${dir}/CLAUDE.md".source =
        config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/CLAUDE.md";
      "${dir}/statusline.sh".source =
        config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/statusline.sh";
      "${dir}/subagent-statusline.sh".source =
        config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/subagent-statusline.sh";
    })
    claudeDirs)) // {
    # Non-Claude harnesses read their own global-instructions filename; point
    # both at the same canonical file so every agent gets identical rules.
    # opencode's global precedence makes ~/.config/opencode/AGENTS.md win over
    # the ~/.claude/CLAUDE.md fallback (first match wins), so this replaces —
    # not duplicates — that fallback.
    ".config/opencode/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/CLAUDE.md";
  } // lib.optionalAttrs piEnabled {
    ".pi/agent/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${aiConfigs}/CLAUDE.md";
  };

  # settings.json can't go through home.file/mkOutOfStoreSymlink: that routes the
  # link through the read-only home-manager-files store dir, and Claude Code
  # rewrites settings.json atomically (write a sibling .tmp, then rename). It
  # resolves only the first symlink hop, so the .tmp lands in /nix/store → EROFS
  # (breaks plugin installs, /config, etc.). Create a *direct* out-of-store
  # symlink to the live repo file instead, so the sibling .tmp lands in the
  # writable repo dir and Claude's own edits still sync straight back into git.
  #
  # rename() replaces the symlink itself, so an in-place rewrite can still leave a
  # detached regular file behind (this happened to ~/.claude/settings.json). The
  # loop below heals that: a non-symlink target newer than the repo file is copied
  # back into the repo first — never discarded — then re-linked.
  #
  # The theme at "<config dir>/themes/base16.json" is deliberately not linked
  # here: scripts/theme-render writes it in place, and Claude Code only
  # hot-reloads the active theme by watching that directory for events on the
  # file itself.
  home.activation.claudeSettingsLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="${aiConfigs}/settings.json"
    for dir in ${lib.concatMapStringsSep " " (d: ''"${config.home.homeDirectory}/${d}"'') claudeDirs}; do
      target="$dir/settings.json"
      run mkdir -p "$dir"
      if [ -f "$target" ] && [ ! -L "$target" ]; then
        if [ "$target" -nt "$settings" ]; then
          run cp -f "$target" "$settings"
        fi
        run rm -f "$target"
      fi
      run ln -sfn "$settings" "$target"
    done
  '';

  # opencode rewrites its global config in place (it injects "$schema" when
  # missing), so use a direct out-of-store symlink for the same reason as
  # Claude's settings above. The repo file already sets $schema, so no rewrite
  # should happen, but the direct link keeps writes inside the repo either way.
  home.activation.opencodeConfigLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.config/opencode"
    run ln -sf "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/opencode.json" \
      "${config.home.homeDirectory}/.config/opencode/opencode.json"
  '';

  # Pi rewrites settings.json atomically, so use direct out-of-store symlinks
  # for the same reason as Claude's settings above. Pi's own settings changes
  # then land in this repo, while listed packages install on the next launch.
  # The theme at ".pi/agent/themes/base16.json" is not linked here on purpose:
  # scripts/theme-render writes it in place, and pi only hot-reloads the active
  # theme by watching that directory for events on the file itself.
  home.activation.piConfigLinks = lib.mkIf piEnabled (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.pi/agent/extensions"
    run ln -sfn "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-settings.json" \
      "${config.home.homeDirectory}/.pi/agent/settings.json"
    run ln -sfn "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-models.json" \
      "${config.home.homeDirectory}/.pi/agent/models.json"
    run ln -sfn "${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/pi-usage-status.ts" \
      "${config.home.homeDirectory}/.pi/agent/extensions/pi-usage-status.ts"
  '');

  # Command Code's global taste (~/.commandcode/taste) is a writable tree that
  # the learning system rewrites in place, so use a direct out-of-store symlink
  # (same rationale as Claude's settings above) pointing at the tracked copy in
  # this repo. Project-level .commandcode/ stays gitignored. rm + ln (instead of
  # ln -sfn alone) so a pre-existing real dir — e.g. one created by an older
  # command-code version before this link existed — gets replaced rather than
  # linked into.
  home.activation.commandcodeTasteLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    tasteRepo="${config.home.homeDirectory}/dotfiles-nixos/user/apps/ai/configs/taste"
    tasteTarget="${config.home.homeDirectory}/.commandcode/taste"
    run mkdir -p "${config.home.homeDirectory}/.commandcode"
    if [ -e "$tasteTarget" ] && [ ! -L "$tasteTarget" ]; then
      run rm -rf "$tasteTarget"
    fi
    run ln -sfn "$tasteRepo" "$tasteTarget"
  '';
}
