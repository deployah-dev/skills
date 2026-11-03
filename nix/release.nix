# Release packaging. Validation of product content stays in validate.nix;
# checks.release verifies the built artifact.
{
  pkgs,
  src,
}:

let
  inherit (pkgs) lib;
  plugin = builtins.fromJSON (builtins.readFile (src + "/plugin.json"));
  version = plugin.version;
  zipName = "deployah-agent-skills-v${version}.zip";

  releaseInputs = [
    pkgs.bash
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.jq
    pkgs.zip
    pkgs.unzip
  ];

  release =
    pkgs.runCommand "deployah-agent-skills-release-${version}"
      {
        nativeBuildInputs = releaseInputs;
        meta = {
          description = "Deployah Agent Skills release artifact";
          homepage = "https://deployah.dev";
          license = lib.licenses.asl20;
        };
      }
      ''
        set -euo pipefail
        mkdir -p "$out"
        bash ${./scripts/package-release.sh} "${src}" "$out"
        test -f "$out/${zipName}"
      '';

  check =
    pkgs.runCommand "deployah-skills-release-check"
      {
        nativeBuildInputs = releaseInputs ++ [
          pkgs.check-jsonschema
          release
        ];
      }
      ''
        set -euo pipefail
        bash ${./scripts/verify-release-artifact.sh} "${release}/${zipName}" "${src}"
        mkdir -p "$out"
        echo ok > "$out/result"
      '';
in
{
  inherit release check;
}
