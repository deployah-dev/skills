# Custom packages that are not available in the locked nixpkgs revision.
# Prefer pkgs.* for everything else (skills, jq, yq-go, check-jsonschema, …).
{
  pkgs,
  agentskills-src,
}:

let
  inherit (pkgs) lib;
  python3Packages = pkgs.python3Packages;
  # Upstream package version (independent of Deployah Skills product version).
  skillsRefVersion =
    (builtins.fromTOML (builtins.readFile "${agentskills-src}/skills-ref/pyproject.toml"))
    .project.version;
in
{
  # Official Agent Skills reference validator (not packaged in pinned nixpkgs).
  skills-ref = python3Packages.buildPythonApplication {
    pname = "skills-ref";
    version = skillsRefVersion;
    pyproject = true;

    src = "${agentskills-src}/skills-ref";

    build-system = [ python3Packages.hatchling ];
    dependencies = with python3Packages; [
      click
      strictyaml
    ];

    doCheck = false;

    meta = {
      description = "Reference library for Agent Skills frontmatter validation";
      homepage = "https://github.com/agentskills/agentskills";
      license = lib.licenses.asl20;
      mainProgram = "skills-ref";
    };
  };
}
