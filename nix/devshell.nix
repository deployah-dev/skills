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
    echo "  nix run .#validate              # flake self (reproducible default)"
    echo "  DEPLOYAH_SKILLS_ROOT=\$PWD nix run .#validate  # dirty checkout"
    echo "  nix build .#release             # consumer ZIP from plugin.json version"
    echo "  skills-ref validate skills/deployah"
    echo "  skills add . --list"
    echo "  Product version: see plugin.json (Agent Plugins schema remains 1.0.0)"
  '';
}
