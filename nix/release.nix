# Consumer release artifact (ZIP) for GitHub Releases.
# Validation stays in validate.nix; this only packages distribution files.
{
  pkgs,
  src,
}:

let
  inherit (pkgs) lib;
  plugin = builtins.fromJSON (builtins.readFile (src + "/plugin.json"));
  version = plugin.version;
  zipName = "deployah-agent-skills-v${version}.zip";
in
pkgs.runCommand "deployah-agent-skills-release-${version}"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnused
      pkgs.gnugrep
      pkgs.jq
      pkgs.zip
      pkgs.unzip
    ];
    meta = {
      description = "Deployah Agent Skills consumer release ZIP";
      homepage = "https://deployah.dev";
      license = lib.licenses.asl20;
    };
  }
  ''
    set -euo pipefail
    mkdir -p "$out"
    bash ${./scripts/package-release.sh} "${src}" "$out"
    test -f "$out/${zipName}"
    echo "${version}" > "$out/VERSION"
    ln -s "${zipName}" "$out/deployah-agent-skills.zip"
  ''
