{
  pkgs,
  src,
  deployah-src,
  skills-ref,
}:

let
  # Shared suite so checks.validate and apps.validate run the same scripts.
  validateScripts = ./scripts;
  validateFixtures = ./fixtures;

  runtimeInputs = [
    skills-ref
    pkgs.skills
    pkgs.check-jsonschema
    pkgs.jq
    pkgs.yq-go
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.findutils
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.bash
  ];

  suite = pkgs.runCommand "deployah-skills-validate-suite" { } ''
    mkdir -p $out/scripts $out/fixtures
    cp -a ${validateScripts}/. $out/scripts/
    cp -a ${validateFixtures}/. $out/fixtures/
    chmod -R +x $out/scripts
    chmod +x $out/scripts/*.sh || true
  '';

  validate = pkgs.writeShellApplication {
    name = "deployah-skills-validate";
    inherit runtimeInputs;
    text = ''
      set -euo pipefail

      # Default root is flake self. Dirty tree:
      #   DEPLOYAH_SKILLS_ROOT=$PWD nix run .#validate
      if [[ -n "''${DEPLOYAH_SKILLS_ROOT:-}" ]]; then
        ROOT="$DEPLOYAH_SKILLS_ROOT"
      else
        ROOT="${src}"
      fi

      export DEPLOYAH_SRC="${deployah-src}"
      export DEPLOYAH_SKILLS_ROOT="$ROOT"
      export VALIDATE_SCRIPTS_ROOT="${suite}/scripts"
      export DEPLOYAH_FIXTURES="${suite}/fixtures/behavioral-contracts.yaml"
      export HOME
      HOME="$(mktemp -d)"

      exec bash "${suite}/scripts/validate-all.sh"
    '';
  };

  check =
    pkgs.runCommand "deployah-skills-check"
      {
        nativeBuildInputs = runtimeInputs ++ [ validate ];
      }
      ''
        export DEPLOYAH_SKILLS_ROOT="${src}"
        export DEPLOYAH_SRC="${deployah-src}"
        export HOME
        HOME="$(mktemp -d)"
        deployah-skills-validate
        mkdir -p "$out"
        echo "ok" > "$out/result"
      '';
in
{
  inherit validate check;
}
