{ lib, base, overlay }:

assert lib.assertMsg (builtins.isAttrs base && builtins.isAttrs overlay)
  "PiG settings must be JSON objects";
let
  excluded = overlay.excludePackages or [ ];
  overrides = builtins.removeAttrs overlay [ "excludePackages" ];
  resourceKeys = [ "packages" "extensions" "skills" "prompts" "themes" ];
  source = entry: if builtins.isAttrs entry then entry.source else entry;
  mergeResource = key:
    let
      inherited = base.${key} or [ ];
      added = overrides.${key} or [ ];
      entries = inherited ++ added;
      validEntry = entry: builtins.isString entry || (
        key == "packages" && builtins.isAttrs entry
        && entry ? source && builtins.isString entry.source
      );
      names = lib.unique (map source entries);
      # Keep first-seen positions, but let later entries replace their values.
      bySource = builtins.listToAttrs (map
        (entry: lib.nameValuePair (source entry) entry)
        (lib.reverseList entries));
    in
    assert lib.assertMsg (builtins.isList inherited && builtins.isList added)
      "PiG ${key} must be arrays";
    assert lib.assertMsg (builtins.all validEntry entries)
      "Invalid PiG ${key} entry";
    map (name: bySource.${name}) (builtins.filter
      (name: key != "packages" || !(builtins.elem name excluded)) names);
  resources = lib.genAttrs (builtins.filter
    (key: builtins.hasAttr key base || builtins.hasAttr key overrides)
    resourceKeys) mergeResource;
in
assert lib.assertMsg (builtins.isList excluded && builtins.all builtins.isString excluded)
  "PiG excludePackages must be an array of package source strings";
lib.recursiveUpdate base overrides // resources
