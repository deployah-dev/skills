{
  pkgs,
  skills-ref,
  validate,
}:

pkgs.mkShell {
  packages = [
    skills-ref
    pkgs.skills
    validate
    pkgs.check-jsonschema
    pkgs.jq
    pkgs.yq-go
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.git
    pkgs.nixfmt-tree
    pkgs.zip
    pkgs.unzip
  ];

  shellHook = ''
    echo "Deployah skills maintainer shell"
    echo "  nix run .#validate"
    echo "  DEPLOYAH_SKILLS_ROOT=\$PWD nix run .#validate  # dirty checkout"
    echo "  nix build .#release"
    echo "  nix flake check --print-build-logs"
    echo "  Product version: plugin.json (Agent Plugins schema stays 1.0.0)"
  '';
}
