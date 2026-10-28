let
  flake = builtins.getFlake (toString ../../.);
  lib = flake.inputs.nixpkgs.lib;
  compose = base: overlay: import ../../user/apps/ai/pig-settings.nix {
    inherit lib base overlay;
  };
  accepts = base: overlay: (builtins.tryEval (builtins.deepSeq (compose base overlay) true)).success;
  tests = {
    testNestedOverrides = {
      expr = compose {
        theme = "base16";
        retry = { enabled = true; maxRetries = 3; };
        enabledModels = [ "old" ];
      } {
        theme = "dark";
        retry.maxRetries = 0;
        enabledModels = [ "new" ];
      };
      expected = {
        theme = "dark";
        retry = { enabled = true; maxRetries = 0; };
        enabledModels = [ "new" ];
      };
    };
    testResourceArraysAppendAndDeduplicate = {
      expr = compose {
        extensions = [ "shared.ts" ];
        skills = [ "shared-skills" ];
        prompts = [ "shared-prompts" ];
        themes = [ "shared-themes" ];
      } {
        extensions = [ "shared.ts" "native" ];
        skills = [ "native-skills" ];
        prompts = [ "native-prompts" ];
        themes = [ "native-themes" ];
      };
      expected = {
        extensions = [ "shared.ts" "native" ];
        skills = [ "shared-skills" "native-skills" ];
        prompts = [ "shared-prompts" "native-prompts" ];
        themes = [ "shared-themes" "native-themes" ];
      };
    };
    testPackageOverrideKeepsPosition = {
      expr = compose {
        packages = [ "npm:shared@1.0.0" { source = "npm:lens@1.0.0"; extensions = [ ]; } ];
      } {
        packages = [ { source = "npm:lens@1.0.0"; skills = [ ]; } "./native" ];
      };
      expected.packages = [ "npm:shared@1.0.0" { source = "npm:lens@1.0.0"; skills = [ ]; } "./native" ];
    };
    testExcludesStringAndObjectSources = {
      expr = compose {
        packages = [ "npm:old@1.0.0" { source = "./old"; skills = [ ]; } "./keep" ];
      } {
        excludePackages = [ "npm:old@1.0.0" "./old" ];
        packages = [ "./native" ];
      };
      expected.packages = [ "./keep" "./native" ];
    };
    testExclusionIsExactAndAppliesToAdditions = {
      expr = compose { packages = [ "npm:old@2.0.0" ]; } {
        excludePackages = [ "npm:old@1.0.0" "./native" ];
        packages = [ "./native" ];
      };
      expected.packages = [ "npm:old@2.0.0" ];
    };
    testEmptyOverlayKeepsBase = {
      expr = compose { theme = "base16"; skills = [ "shared" ]; } { };
      expected = { theme = "base16"; skills = [ "shared" ]; };
    };
    testScalarAndNullOverrides = {
      expr = compose { retry = { enabled = true; }; theme = "base16"; } {
        retry = false;
        theme = null;
      };
      expected = { retry = false; theme = null; };
    };
    testInvalidInputsRejected = {
      expr = map (args: accepts args.base args.overlay) [
        { base = [ ]; overlay = { }; }
        { base = { }; overlay = [ ]; }
        { base = { }; overlay.excludePackages = "bad"; }
        { base = { }; overlay.excludePackages = [ false ]; }
        { base.packages = false; overlay = { }; }
        { base = { }; overlay.extensions = null; }
        { base = { }; overlay.packages = [ { source = false; } ]; }
        { base = { }; overlay.skills = [ { source = "./not-a-package"; } ]; }
      ];
      expected = lib.replicate 8 false;
    };
  };
  failures = lib.runTests tests;
in
if failures == [ ] then { passed = builtins.length (builtins.attrNames tests); }
else throw (builtins.toJSON failures)
